pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import "../themes"

Item {
    id: root

    required property var controller

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 18

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 5

                Text {
                    text: "我的歌单"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }

                Text {
                    text: "整理喜欢的歌曲和播放顺序"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            Item { Layout.fillWidth: true }

            AppButton {
                text: "新建歌单"
                primary: true
                onClicked: createDialog.open()
            }
        }

        ListView {
            id: playlistView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 8
            clip: true
            spacing: 2
            model: root.controller.playlistModel

            delegate: Rectangle {
                id: playlistRow
                required property int playlistId
                required property string name
                required property string countLabel

                width: playlistView.width
                height: 62
                color: playlistMouse.containsMouse ? Theme.surfaceHover : Theme.transparent
                radius: Theme.radiusMedium

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 16
                    spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        color: Theme.accentDark
                        radius: Theme.radiusSmall

                        Text {
                            anchors.centerIn: parent
                            text: "♫"
                            color: Theme.accent
                            font.pixelSize: 18
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text { text: playlistRow.name; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold }
                        Text { text: playlistRow.countLabel; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                    }

                    Text {
                        text: "›"
                        color: Theme.textSecondary
                        font.pixelSize: 24
                    }
                }

                MouseArea {
                    id: playlistMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            Column {
                anchors.centerIn: parent
                visible: playlistView.count === 0
                spacing: 10

                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "还没有歌单"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.DemiBold }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "创建一个歌单开始整理音乐"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
            }
        }
    }

    Dialog {
        id: createDialog
        anchors.centerIn: parent
        modal: true
        title: "新建歌单"
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 380
        padding: 20
        onOpened: {
            playlistName.text = ""
            playlistName.forceActiveFocus()
        }
        onAccepted: root.controller.createPlaylist(playlistName.text)

        palette.window: Theme.surface
        palette.windowText: Theme.textPrimary
        palette.buttonText: Theme.textPrimary

        contentItem: ColumnLayout {
            spacing: 12

            Text {
                text: "歌单名称"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }

            TextField {
                id: playlistName
                Layout.fillWidth: true
                implicitHeight: 40
                color: Theme.textPrimary
                placeholderText: "例如：通勤播放"
                placeholderTextColor: "#6f7a73"
                font.family: Theme.fontFamily
                background: Rectangle {
                    color: Theme.window
                    border.color: playlistName.activeFocus ? Theme.accent : Theme.border
                    radius: Theme.radiusMedium
                }
            }
        }

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium
        }
    }
}
