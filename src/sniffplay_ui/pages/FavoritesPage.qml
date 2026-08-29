pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import "../themes"

Item {
    id: root

    required property var controller
    property int contextFavoriteIndex: -1
    property int contextFavoriteId: -1
    property int pendingPlaylistId: -1
    readonly property bool compact: width < 760

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 18

        RowLayout {
            Layout.fillWidth: true

            Text { text: "喜爱"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold }

            Item { Layout.fillWidth: true }

            Button {
                id: shuffleButton
                implicitWidth: 38; implicitHeight: 38
                onClicked: root.controller.toggleShuffle()
                ToolTip.visible: hovered
                ToolTip.text: root.controller.shuffleEnabled ? "关闭随机播放" : "开启随机播放"
                contentItem: Text {
                    text: "⤨"
                    color: root.controller.shuffleEnabled ? Theme.accent : Theme.textSecondary
                    font.family: "Segoe UI Symbol"
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { color: shuffleButton.hovered ? Theme.surfaceHover : Theme.transparent; radius: 19 }
            }

            Button {
                id: refreshButton
                implicitWidth: 38; implicitHeight: 38
                onClicked: root.controller.refreshLibrary()
                ToolTip.visible: hovered; ToolTip.text: "刷新收藏"
                contentItem: Text {
                    text: "↻"
                    color: Theme.textSecondary
                    font.family: "Segoe UI Symbol"
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { color: refreshButton.hovered ? Theme.surfaceHover : Theme.transparent; radius: 19 }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: root.compact ? 1 : 2
            columnSpacing: 28

            Rectangle {
                visible: !root.compact
                Layout.preferredWidth: 350
                Layout.maximumWidth: 370
                Layout.fillHeight: true
                color: Theme.sidebar
                border.color: Theme.border
                radius: Theme.radiusMedium

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 18

                    Rectangle {
                        id: favoriteCover
                        Layout.fillWidth: true
                        Layout.preferredHeight: width
                        Layout.maximumHeight: 310
                        color: root.controller.hasCurrentTrack && favoriteCoverImage.status === Image.Ready
                            ? root.controller.currentAccent
                            : (root.controller.hasCurrentTrack ? "#3d8bff" : Theme.surface)
                        radius: Theme.radiusMedium
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            text: root.controller.hasCurrentTrack
                                ? root.controller.currentInitials
                                : "♥"
                            color: root.controller.hasCurrentTrack
                                ? Theme.coverText
                                : Theme.textSecondary
                            font.family: root.controller.hasCurrentTrack
                                ? Theme.fontFamily
                                : "Segoe UI Symbol"
                            font.pixelSize: 68
                            font.bold: root.controller.hasCurrentTrack
                            visible: favoriteCoverImage.status !== Image.Ready
                        }

                        Image {
                            id: favoriteCoverImage
                            anchors.fill: parent
                            source: root.controller.currentCoverUrl
                            sourceSize.width: 640
                            sourceSize.height: 640
                            asynchronous: true
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.controller.hasCurrentTrack
                            ? root.controller.currentTitle
                            : "你喜欢的歌曲"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        clip: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.controller.hasCurrentTrack
                            ? root.controller.currentArtist
                            : root.controller.favoriteCount + " 首收藏"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        clip: true
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text { text: "喜爱的歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
            Item { Layout.fillWidth: true }
            Text { text: root.controller.favoriteCount + " 首"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
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
                height: 64
                color: root.contextFavoriteIndex === favoriteRow.index
                    ? Theme.accentDark
                    : (rowMouse.containsMouse ? Theme.surfaceHover : Theme.transparent)
                radius: Theme.radiusMedium

                RowLayout {
                    z: 1
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 8
                    spacing: 12

                    Text {
                        Layout.preferredWidth: 30
                        text: favoriteRow.index + 1
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { Layout.fillWidth: true; text: favoriteRow.title; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: favoriteRow.artist; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight }
                    }

                    Text { visible: false; text: favoriteRow.album }
                    Text { Layout.preferredWidth: 42; text: favoriteRow.duration; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }

                    Button {
                        id: playButton
                        implicitWidth: 34; implicitHeight: 34
                        opacity: rowMouse.containsMouse ? 1 : 0
                        onClicked: root.controller.playFavorite(favoriteRow.index)
                        ToolTip.visible: hovered; ToolTip.text: "播放"
                        contentItem: Text { text: "▶"; color: Theme.textPrimary; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: playButton.hovered ? Theme.accentDark : Theme.surface; border.color: Theme.border; radius: 17 }
                    }

                    Button {
                        id: removeButton
                        implicitWidth: 34; implicitHeight: 34
                        opacity: rowMouse.containsMouse ? 1 : 0
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
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button !== Qt.RightButton)
                            return
                        root.contextFavoriteIndex = favoriteRow.index
                        root.contextFavoriteId = favoriteRow.favoriteId
                        favoriteContextMenu.popup()
                    }
                    onDoubleClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton)
                            root.controller.playFavorite(favoriteRow.index)
                    }
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
    }

    Menu {
        id: favoriteContextMenu
        implicitWidth: 210
        modal: true
        palette.window: Theme.surface
        palette.windowText: Theme.textPrimary

        onClosed: {
            root.contextFavoriteIndex = -1
            root.contextFavoriteId = -1
        }

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium
        }

        ContextMenuItem {
            text: "播放"
            onTriggered: root.controller.playFavorite(root.contextFavoriteIndex)
        }

        ContextMenuItem {
            text: "添加到歌单..."
            onTriggered: {
                root.pendingFavoriteIndex = root.contextFavoriteIndex
                addFavoriteToPlaylistDialog.open()
            }
        }

        MenuSeparator {
            contentItem: Rectangle {
                implicitHeight: 1
                color: Theme.border
            }
        }

        ContextMenuItem {
            text: "取消收藏"
            onTriggered: root.controller.removeFavorite(root.contextFavoriteId)
        }
    }

    property int pendingFavoriteIndex: -1

    Dialog {
        id: addFavoriteToPlaylistDialog
        anchors.centerIn: parent
        width: 390
        height: 440
        modal: true
        title: "加入歌单"
        onOpened: root.pendingPlaylistId = -1
        palette.window: Theme.surface
        palette.windowText: Theme.textPrimary
        palette.button: Theme.accent
        palette.buttonText: Theme.buttonText

        contentItem: ColumnLayout {
            spacing: 10

            ListView {
                id: favoritePlaylistPicker
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: root.controller.playlistModel

                delegate: Button {
                    id: playlistChoice
                    required property int playlistId
                    required property string name
                    required property string countLabel
                    width: favoritePlaylistPicker.width
                    height: 52
                    onClicked: root.pendingPlaylistId = playlistChoice.playlistId

                    contentItem: RowLayout {
                        spacing: 10
                        Text { Layout.fillWidth: true; text: playlistChoice.name; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; elide: Text.ElideRight }
                        Text { text: playlistChoice.countLabel; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                        Text { text: "✓"; visible: root.pendingPlaylistId === playlistChoice.playlistId; color: Theme.accent; font.pixelSize: 15; font.bold: true }
                    }

                    background: Rectangle {
                        color: root.pendingPlaylistId === playlistChoice.playlistId
                            ? Theme.accentDark
                            : (playlistChoice.hovered ? Theme.surfaceHover : Theme.window)
                        border.color: root.pendingPlaylistId === playlistChoice.playlistId
                            ? Theme.accent
                            : Theme.border
                        radius: Theme.radiusMedium
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: favoritePlaylistPicker.count === 0
                    text: "还没有歌单"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            AppButton {
                Layout.fillWidth: true
                text: "新建歌单并添加"
                primary: true
                onClicked: newPlaylistWithFavoriteDialog.open()
            }
        }

        footer: Rectangle {
            implicitHeight: 58
            color: Theme.surface

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: addFavoriteToPlaylistDialog.leftPadding
                anchors.rightMargin: addFavoriteToPlaylistDialog.rightPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                AppButton {
                    Layout.fillWidth: true
                    text: "取消"
                    primary: true
                    onClicked: addFavoriteToPlaylistDialog.reject()
                }

                AppButton {
                    Layout.fillWidth: true
                    text: "确定"
                    primary: true
                    enabled: root.pendingPlaylistId >= 0
                    onClicked: {
                        root.controller.addFavoriteTrackToPlaylist(
                            root.pendingFavoriteIndex,
                            root.pendingPlaylistId
                        )
                        addFavoriteToPlaylistDialog.accept()
                    }
                }
            }
        }

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium
        }
    }

    Dialog {
        id: newPlaylistWithFavoriteDialog
        anchors.centerIn: parent
        width: 380
        modal: true
        title: "新建歌单"
        standardButtons: Dialog.Ok | Dialog.Cancel
        onOpened: {
            newFavoritePlaylistName.text = ""
            newFavoritePlaylistName.forceActiveFocus()
        }
        onAccepted: {
            root.controller.createPlaylistWithFavorite(
                newFavoritePlaylistName.text,
                root.pendingFavoriteIndex
            )
            addFavoriteToPlaylistDialog.close()
        }
        palette.window: Theme.surface
        palette.windowText: Theme.textPrimary
        palette.button: Theme.accent
        palette.buttonText: Theme.buttonText

        contentItem: TextField {
            id: newFavoritePlaylistName
            implicitHeight: 40
            color: Theme.textPrimary
            placeholderText: "歌单名称"
            placeholderTextColor: Theme.placeholderText
            font.family: Theme.fontFamily
            background: Rectangle {
                color: Theme.window
                border.color: newFavoritePlaylistName.activeFocus ? Theme.accent : Theme.border
                radius: Theme.radiusMedium
            }
        }

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium
        }
    }
}
