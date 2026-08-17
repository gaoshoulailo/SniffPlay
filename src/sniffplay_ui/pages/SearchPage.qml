pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
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

        Text {
            text: "搜索"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 26
            font.weight: Font.Bold
        }

        Text {
            text: "在已启用的音乐来源中查找歌曲、歌手或专辑"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            TextField {
                id: searchField
                Layout.fillWidth: true
                Layout.maximumWidth: 680
                implicitHeight: 42
                leftPadding: 14
                rightPadding: 14
                placeholderText: "输入歌曲、歌手或专辑"
                placeholderTextColor: "#6f7a73"
                color: Theme.textPrimary
                selectionColor: Theme.accentDark
                selectedTextColor: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                onAccepted: root.controller.search(text)

                background: Rectangle {
                    color: Theme.surface
                    border.color: searchField.activeFocus ? Theme.accent : Theme.border
                    border.width: 1
                    radius: Theme.radiusMedium
                }
            }

            AppButton {
                text: "打开音频"
                onClicked: localFileDialog.open()
            }

            AppButton {
                text: root.controller.searching ? "搜索中" : "搜索"
                primary: true
                enabled: !root.controller.searching
                onClicked: root.controller.search(searchField.text)
            }

            BusyIndicator {
                running: root.controller.searching
                visible: root.controller.searching
                palette.highlight: Theme.accent
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8

            Text {
                text: searchField.text.length > 0 ? "搜索结果" : "推荐试听"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Text {
                text: resultsList.count + " 首"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            color: Theme.transparent

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 58
                anchors.rightMargin: 18
                spacing: 14

                Text { Layout.fillWidth: true; text: "歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Text { Layout.preferredWidth: 180; text: "专辑"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Text { Layout.preferredWidth: 72; text: "来源"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Text { Layout.preferredWidth: 52; text: "时长"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Item { Layout.preferredWidth: 36 }
            }
        }

        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.controller.trackModel

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: trackRow
                required property int index
                required property string title
                required property string artist
                required property string album
                required property string duration
                required property string source
                required property string accent
                required property string initials
                required property string coverUrl

                width: resultsList.width
                height: 58
                color: rowMouse.containsMouse ? Theme.surfaceHover : Theme.transparent
                radius: Theme.radiusMedium

                RowLayout {
                    z: 1
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 18
                    spacing: 14

                    Rectangle {
                        id: coverContainer
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        color: trackRow.accent
                        radius: Theme.radiusSmall
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            text: trackRow.initials
                            color: "#101311"
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.bold: true
                            visible: coverImage.status !== Image.Ready
                        }

                        Image {
                            id: coverImage
                            anchors.fill: parent
                            source: trackRow.coverUrl
                            asynchronous: false
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text { Layout.fillWidth: true; text: trackRow.title; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: trackRow.artist; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; elide: Text.ElideRight }
                    }

                    Text { Layout.preferredWidth: 180; text: trackRow.album; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; elide: Text.ElideRight }
                    Text { Layout.preferredWidth: 72; text: trackRow.source; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.DemiBold }
                    Text { Layout.preferredWidth: 52; text: trackRow.duration; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }

                    Button {
                        id: rowPlayButton
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        onClicked: root.controller.playTrack(trackRow.index)
                        ToolTip.visible: hovered
                        ToolTip.text: "播放"

                        contentItem: Text {
                            text: "▶"
                            color: Theme.textPrimary
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: rowPlayButton.hovered ? Theme.accentDark : Theme.surface
                            border.color: Theme.border
                            radius: 17
                        }
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    z: 0
                    onDoubleClicked: root.controller.playTrack(trackRow.index)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: resultsList.count === 0 && !root.controller.searching
                text: "没有找到匹配的歌曲"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 14
            }
        }
    }

    FileDialog {
        id: localFileDialog
        title: "选择本地音频"
        nameFilters: [
            "音频文件 (*.mp3 *.flac *.wav *.m4a *.aac *.ogg *.opus)",
            "所有文件 (*)"
        ]
        onAccepted: root.controller.openLocalFile(selectedFile)
    }

    Component.onCompleted: root.controller.search("")
}
