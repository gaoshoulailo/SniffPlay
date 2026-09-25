import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../themes"

Rectangle {
    id: root

    property string message: ""
    property string tone: "info"
    property bool shown: false

    function show(nextMessage) {
        message = nextMessage
        tone = /(失败|错误|不存在|无法|未检测到|尚未初始化)/.test(nextMessage)
            ? "error"
            : (/(已|找到)/.test(nextMessage) ? "success" : "info")
        shown = true
        dismissTimer.restart()
    }

    implicitWidth: 420
    implicitHeight: 52
    color: Qt.rgba(0.10, 0.10, 0.12, 0.96)
    border.color: root.tone === "error"
        ? Theme.danger
        : (root.tone === "success" ? Theme.accent : Theme.buttonBorder)
    border.width: 1
    radius: Theme.radiusMedium
    opacity: shown ? 1 : 0
    visible: shown || opacity > 0
    scale: shown ? 1 : 0.96

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.42
        shadowBlur: 0.65
        shadowVerticalOffset: 6
    }

    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 8
        spacing: 10

        AppIcon {
            name: root.tone === "success" ? "check" : (root.tone === "error" ? "close" : "info")
            color: root.tone === "error" ? Theme.danger : Theme.accent
            iconSize: 17
        }

        Text {
            Layout.fillWidth: true
            text: root.message
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        Button {
            id: closeButton
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            onClicked: root.shown = false
            ToolTip.visible: hovered
            ToolTip.text: "关闭提示"
            contentItem: AppIcon { name: "close"; color: Theme.textSecondary; iconSize: 12 }
            background: Rectangle {
                color: closeButton.hovered ? Theme.surfaceHover : Theme.transparent
                radius: 17
            }
        }
    }

    Timer {
        id: dismissTimer
        interval: 2600
        onTriggered: root.shown = false
    }
}
