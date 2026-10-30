# DMS Translate

English | [Русский](README_RU.md)

A small translator widget for the top bar of [DankMaterialShell](https://github.com/duxlabs-dev/dux-shell) 1.6.3+ and Dux Shell 2.x. Click the icon, type or paste text, press Enter. It works with Google Cloud Translation, DeepL or any OpenRouter model. Pure QML: no Python, no extra packages.

## Requirements

- DankMaterialShell 1.6.3 or newer, or Dux Shell 2.x (tested on niri)
- An API key for one provider (see [Providers and keys](#providers-and-keys))

## Install

```bash
git clone https://github.com/exec-cmd/dms-translater.git
cd dms-translater
./install.sh
dms ipc call plugins reload dmsTranslate
```

`install.sh` copies `src/` to `~/.config/dms/plugins/dmsTranslate` on Dux Shell 2.x, or to `~/.config/DankMaterialShell/plugins/dmsTranslate` on 1.x. `--link` makes a symlink instead, so edits in the repo apply after a reload. An existing directory that is not this plugin is never replaced without `--force`.

## Add to the bar

1. Settings → Plugins → Scan for Plugins, then turn on **Translate**.
2. Pick a provider and enter its API key in the plugin settings.
3. Settings → Dank Bar → add the **Translate** widget to a section.

In the popout, Enter translates and Shift+Enter adds a new line. Type in a language list to search it. The source language can be Auto. The swap button swaps the languages and moves the last translation into the input. The last four language pairs you used appear as chips under the lists, so one click switches back. The current pair is remembered.

To translate text in an image, copy the image (for example a niri screenshot) and press Ctrl+V in the input or click **Image**. Images work only with OpenRouter and a model that accepts image input (the default `z-ai/glm-5.3-flash` does). Google Cloud Translation v2 and DeepL `/v2/translate` accept text only. Pasting an image needs `wl-paste` from wl-clipboard.

## Providers and keys

| Provider | Key | Notes |
|---|---|---|
| Google Cloud Translation | [Cloud Console](https://console.cloud.google.com/apis/credentials), with the Cloud Translation API enabled | Uses the Basic v2 API, which accepts API keys. |
| DeepL | [DeepL API account](https://www.deepl.com/your-account/keys) | Free keys end in `:fx` and use `api-free.deepl.com` automatically. |
| OpenRouter | [openrouter.ai/keys](https://openrouter.ai/keys) | Default model `z-ai/glm-5.3-flash`. The model id, reasoning level and system prompt are editable. **Reasoning**: Model default sends nothing; Off to Extra high set `reasoning.effort` (Off is fastest; models that always reason may reject it). `{source}` and `{target}` in the prompt become language names. |

API keys are stored as **plain text** in the shell's `plugin_settings.json` (in `~/.config/dms/` or `~/.config/DankMaterialShell/`), which every plugin can read. Use keys limited to the translation API, with a spending cap. Keys are sent only in request headers, never in URLs or command lines.

The text you translate is sent to the selected provider.

## Keyboard shortcut

Add a bind to `~/.config/niri/config.kdl`:

```kdl
binds {
    Mod+Alt+T { spawn "dms" "ipc" "call" "widget" "toggle" "dmsTranslate"; }
}
```

The widget must be on the bar for the shortcut to work.

## Update and remove

```bash
git pull && ./install.sh   # not needed with --link; just reload
./uninstall.sh
```

`uninstall.sh` removes only the plugin directory. The settings and keys stay in `plugin_settings.json` under `dmsTranslate`; delete that entry by hand if you need to.

## Development

```bash
node --test tests/*.test.mjs              # request building and response parsing
shellcheck install.sh uninstall.sh
./install.sh --link && dms ipc call plugins reload dmsTranslate
```

See [AGENTS.md](AGENTS.md) for the repository rules.

## License

MIT. See [LICENSE](LICENSE).
