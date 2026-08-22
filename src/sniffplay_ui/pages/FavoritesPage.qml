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

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 5
                Text { text: "我的收藏"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold }
                Text { text: "收藏喜欢的歌曲，随时重新播放"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
            }

            Item { Layout.fillWidth: true }
            Text { text: root.controller.favoriteCount + " 首"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 58
            Layout.rightMargin: 18
            Text { Layout.fillWidth: true; text: "歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
            Text { Layout.preferredWidth: 170; text: "专辑"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
            Text { Layout.preferredWidth: 82; text: "收藏时间"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
            Item { Layout.preferredWidth: 72 }
        }

        ListView {
            id: favoriteView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.controller.favoriteModel
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: favoriteRow
                required property int index
                required property int favoriteId
                required property string title
                required property string artist
                required property string album
                required property string duration
                required property string accent
                required property string initials
                required property string coverUrl
                required property string favoritedAt

                width: favoriteView.width
                height: 60
                color: rowMouse.containsMouse ? Theme.surfaceHover : Theme.transparent
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
                        color: favoriteRow.accent
                        radius: Theme.radiusSmall
                        clip: true
                        Text { anchors.centerIn: parent; text: favoriteRow.initials; color: "#101311"; font.family: Theme.fontFamily; font.bold: true; visible: coverImage.status !== Image.Ready }
                        Image { id: coverImage; anchors.fill: parent; source: favoriteRow.coverUrl; asynchronous: true; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { Layout.fillWidth: true; text: favoriteRow.title; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: favoriteRow.artist; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight }
                    }

                    Text { Layout.preferredWidth: 170; text: favoriteRow.album; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight }
                    Text { Layout.preferredWidth: 82; text: favoriteRow.favoritedAt; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }

                    Button {
                        id: playButton
                        implicitWidth: 34; implicitHeight: 34
                        onClicked: root.controller.playFavorite(favoriteRow.index)
                        ToolTip.visible: hovered; ToolTip.text: "播放"
                        contentItem: Text { text: "▶"; color: Theme.textPrimary; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: playButton.hovered ? Theme.accentDark : Theme.surface; border.color: Theme.border; radius: 17 }
                    }

                    Button {
                        id: removeButton
                        implicitWidth: 34; implicitHeight: 34
                        onClicked: root.controller.removeFavorite(favoriteRow.favoriteId)
                        ToolTip.visible: hovered; ToolTip.text: "取消收藏"
                        contentItem: Text { text: "♥"; color: Theme.danger; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: removeButton.hovered ? Theme.surfaceHover : Theme.surface; border.color: Theme.border; radius: 17 }
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    z: 0
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    onDoubleClicked: root.controller.playFavorite(favoriteRow.index)
                }
            }

            Column {
                anchors.centerIn: parent
                visible: favoriteView.count === 0
                spacing: 8
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "还没有收藏"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.DemiBold }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "在搜索结果或播放器中点击爱心收藏歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
            }
        }
    }
}
