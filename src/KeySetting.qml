import QtQuick
import qs.Common
import qs.Widgets

// StringSetting with a masked field: the shell's StringSetting has no echoMode.
Column {
    id: root

    required property string settingKey
    required property string label
    required property var settings
    property string description: ""

    width: parent.width
    spacing: Theme.spacingS

    function loadValue() {
        if (!settings.pluginService || field.activeFocus)
            return;
        field.text = settings.loadValue(settingKey, "");
    }

    function commit() {
        const value = field.text.trim();
        if (value !== settings.loadValue(settingKey, ""))
            settings.saveValue(settingKey, value);
    }

    Component.onCompleted: Qt.callLater(loadValue)

    StyledText {
        text: root.label
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        text: root.description
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        width: parent.width
        wrapMode: Text.WordWrap
        visible: root.description !== ""
    }

    DankTextField {
        id: field
        width: parent.width
        showPasswordToggle: true
        echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
        onEditingFinished: root.commit()
        onActiveFocusChanged: {
            if (!activeFocus)
                root.commit();
        }
    }
}
