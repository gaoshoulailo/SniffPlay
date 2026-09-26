pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import "../themes"

Item {
    id: root

    required property var controller
    signal browseRequested()
    property int contextFavoriteIndex: -1
    property int contextFavoriteId: -1
    property int pendingPlaylistId: -1

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
                contentItem: AppIcon {
                    name: "shuffle"
                    color: root.controller.shuffleEnabled ? Theme.accent : Theme.textSecondary
                    iconSize: 18
                }
                background: Rectangle { color: shuffleButton.hovered ? Theme.surfaceHover : Theme.transparent; radius: 19 }
            }

            Button {
                id: refreshButton
                implicitWidth: 38; implicitHeight: 38
                onClicked: root.controller.refreshLibrary()
                ToolTip.visible: hovered; ToolTip.text: "刷新收藏"
                contentItem: AppIcon {
                    name: "refresh"
                    color: Theme.textSecondary
                    iconSize: 17
                }
                background: Rectangle { color: refreshButton.hovered ? Theme.surfaceHover : Theme.transparent; radius: 19 }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "集中查看和管理已收藏的歌曲"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 62
            Layout.rightMargin: 18
            spacing: 12

            Text { Layout.fillWidth: true; text: "歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
            Text { visible: root.width >= 820; Layout.preferredWidth: 170; text: "专辑"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
            Text { visible: root.width >= 700; Layout.preferredWidth: 100; text: "收藏时间"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; horizontalAlignment: Text.AlignRight }
            Text { Layout.preferredWidth: 42; text: "时长"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
            Item { Layout.preferredWidth: 76 }
        }

        ListView {
            id: favoriteView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 2
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
                height: 58
                color: root.contextFavoriteIndex === favoriteRow.index
                    ? Theme.accentDark
                    : (favoriteHover.hovered ? Theme.surfaceHover : Theme.transparent)
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
                        color: favoriteCoverImage.status === Image.Ready ? favoriteRow.accent : "#3d8bff"
                        radius: Theme.radiusSmall
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            text: favoriteRow.initials
                            color: Theme.buttonText
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.bold: true
                            visible: favoriteCoverImage.status !== Image.Ready
                        }

                        Image {
                            id: favoriteCoverImage
                            anchors.fill: parent
                            source: favoriteRow.coverUrl
                            sourceSize.width: 96
                            sourceSize.height: 96
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { Layout.fillWidth: true; text: favoriteRow.title; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: favoriteRow.artist; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight }
                    }

                    Text {
                        visible: root.width >= 820
                        Layout.preferredWidth: 170
                        text: favoriteRow.album
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                    Text {
                        visible: root.width >= 700
                        Layout.preferredWidth: 100
                        text: favoriteRow.favoritedAt
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignRight
                    }
                    Text { Layout.preferredWidth: 42; text: favoriteRow.duration; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }

                    RowLayout {
                        Layout.preferredWidth: 76
                        spacing: 4
                        opacity: favoriteHover.hovered || root.contextFavoriteIndex === favoriteRow.index ? 1 : 0
                        enabled: favoriteHover.hovered || root.contextFavoriteIndex === favoriteRow.index

                        Behavior on opacity { NumberAnimation { duration: 120 } }

                        Button {
                            id: playButton
                            implicitWidth: 34; implicitHeight: 34
                            onClicked: root.controller.playFavorite(favoriteRow.index)
                            ToolTip.visible: hovered; ToolTip.text: "播放"
                            contentItem: AppIcon { name: "play"; color: Theme.textPrimary; iconSize: 14 }
                            background: Rectangle { color: playButton.hovered ? Theme.accentDark : Theme.surface; border.color: Theme.border; radius: 17 }
                        }

                        Button {
                            id: removeButton
                            implicitWidth: 34; implicitHeight: 34
                            onClicked: root.controller.removeFavorite(favoriteRow.favoriteId)
                            ToolTip.visible: hovered; ToolTip.text: "取消收藏"
                            contentItem: AppIcon { name: "favorite-filled"; color: Theme.danger; iconSize: 17 }
                            background: Rectangle { color: removeButton.hovered ? Theme.surfaceHover : Theme.surface; border.color: Theme.border; radius: 17 }
                        }
                    }
                }

                HoverHandler { id: favoriteHover }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    z: 0
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onDoubleClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton)
                            root.controller.playFavorite(favoriteRow.index)
                    }
                    onClicked: function(mouse) {
                        if (mouse.button !== Qt.RightButton)
                            return
                        root.contextFavoriteIndex = favoriteRow.index
                        root.contextFavoriteId = favoriteRow.favoriteId
                        favoriteContextMenu.popup()
                    }
                }

            }

            EmptyState {
                anchors.centerIn: parent
                visible: favoriteView.count === 0
                width: Math.min(360, favoriteView.width)
                iconName: "favorite"
                title: "还没有收藏"
                description: "在搜索结果或播放器中点击爱心收藏歌曲"
                actionText: "去搜索歌曲"
                actionIcon: "search"
                onActionTriggered: root.browseRequested()
            }
        }
    }

    AppMenu {
        id: favoriteContextMenu

        onClosed: {
            root.contextFavoriteIndex = -1
            root.contextFavoriteId = -1
        }

        ContextMenuItem {
            text: "播放"
            iconName: "play"
            onTriggered: root.controller.playFavorite(root.contextFavoriteIndex)
        }

        ContextMenuItem {
            text: "添加到歌单..."
            iconName: "add"
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
            iconName: "remove"
            danger: true
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
                        AppIcon { name: "check"; visible: root.pendingPlaylistId === playlistChoice.playlistId; color: Theme.accent; iconSize: 14 }
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
                iconName: "add"
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

    PlaylistNameDialog {
        id: newPlaylistWithFavoriteDialog
        anchors.centerIn: parent
        description: "创建歌单并将当前收藏添加进去"
        placeholderText: "输入歌单名称"
        onSubmitted: function(name) {
            root.controller.createPlaylistWithFavorite(
                name,
                root.pendingFavoriteIndex
            )
            addFavoriteToPlaylistDialog.close()
        }
    }
}
