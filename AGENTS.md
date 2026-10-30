# DMS Translate repository instructions

## Project scope

DMS Translate is a top bar widget plugin (id `dmsTranslate`) for DankMaterialShell 1.6.3+ and Dux Shell 2.x. It translates typed text through Google Cloud Translation (Basic v2), DeepL or OpenRouter. It is pure QML/JavaScript: no Python, no curl, no runtime dependencies beyond the shell itself. Keep it a basic translator; history, TTS, clipboard watching and similar features are out of scope unless the user asks.

Read the relevant file and test before changing behavior. Prefer the smallest change that keeps the setting keys, the plugin id and the install paths working.

## Repository map

- `src/` is the plugin directory that `install.sh` copies or symlinks into the shell's `plugins/dmsTranslate`.
  - `plugin.json` is the manifest.
  - `Widget.qml` holds the bar icon, the popout UI and the `XMLHttpRequest` call with its 15 s timeout.
  - `Settings.qml` holds the provider choice, keys, model and prompt. `KeySetting.qml` is a masked variant of the shell's `StringSetting`.
  - `Providers.js` (`.pragma library`) holds every provider-specific detail: language list, defaults, `buildRequest()` and `parseResponse()`. It has no QML dependencies.
- `tests/providers.test.mjs` loads `Providers.js` in a `node:vm` context and covers request shape and response parsing.
- `install.sh` / `uninstall.sh` are POSIX `sh`.
- `README.md` and `README_RU.md` are full mirrors in English and Russian.

## Development commands

```bash
node --test tests/*.test.mjs
shellcheck install.sh uninstall.sh
./install.sh --link
dms ipc call plugins reload dmsTranslate
```

QML has no automated test. After QML changes, reload the plugin, open the popout, and check the shell log for errors.

## Rules the code does not show

- Compatibility: use the `Dank*` widget names from `qs.Widgets` and `Theme` from `qs.Common`. They exist in 1.6.3 and are kept as aliases in 2.x (`DTextField` etc. exist only in 2.x). Before using a new widget or property, confirm it exists in both: 1.6.3 is extracted at runtime under `/run/user/$UID/danklinux-shell/*/`, 2.x is `duxlabs-dev/dux-shell` (shared widgets in the `dux-qml-common` submodule).
- Setting keys (`provider`, `googleApiKey`, `deeplApiKey`, `openrouterApiKey`, `openrouterModel`, `openrouterReasoning`, `openrouterPrompt`) and state keys (`source`, `target`, `recentPairs`) are stored user data. Do not rename them.
- API keys go only into request headers: never into URLs, process arguments, logs or error messages. Tests assert this.
- Provider logic lives in `Providers.js`, so it stays testable. `Widget.qml` only sends what `buildRequest()` returns.
- DeepL accepts only the `Authorization: DeepL-Auth-Key` header (legacy auth was removed in 2026). Google v3 needs OAuth, so v2 stays.
- Clipboard copy goes through `dms cl copy`. Image paste reads the clipboard with `wl-paste` (`dms cl` has no image read); images go only to OpenRouter as a `data:` URL part.
- The default prompt stays one line: the settings field is single-line.
- Do not add dependencies. Tests use only Node's built-in `node:test`.

## Documentation and delivery

Keep `README.md` and `README_RU.md` in sync with each other and with the code (settings, defaults, paths, commands). Do not commit, tag, push or publish unless the user explicitly asks.
