import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../themes"

Dialog {
    id: control

    property string description: "创建后可继续从搜索结果添加歌曲"
    property string placeholderText: "例如：通勤播放"
    signal submitted(string name)

    width: 410
    modal: true
    dim: true
    title: "新建歌单"
    closePolicy: Popup.CloseOnEscape
    transformOrigin: Item.Center

    onOpened: {
        playlistName.text = ""
        playlistName.forceActiveFocus()
    }
    onAccepted: submitted(playlistName.text.trim())

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 190; easing.type: Easing.OutBack }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 110; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1; to: 0.98; duration: 110; easing.type: Easing.InCubic }
        }
    }

    Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, 0.42) }

    header: Item {
        implicitHeight: 60

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.topMargin: 14
            anchors.bottomMargin: 6
            spacing: 11

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                color: Theme.accentDark
                radius: 17
                AppIcon { anchors.centerIn: parent; name: "list"; color: Theme.accent; iconSize: 17 }
            }

            Text {
                Layout.fillWidth: true
                text: control.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: 12

        Text {
            Layout.fillWidth: true
            text: control.description
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }

        TextField {
            id: playlistName
            Layout.fillWidth: true
            implicitHeight: 42
            leftPadding: 13
            rightPadding: 13
            color: Theme.textPrimary
            placeholderText: control.placeholderText
            placeholderTextColor: Theme.placeholderText
            selectionColor: Theme.accentDark
            selectedTextColor: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            onAccepted: if (text.trim().length > 0) control.accept()

            background: Rectangle {
                color: Theme.window
                border.color: playlistName.activeFocus ? Theme.accent : Theme.border
                border.width: playlistName.activeFocus ? 2 : 1
                radius: Theme.radiusMedium
                Behavior on border.color { ColorAnimation { duration: 140 } }
            }
        }
    }

    footer: Item {
        implicitHeight: 66

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.topMargin: 10
            anchors.bottomMargin: 16
            spacing: 10

            Item { Layout.fillWidth: true }
            AppButton { text: "取消"; onClicked: control.reject() }
            AppButton {
                text: "创建歌单"
                iconName: "add"
                primary: true
                enabled: playlistName.text.trim().length > 0
                onClicked: control.accept()
            }
        }
    }

    background: Rectangle {
        color: Qt.rgba(0.105, 0.105, 0.12, 0.99)
        border.color: Theme.buttonBorder
        radius: Theme.radiusMedium

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.52
            shadowBlur: 0.78
            shadowVerticalOffset: 12
        }
    }
}
