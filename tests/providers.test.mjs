import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";

// Providers.js is a QML `.pragma library` script, not a module: drop the pragma and run it in a context.
const source = readFileSync(new URL("../src/Providers.js", import.meta.url), "utf8").replace(/^\.pragma library/m, "");
const P = vm.createContext({});
vm.runInContext(source, P);

const body = req => JSON.parse(req.body);

test("missing key is an error, not a request", () => {
    assert.match(P.buildRequest({ provider: "deepl", deeplApiKey: "  " }, "hi", "auto", "ru").error, /DeepL API key/);
    assert.match(P.buildRequest({}, "hi", "auto", "ru").error, /Google API key/);
});

test("google: key in header, auto omits source", () => {
    const req = P.buildRequest({ provider: "google", googleApiKey: "G" }, "hi", "auto", "ru");
    assert.equal(req.url, "https://translation.googleapis.com/language/translate/v2");
    assert.equal(req.headers["X-Goog-Api-Key"], "G");
    assert.deepEqual(body(req), { q: ["hi"], target: "ru", format: "text" });
    assert.equal(body(P.buildRequest({ googleApiKey: "G" }, "hi", "en", "ru")).source, "en");
});

test("deepl: host by :fx, target variants, upper-case codes", () => {
    const free = P.buildRequest({ provider: "deepl", deeplApiKey: "k:fx" }, "hi", "ru", "en");
    assert.equal(free.url, "https://api-free.deepl.com/v2/translate");
    assert.equal(free.headers.Authorization, "DeepL-Auth-Key k:fx");
    assert.deepEqual(body(free), { text: ["hi"], target_lang: "EN-US", source_lang: "RU" });

    const pro = P.buildRequest({ provider: "deepl", deeplApiKey: "k" }, "hi", "auto", "de");
    assert.equal(pro.url, "https://api.deepl.com/v2/translate");
    assert.deepEqual(body(pro), { text: ["hi"], target_lang: "DE" });
    assert.equal(body(P.buildRequest({ provider: "deepl", deeplApiKey: "k" }, "hi", "auto", "zh")).target_lang, "ZH-HANS");
});

test("openrouter: defaults, prompt placeholders, key only in header", () => {
    const req = P.buildRequest({ provider: "openrouter", openrouterApiKey: "sk" }, "hi", "auto", "ru");
    const b = body(req);
    assert.equal(req.headers.Authorization, "Bearer sk");
    assert.ok(!req.url.includes("sk") && !req.body.includes("sk"));
    assert.equal(b.model, "z-ai/glm-5.3-flash");
    assert.match(b.messages[0].content, /^You are a translation engine\. Translate the user's message from the auto-detected language into Russian\./);
    assert.equal(b.reasoning, undefined);
    assert.deepEqual({ ...b.messages[1] }, { role: "user", content: "hi" });

    const custom = body(P.buildRequest({ provider: "openrouter", openrouterApiKey: "sk", openrouterModel: "x/y", openrouterPrompt: "{source}>{target}" }, "hi", "de", "en"));
    assert.equal(custom.model, "x/y");
    assert.equal(custom.messages[0].content, "German>English");
});

test("parse success per provider", () => {
    assert.equal(P.parseResponse("google", 200, '{"data":{"translations":[{"translatedText":"привет"}]}}').text, "привет");
    assert.equal(P.parseResponse("deepl", 200, '{"translations":[{"detected_source_language":"EN","text":"привет"}]}').text, "привет");
    assert.equal(P.parseResponse("openrouter", 200, '{"choices":[{"message":{"content":" привет\\n"}}]}').text, "привет");
});

test("parse errors", () => {
    assert.match(P.parseResponse("google", 0, "").error, /Network error/);
    assert.equal(P.parseResponse("google", 400, '{"error":{"code":400,"message":"API key not valid"}}').error, "HTTP 400: API key not valid");
    assert.equal(P.parseResponse("deepl", 403, '{"message":"Wrong key"}').error, "HTTP 403: Wrong key");
    assert.equal(P.parseResponse("deepl", 456, "").error, "DeepL quota exceeded.");
    assert.equal(P.parseResponse("openrouter", 200, '{"error":{"message":"No endpoints"}}').error, "No endpoints");
    assert.equal(P.parseResponse("openrouter", 502, "<html>").error, "HTTP 502");
});

test("openrouter: reasoning effort and image parts", () => {
    const s = { provider: "openrouter", openrouterApiKey: "sk", openrouterReasoning: "none" };
    const b = body(P.buildRequest(s, "", "auto", "ru", { mime: "image/png", data: "AAA" }));
    assert.deepEqual(b.reasoning, { effort: "none", exclude: true });
    assert.deepEqual(b.messages[1].content, [{ type: "image_url", image_url: { url: "data:image/png;base64,AAA" } }]);
    const withText = body(P.buildRequest(s, "note", "auto", "ru", { mime: "image/jpeg", data: "B" }));
    assert.equal(withText.messages[1].content[0].text, "note");
    assert.match(P.buildRequest({ googleApiKey: "G" }, "", "auto", "ru", { mime: "image/png", data: "A" }).error, /OpenRouter/);
});

test("recent pairs: newest first, deduplicated, capped at 4", () => {
    let r = [];
    for (const t of ["ru", "de", "fr", "es", "de"]) r = P.pushRecent(r, "en", t);
    assert.equal(r.map(p => p.target).join(), "de,es,fr,ru");
});
