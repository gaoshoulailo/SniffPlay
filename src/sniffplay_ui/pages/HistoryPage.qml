pragma ComponentBehavior: Bound

import QtQuick
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
                required property string title
                required property string artist
                required property string playedAt

                width: historyView.width
                height: 58
                color: historyMouse.containsMouse ? Theme.surfaceHover : Theme.transparent
                radius: Theme.radiusMedium

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 18
                    spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        color: Theme.surface
                        border.color: Theme.border
                        radius: 18

                        Text {
                            anchors.centerIn: parent
                            text: "↺"
                            color: Theme.textSecondary
                            font.pixelSize: 16
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text { Layout.fillWidth: true; text: historyRow.title; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: historyRow.artist; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; elide: Text.ElideRight }
                    }

                    Text {
                        Layout.preferredWidth: 100
                        text: historyRow.playedAt
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignRight
                    }
                }

                MouseArea {
                    id: historyMouse
                    anchors.fill: parent
                    hoverEnabled: true
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
