pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../themes"

Item {
    id: root

    required property var controller

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 18

        Text {
            text: "播放历史"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 26
            font.weight: Font.Bold
        }

        Text {
            text: "最近播放过的歌曲会保存在本机"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 58
            Layout.rightMargin: 18
            Text { Layout.fillWidth: true; text: "歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
            Text { Layout.preferredWidth: 170; text: "专辑"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
            Text { Layout.preferredWidth: 52; text: "时长"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
            Text { Layout.preferredWidth: 100; text: "播放时间"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; horizontalAlignment: Text.AlignRight }
            Item { Layout.preferredWidth: 34 }
        }

        ListView {
            id: historyView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 8
            clip: true
            spacing: 2
            model: root.controller.historyModel

            delegate: Rectangle {
                id: historyRow
                required property int index
                required property string title
                required property string artist
                required property string album
                required property string duration
                required property string accent
                required property string initials
                required property string coverUrl
                required property string playedAt

                width: historyView.width
                height: 58
                color: historyMouse.containsMouse ? Theme.surfaceHover : Theme.transparent
                radius: Theme.radiusMedium

                RowLayout {
                    z: 1
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 18
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        color: historyRow.accent
                        radius: Theme.radiusSmall
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            text: historyRow.initials
                            color: "#101311"
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.bold: true
                            visible: historyCover.status !== Image.Ready
                        }

                        Image {
                            id: historyCover
                            anchors.fill: parent
                            source: historyRow.coverUrl
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text { Layout.fillWidth: true; text: historyRow.title; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: historyRow.artist; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; elide: Text.ElideRight }
                    }

                    Text {
                        Layout.preferredWidth: 170
                        text: historyRow.album
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.preferredWidth: 52
                        text: historyRow.duration
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    Text {
                        Layout.preferredWidth: 100
                        text: historyRow.playedAt
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignRight
                    }

                    Button {
                        id: playButton
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        onClicked: root.controller.playHistory(historyRow.index)
                        ToolTip.visible: hovered
                        ToolTip.text: "播放"

                        contentItem: Text {
                            text: "▶"
                            color: Theme.textPrimary
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: playButton.hovered ? Theme.accentDark : Theme.surface
                            border.color: Theme.border
                            radius: 17
                        }
                    }
                }

                MouseArea {
                    id: historyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    z: 0
                    onDoubleClicked: root.controller.playHistory(historyRow.index)
                }
            }

            Column {
                anchors.centerIn: parent
                visible: historyView.count === 0
                spacing: 10

                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "暂无播放记录"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.DemiBold }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "播放歌曲后会显示在这里"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
            }
        }
    }
}
