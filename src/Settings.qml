import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "Providers.js" as Providers

PluginSettings {
    id: root
    pluginId: "dmsTranslate"

    SelectionSetting {
        settingKey: "provider"
        label: "Provider"
        options: [
            { label: "Google Cloud Translation", value: "google" },
            { label: "DeepL", value: "deepl" },
            { label: "OpenRouter", value: "openrouter" }
        ]
        defaultValue: Providers.defaultProvider
    }

    KeySetting {
        settings: root
        settingKey: "googleApiKey"
        label: "Google API key"
        description: "Google Cloud Console → Credentials, with the Cloud Translation API enabled."
    }

    KeySetting {
        settings: root
        settingKey: "deeplApiKey"
        label: "DeepL API key"
        description: "Free keys end in :fx and use the Free endpoint automatically."
    }

    KeySetting {
        settings: root
        settingKey: "openrouterApiKey"
        label: "OpenRouter API key"
    }

    StringSetting {
        settingKey: "openrouterModel"
        label: "OpenRouter model"
        description: "Any model id from openrouter.ai/models."
        placeholder: Providers.defaultModel
        defaultValue: Providers.defaultModel
    }

    SelectionSetting {
        settingKey: "openrouterReasoning"
        label: "OpenRouter reasoning"
        description: "How much the model thinks before answering. Off is fastest and cheapest; models that always reason ignore it or reject Off."
        options: [
            { label: "Model default", value: "" },
            { label: "Off", value: "none" },
            { label: "Minimal", value: "minimal" },
            { label: "Low", value: "low" },
            { label: "Medium", value: "medium" },
            { label: "High", value: "high" },
            { label: "Extra high", value: "xhigh" }
        ]
        defaultValue: ""
    }

    StringSetting {
        settingKey: "openrouterPrompt"
        label: "OpenRouter system prompt"
        description: "{source} and {target} are replaced with language names."
        placeholder: Providers.defaultPrompt
        defaultValue: Providers.defaultPrompt
    }
}
