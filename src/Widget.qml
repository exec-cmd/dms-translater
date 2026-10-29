import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "Providers.js" as Providers

PluginComponent {
    id: root

    property string source: "auto"
    property string target: "en"
    property var recentPairs: []
    property string inputText: ""
    property var image: null
    property string resultText: ""
    property string errorText: ""
    property var request: null
    readonly property bool busy: request !== null
    readonly property string provider: Providers.providerOf(pluginData)

    popoutWidth: 460
    popoutHeight: image ? 600 : 500

    onPluginServiceChanged: loadPair()
    onPluginIdChanged: loadPair()

    function loadPair() {
        if (!pluginService || !pluginId)
            return;
        source = pluginService.loadPluginState(pluginId, "source", "auto");
        target = pluginService.loadPluginState(pluginId, "target", "en");
        recentPairs = pluginService.loadPluginState(pluginId, "recentPairs", []);
    }

    function savePair() {
        if (!pluginService)
            return;
        pluginService.savePluginState(pluginId, "source", source);
        pluginService.savePluginState(pluginId, "target", target);
    }

    function setPair(s, t) {
        source = s;
        target = t;
        savePair();
    }

    function remember() {
        recentPairs = Providers.pushRecent(recentPairs, source, target);
        pluginService?.savePluginState(pluginId, "recentPairs", recentPairs);
    }

    function cancel() {
        const old = request;
        request = null;
        timeout.stop();
        if (old)
            old.abort();
    }

    function translate() {
        const text = inputText.trim();
        if (!text && !image)
            return;
        cancel();
        resultText = "";
        errorText = "";
        const req = Providers.buildRequest(pluginData, text, source, target, image);
        if (req.error) {
            errorText = req.error;
            return;
        }
        const p = provider;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            // Ignore aborted or superseded requests.
            if (xhr.readyState !== XMLHttpRequest.DONE || request !== xhr)
                return;
            request = null;
            timeout.stop();
            const res = Providers.parseResponse(p, xhr.status, xhr.responseText);
            resultText = res.text || "";
            errorText = res.error || "";
            if (res.text)
                remember();
        };
        xhr.open("POST", req.url);
        for (const name in req.headers)
            xhr.setRequestHeader(name, req.headers[name]);
        request = xhr;
        xhr.send(req.body);
        timeout.interval = image ? 60000 : 15000;
        timeout.restart();
    }

    // Qt's XMLHttpRequest has no timeout property.
    Timer {
        id: timeout
        interval: 15000
        onTriggered: {
            root.cancel();
            root.errorText = "Request timed out.";
        }
    }

    // First line: the image MIME type; second line: the image as base64. Empty when the clipboard has no image.
    Process {
        id: imagePaste
        command: ["sh", "-c", "t=$(wl-paste --list-types 2>/dev/null | grep -m1 '^image/') || exit 0; echo \"$t\"; wl-paste --type \"$t\" | base64 -w0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const nl = text.indexOf("\n");
                if (nl > 0 && text.length > nl + 1)
                    root.image = { mime: text.slice(0, nl), data: text.slice(nl + 1).trim() };
            }
        }
    }

    horizontalBarPill: Component {
        DankIcon {
            name: "translate"
            size: Theme.iconSize - 6
            color: Theme.surfaceText
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: "translate"
            size: Theme.iconSize - 6
            color: Theme.surfaceText
        }
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: "Translate"
            detailsText: "via " + Providers.providerNames[root.provider]
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM
                topPadding: Theme.spacingS

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DankDropdown {
                        width: (parent.width - swapButton.width - parent.spacing * 2) / 2
                        dropdownWidth: width
                        enableFuzzySearch: true
                        options: Providers.languages.map(l => l.name)
                        currentValue: Providers.languageName(root.source)
                        onValueChanged: value => root.setPair(Providers.languageCode(value), root.target)
                    }

                    DankActionButton {
                        id: swapButton
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: "swap_horiz"
                        tooltipText: "Swap languages"
                        enabled: root.source !== "auto"
                        opacity: enabled ? 1 : 0.4
                        onClicked: {
                            if (root.resultText) {
                                input.text = root.resultText;
                                root.resultText = "";
                            }
                            root.setPair(root.target, root.source);
                        }
                    }

                    DankDropdown {
                        width: (parent.width - swapButton.width - parent.spacing * 2) / 2
                        dropdownWidth: width
                        enableFuzzySearch: true
                        options: Providers.languages.slice(1).map(l => l.name)
                        currentValue: Providers.languageName(root.target)
                        onValueChanged: value => root.setPair(root.source, Providers.languageCode(value))
                    }
                }

                // Recent pairs: one click instead of two dropdowns.
                Flow {
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: root.recentPairs.length > 0

                    Repeater {
                        model: root.recentPairs

                        StyledRect {
                            required property var modelData
                            readonly property bool current: modelData.source === root.source && modelData.target === root.target
                            width: chipLabel.implicitWidth + Theme.spacingM * 2
                            height: 28
                            radius: 14
                            color: current ? Theme.primary : (chipArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)

                            StyledText {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: (modelData.source === "auto" ? "Auto" : modelData.source.toUpperCase()) + " → " + modelData.target.toUpperCase()
                                font.pixelSize: Theme.fontSizeSmall
                                color: parent.current ? Theme.onPrimary : Theme.surfaceText
                            }

                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setPair(modelData.source, modelData.target)
                            }
                        }
                    }
                }

                DankTextEdit {
                    id: input
                    width: parent.width
                    height: 110
                    placeholderText: "Text to translate. Enter translates, Shift+Enter adds a line, Ctrl+V also pastes an image."
                    keyForwardTargets: [keys]
                    onTextChanged: root.inputText = text
                    Component.onCompleted: {
                        text = root.inputText;
                        forceActiveFocus();
                    }
                }

                // Receives keys before the TextEdit, so plain Enter translates instead of inserting a newline.
                Item {
                    id: keys
                    Keys.onPressed: event => {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                            event.accepted = true;
                            root.translate();
                        } else if (event.key === Qt.Key_V && (event.modifiers & Qt.ControlModifier)) {
                            // Text still pastes normally; an image in the clipboard is attached as well.
                            imagePaste.running = true;
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 90
                    visible: root.image !== null

                    Image {
                        anchors.left: parent.left
                        height: parent.height
                        width: Math.min(parent.width - removeImage.width - Theme.spacingS, implicitWidth * height / Math.max(1, implicitHeight))
                        fillMode: Image.PreserveAspectFit
                        source: root.image ? "data:" + root.image.mime + ";base64," + root.image.data : ""
                    }

                    DankActionButton {
                        id: removeImage
                        anchors.right: parent.right
                        anchors.top: parent.top
                        iconName: "close"
                        tooltipText: "Remove image"
                        onClicked: root.image = null
                    }
                }

                DankTextEdit {
                    width: parent.width
                    height: 110
                    readOnly: true
                    text: root.errorText || root.resultText
                    textColor: root.errorText ? Theme.error : Theme.surfaceText
                    placeholderText: root.busy ? "Translating…" : "Translation"
                }

                Row {
                    anchors.right: parent.right
                    spacing: Theme.spacingS

                    DankButton {
                        text: "Image"
                        iconName: "image"
                        enabled: !imagePaste.running
                        onClicked: imagePaste.running = true
                    }

                    DankButton {
                        text: "Copy"
                        iconName: "content_copy"
                        enabled: root.resultText !== ""
                        opacity: enabled ? 1 : 0.4
                        onClicked: Quickshell.execDetached(["dms", "cl", "copy", root.resultText])
                    }

                    DankButton {
                        text: root.busy ? "Translating…" : "Translate"
                        iconName: "translate"
                        enabled: !root.busy && (root.inputText.trim() !== "" || root.image !== null)
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.translate()
                    }
                }
            }
        }
    }
}
