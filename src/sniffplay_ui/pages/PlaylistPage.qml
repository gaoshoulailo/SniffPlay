pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import "../themes"

Item {
    id: root

    required property var controller
    property int pendingRemoveItemId: -1

    StackLayout {
        anchors.fill: parent
        currentIndex: root.controller.hasSelectedPlaylist ? 1 : 0

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 18

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 5
                        Text { text: "我的歌单"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold }
                        Text { text: "整理喜欢的歌曲和播放顺序"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
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
                                Text { anchors.centerIn: parent; text: "♫"; color: Theme.accent; font.pixelSize: 18 }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text { Layout.fillWidth: true; text: playlistRow.name; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                Text { text: playlistRow.countLabel; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                            }

                            Text { text: "›"; color: Theme.textSecondary; font.pixelSize: 24 }
                        }

                        MouseArea {
                            id: playlistMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.controller.openPlaylist(playlistRow.playlistId)
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        visible: playlistView.count === 0
                        spacing: 10
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "还没有歌单"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.DemiBold }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "创建歌单后，可从搜索结果添加歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
                    }
                }
            }
        }

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Button {
                        id: backButton
                        implicitWidth: 38
                        implicitHeight: 38
                        onClicked: root.controller.closePlaylist()
                        ToolTip.visible: hovered
                        ToolTip.text: "返回歌单列表"
                        contentItem: Text { text: "‹"; color: Theme.textPrimary; font.pixelSize: 26; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: backButton.hovered ? Theme.surfaceHover : Theme.surface; border.color: Theme.border; radius: Theme.radiusMedium }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.controller.selectedPlaylistName
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    AppButton {
                        text: "播放全部"
                        primary: true
                        enabled: playlistTrackView.count > 0
                        onClicked: root.controller.playSelectedPlaylist()
                    }
                    AppButton { text: "重命名"; onClicked: renameDialog.open() }
                    AppButton { text: "删除歌单"; onClicked: deletePlaylistDialog.open() }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 58
                    Layout.rightMargin: 18
                    Text { Layout.fillWidth: true; text: "歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                    Text { Layout.preferredWidth: 150; text: "专辑"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                    Text { Layout.preferredWidth: 54; text: "时长"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                    Item { Layout.preferredWidth: 156 }
                }

                ListView {
                    id: playlistTrackView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: root.controller.playlistTrackModel
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        id: trackRow
                        required property int index
                        required property int itemId
                        required property string title
                        required property string artist
                        required property string album
                        required property string duration
                        required property string accent
                        required property string initials
                        required property string coverUrl
                        required property bool canMoveUp
                        required property bool canMoveDown

                        width: playlistTrackView.width
                        height: 60
                        color: trackMouse.containsMouse ? Theme.surfaceHover : Theme.transparent
                        radius: Theme.radiusMedium

                        RowLayout {
                            z: 1
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 18
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 42
                                Layout.preferredHeight: 42
                                color: trackRow.accent
                                radius: Theme.radiusSmall
                                clip: true
                                Text { anchors.centerIn: parent; text: trackRow.initials; color: "#101311"; font.family: Theme.fontFamily; font.bold: true; visible: trackCover.status !== Image.Ready }
                                Image { id: trackCover; anchors.fill: parent; source: trackRow.coverUrl; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: status === Image.Ready }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text { Layout.fillWidth: true; text: trackRow.title; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                Text { Layout.fillWidth: true; text: trackRow.artist; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight }
                            }

                            Text { Layout.preferredWidth: 150; text: trackRow.album; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight }
                            Text { Layout.preferredWidth: 54; text: trackRow.duration; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }

                            Button {
                                id: playButton
                                implicitWidth: 34; implicitHeight: 34
                                onClicked: root.controller.playPlaylistItem(trackRow.index)
                                ToolTip.visible: hovered; ToolTip.text: "播放"
                                contentItem: Text { text: "▶"; color: Theme.textPrimary; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { color: playButton.hovered ? Theme.accentDark : Theme.surface; border.color: Theme.border; radius: 17 }
                            }
                            Button {
                                id: moveUpButton
                                implicitWidth: 32; implicitHeight: 32
                                enabled: trackRow.canMoveUp
                                onClicked: root.controller.movePlaylistItem(trackRow.itemId, trackRow.index - 1)
                                ToolTip.visible: hovered; ToolTip.text: "上移"
                                contentItem: Text { text: "↑"; color: Theme.textPrimary; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { color: moveUpButton.hovered ? Theme.surfaceHover : Theme.surface; border.color: Theme.border; radius: Theme.radiusSmall; opacity: moveUpButton.enabled ? 1 : 0.35 }
                            }
                            Button {
                                id: moveDownButton
                                implicitWidth: 32; implicitHeight: 32
                                enabled: trackRow.canMoveDown
                                onClicked: root.controller.movePlaylistItem(trackRow.itemId, trackRow.index + 1)
                                ToolTip.visible: hovered; ToolTip.text: "下移"
                                contentItem: Text { text: "↓"; color: Theme.textPrimary; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { color: moveDownButton.hovered ? Theme.surfaceHover : Theme.surface; border.color: Theme.border; radius: Theme.radiusSmall; opacity: moveDownButton.enabled ? 1 : 0.35 }
                            }
                            Button {
                                id: removeButton
                                implicitWidth: 32; implicitHeight: 32
                                onClicked: {
                                    root.pendingRemoveItemId = trackRow.itemId
                                    removeItemDialog.open()
                                }
                                ToolTip.visible: hovered; ToolTip.text: "从歌单移除"
                                contentItem: Text { text: "×"; color: Theme.danger; font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { color: removeButton.hovered ? Theme.surfaceHover : Theme.surface; border.color: Theme.border; radius: Theme.radiusSmall }
                            }
                        }

                        MouseArea {
                            id: trackMouse
                            anchors.fill: parent
                            z: 0
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton
                            onDoubleClicked: root.controller.playPlaylistItem(trackRow.index)
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        visible: playlistTrackView.count === 0
                        spacing: 8
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "歌单还是空的"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.DemiBold }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "从搜索结果中添加歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                    }
                }
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
        onOpened: { playlistName.text = ""; playlistName.forceActiveFocus() }
        onAccepted: root.controller.createPlaylist(playlistName.text)
        palette.window: Theme.surface; palette.windowText: Theme.textPrimary; palette.buttonText: Theme.textPrimary
        contentItem: TextField {
            id: playlistName
            implicitHeight: 40
            color: Theme.textPrimary
            placeholderText: "例如：通勤播放"
            placeholderTextColor: "#6f7a73"
            font.family: Theme.fontFamily
            background: Rectangle { color: Theme.window; border.color: playlistName.activeFocus ? Theme.accent : Theme.border; radius: Theme.radiusMedium }
        }
        background: Rectangle { color: Theme.surface; border.color: Theme.border; radius: Theme.radiusMedium }
    }

    Dialog {
        id: renameDialog
        anchors.centerIn: parent
        modal: true
        title: "重命名歌单"
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 380
        onOpened: { renamedPlaylistName.text = root.controller.selectedPlaylistName; renamedPlaylistName.selectAll(); renamedPlaylistName.forceActiveFocus() }
        onAccepted: root.controller.renamePlaylist(root.controller.selectedPlaylistId, renamedPlaylistName.text)
        palette.window: Theme.surface; palette.windowText: Theme.textPrimary; palette.buttonText: Theme.textPrimary
        contentItem: TextField {
            id: renamedPlaylistName
            implicitHeight: 40
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            background: Rectangle { color: Theme.window; border.color: renamedPlaylistName.activeFocus ? Theme.accent : Theme.border; radius: Theme.radiusMedium }
        }
        background: Rectangle { color: Theme.surface; border.color: Theme.border; radius: Theme.radiusMedium }
    }

    Dialog {
        id: deletePlaylistDialog
        anchors.centerIn: parent
        modal: true
        title: "删除歌单"
        standardButtons: Dialog.Yes | Dialog.Cancel
        onAccepted: root.controller.deletePlaylist(root.controller.selectedPlaylistId)
        palette.window: Theme.surface; palette.windowText: Theme.textPrimary; palette.buttonText: Theme.textPrimary
        contentItem: Text { text: "确定删除“" + root.controller.selectedPlaylistName + "”吗？\n歌曲文件和播放历史不会被删除。"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
        background: Rectangle { color: Theme.surface; border.color: Theme.border; radius: Theme.radiusMedium }
    }

    Dialog {
        id: removeItemDialog
        anchors.centerIn: parent
        modal: true
        title: "移除歌曲"
        standardButtons: Dialog.Yes | Dialog.Cancel
        onAccepted: root.controller.removePlaylistItem(root.pendingRemoveItemId)
        palette.window: Theme.surface; palette.windowText: Theme.textPrimary; palette.buttonText: Theme.textPrimary
        contentItem: Text { text: "确定从当前歌单移除这首歌曲吗？"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
        background: Rectangle { color: Theme.surface; border.color: Theme.border; radius: Theme.radiusMedium }
    }
}
