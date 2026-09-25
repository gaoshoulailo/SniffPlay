pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../components"
import "../themes"

Item {
    id: root

    required property var controller
    signal browseRequested()
    property int pendingRemoveItemId: -1
    property int contextTrackIndex: -1
    property int contextTrackItemId: -1
    property bool contextTrackFavorite: false
    property int pendingTrackIndex: -1
    property int pendingPlaylistId: -1
    property int contextPlaylistId: -1
    property string contextPlaylistName: ""
    property bool contextPlaylistShortcut: false
    property int pendingShortcutPlaylistId: -1
    property string pendingShortcutPlaylistName: ""
    property int dialogPlaylistId: -1
    property string dialogPlaylistName: ""
    readonly property bool compact: width < 760

    function openRenameDialog(playlistId, playlistName) {
        root.dialogPlaylistId = playlistId
        root.dialogPlaylistName = playlistName
        renameDialog.open()
    }

    function openDeleteDialog(playlistId, playlistName) {
        root.dialogPlaylistId = playlistId
        root.dialogPlaylistName = playlistName
        deletePlaylistDialog.open()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 22

        Rectangle {
            Layout.preferredWidth: root.compact ? 190 : 230
            Layout.fillHeight: true
            color: Theme.transparent

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 1
                color: Theme.border
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.rightMargin: 18
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true

                    Text { text: "我的歌单"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 22; font.weight: Font.Bold }

                    Item { Layout.fillWidth: true }

                    AppButton {
                        text: ""
                        iconName: "add"
                        primary: true
                        ToolTip.visible: hovered
                        ToolTip.text: "新建歌单"
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
                        color: root.controller.selectedPlaylistId === playlistRow.playlistId
                            ? Theme.accentDark
                            : (playlistMouse.containsMouse ? Theme.surfaceHover : Theme.transparent)
                        radius: Theme.radiusMedium

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: root.controller.selectedPlaylistId === playlistRow.playlistId ? 24 : 0
                            radius: 2
                            color: Theme.accent
                            Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        }

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
                                AppIcon { anchors.centerIn: parent; name: "music"; color: Theme.accent; iconSize: 17 }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text { Layout.fillWidth: true; text: playlistRow.name; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                Text { text: playlistRow.countLabel; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                            }

                            AppIcon { name: "chevron-right"; color: Theme.textSecondary; iconSize: 16 }
                        }

                        MouseArea {
                            id: playlistMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.LeftButton) {
                                    root.controller.openPlaylist(playlistRow.playlistId)
                                    return
                                }
                                root.contextPlaylistId = playlistRow.playlistId
                                root.contextPlaylistName = playlistRow.name
                                root.contextPlaylistShortcut = root.controller.isPlaylistShortcut(
                                    playlistRow.playlistId
                                )
                                playlistContextMenu.popup()
                            }
                        }

                    }

                    EmptyState {
                        anchors.centerIn: parent
                        visible: playlistView.count === 0
                        width: Math.min(360, playlistView.width)
                        iconName: "list"
                        title: "还没有歌单"
                        description: "创建歌单后，可从搜索结果添加歌曲"
                        actionText: "新建歌单"
                        actionIcon: "add"
                        onActionTriggered: createDialog.open()
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                visible: root.controller.hasSelectedPlaylist
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Button {
                        id: backButton
                        visible: false
                        implicitWidth: 38
                        implicitHeight: 38
                        onClicked: root.controller.closePlaylist()
                        ToolTip.visible: hovered
                        ToolTip.text: "返回歌单列表"
                        contentItem: AppIcon { name: "back"; color: Theme.textPrimary; iconSize: 17 }
                        background: Rectangle { color: backButton.hovered ? Theme.surfaceHover : Theme.surface; border.color: Theme.border; radius: Theme.radiusMedium }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: root.controller.selectedPlaylistName
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 24
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Text {
                            text: playlistTrackView.count + " 首歌曲 · 可拖动整理播放顺序"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    AppButton {
                        text: "播放全部"
                        iconName: "play"
                        primary: true
                        enabled: playlistTrackView.count > 0
                        onClicked: root.controller.playSelectedPlaylist()
                    }
                    AppButton {
                        text: ""
                        iconName: "edit"
                        ToolTip.visible: hovered
                        ToolTip.text: "重命名歌单"
                        onClicked: root.openRenameDialog(
                            root.controller.selectedPlaylistId,
                            root.controller.selectedPlaylistName
                        )
                    }
                    AppButton {
                        text: ""
                        iconName: "delete"
                        ToolTip.visible: hovered
                        ToolTip.text: "删除歌单"
                        onClicked: root.openDeleteDialog(
                            root.controller.selectedPlaylistId,
                            root.controller.selectedPlaylistName
                        )
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 18
                    Text { Layout.fillWidth: true; text: "歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                    Text { visible: !root.compact; Layout.preferredWidth: 130; text: "专辑"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                    Text { Layout.preferredWidth: 54; text: "时长"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                    Item { Layout.preferredWidth: root.compact ? 72 : 146 }
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
                        required property bool isFavorite
                        required property bool canMoveUp
                        required property bool canMoveDown

                        width: playlistTrackView.width
                        height: 60
                        color: root.contextTrackIndex === trackRow.index
                            ? Theme.accentDark
                            : (trackMouse.containsMouse ? Theme.surfaceHover : Theme.transparent)
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
                                color: trackCover.status === Image.Ready ? trackRow.accent : "#3d8bff"
                                radius: Theme.radiusSmall
                                clip: true
                                Text { anchors.centerIn: parent; text: trackRow.initials; color: Theme.buttonText; font.family: Theme.fontFamily; font.bold: true; visible: trackCover.status !== Image.Ready }
                                Image { id: trackCover; anchors.fill: parent; source: trackRow.coverUrl; sourceSize.width: 96; sourceSize.height: 96; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: status === Image.Ready }
                            }

                            Item {
                                Layout.fillWidth: true

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.verticalCenter
                                    text: trackRow.title
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.verticalCenter
                                    anchors.topMargin: 2
                                    text: trackRow.artist
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    onDoubleClicked: root.controller.playPlaylistItem(trackRow.index)
                                }
                            }

                            Text { visible: !root.compact; Layout.preferredWidth: 130; text: trackRow.album; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight }
                            Text { Layout.preferredWidth: 54; text: trackRow.duration; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }

                            Button {
                                id: playButton
                                implicitWidth: 34; implicitHeight: 34
                                onClicked: root.controller.playPlaylistItem(trackRow.index)
                                ToolTip.visible: hovered; ToolTip.text: "播放"
                                contentItem: AppIcon { name: "play"; color: Theme.textPrimary; iconSize: 14 }
                                background: Rectangle { color: playButton.hovered ? Theme.accentDark : Theme.surface; border.color: Theme.border; radius: 17 }
                            }
                            Button {
                                id: moveUpButton
                                visible: !root.compact
                                implicitWidth: 32; implicitHeight: 32
                                enabled: trackRow.canMoveUp
                                onClicked: root.controller.movePlaylistItem(trackRow.itemId, trackRow.index - 1)
                                ToolTip.visible: hovered; ToolTip.text: "上移"
                                contentItem: AppIcon { name: "up"; color: Theme.textPrimary; iconSize: 14 }
                                background: Rectangle { color: moveUpButton.hovered ? Theme.surfaceHover : Theme.surface; border.color: Theme.border; radius: Theme.radiusSmall; opacity: moveUpButton.enabled ? 1 : 0.35 }
                            }
                            Button {
                                id: moveDownButton
                                visible: !root.compact
                                implicitWidth: 32; implicitHeight: 32
                                enabled: trackRow.canMoveDown
                                onClicked: root.controller.movePlaylistItem(trackRow.itemId, trackRow.index + 1)
                                ToolTip.visible: hovered; ToolTip.text: "下移"
                                contentItem: AppIcon { name: "down"; color: Theme.textPrimary; iconSize: 14 }
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
                                contentItem: AppIcon { name: "remove"; color: Theme.danger; iconSize: 14 }
                                background: Rectangle { color: removeButton.hovered ? Theme.surfaceHover : Theme.surface; border.color: Theme.border; radius: Theme.radiusSmall }
                            }
                        }

                        MouseArea {
                            id: trackMouse
                            anchors.fill: parent
                            z: 0
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(mouse) {
                                if (mouse.button !== Qt.RightButton)
                                    return
                                root.contextTrackIndex = trackRow.index
                                root.contextTrackItemId = trackRow.itemId
                                root.contextTrackFavorite = trackRow.isFavorite
                                playlistTrackContextMenu.popup()
                            }
                        }

                    }

                    EmptyState {
                        anchors.centerIn: parent
                        visible: playlistTrackView.count === 0
                        width: Math.min(360, playlistTrackView.width)
                        iconName: "music"
                        title: "歌单还是空的"
                        description: "从搜索结果中添加歌曲"
                        actionText: "去搜索歌曲"
                        actionIcon: "search"
                        onActionTriggered: root.browseRequested()
                    }
                }
            }

            EmptyState {
                anchors.centerIn: parent
                visible: !root.controller.hasSelectedPlaylist
                width: Math.min(360, parent.width - 40)
                iconName: "list"
                title: "选择一个歌单"
                description: "歌曲与播放顺序会显示在这里"
                actionText: "新建歌单"
                actionIcon: "add"
                onActionTriggered: createDialog.open()
            }
        }
    }

    AppMenu {
        id: playlistContextMenu

        onClosed: {
            root.contextPlaylistId = -1
            root.contextPlaylistName = ""
            root.contextPlaylistShortcut = false
        }

        ContextMenuItem {
            text: "打开歌单"
            iconName: "list"
            onTriggered: root.controller.openPlaylist(root.contextPlaylistId)
        }

        ContextMenuItem {
            text: "播放全部"
            iconName: "play"
            onTriggered: root.controller.playPlaylist(root.contextPlaylistId)
        }

        ContextMenuItem {
            text: root.contextPlaylistShortcut ? "取消固定" : "固定到快捷歌单"
            iconName: root.contextPlaylistShortcut ? "remove" : "add"
            onTriggered: {
                if (root.contextPlaylistShortcut) {
                    root.controller.unpinPlaylistShortcut(root.contextPlaylistId)
                } else if (root.controller.shortcutPlaylistCount < 3) {
                    root.controller.pinPlaylistShortcut(root.contextPlaylistId)
                } else {
                    root.pendingShortcutPlaylistId = root.contextPlaylistId
                    root.pendingShortcutPlaylistName = root.contextPlaylistName
                    Qt.callLater(function() { replaceShortcutDialog.open() })
                }
            }
        }

        MenuSeparator {
            contentItem: Rectangle {
                implicitHeight: 1
                color: Theme.border
            }
        }

        ContextMenuItem {
            text: "重命名"
            iconName: "edit"
            onTriggered: root.openRenameDialog(
                root.contextPlaylistId,
                root.contextPlaylistName
            )
        }

        ContextMenuItem {
            text: "删除歌单"
            iconName: "delete"
            danger: true
            onTriggered: root.openDeleteDialog(
                root.contextPlaylistId,
                root.contextPlaylistName
            )
        }
    }

    AppMenu {
        id: playlistTrackContextMenu

        onClosed: {
            root.contextTrackIndex = -1
            root.contextTrackItemId = -1
        }

        ContextMenuItem {
            text: "播放"
            iconName: "play"
            onTriggered: root.controller.playPlaylistItem(root.contextTrackIndex)
        }

        ContextMenuItem {
            text: root.contextTrackFavorite ? "取消收藏" : "收藏"
            iconName: root.contextTrackFavorite ? "favorite-filled" : "favorite"
            onTriggered: {
                root.controller.togglePlaylistTrackFavorite(root.contextTrackIndex)
                root.contextTrackFavorite = !root.contextTrackFavorite
            }
        }

        ContextMenuItem {
            text: "添加到歌单..."
            iconName: "add"
            onTriggered: {
                root.pendingTrackIndex = root.contextTrackIndex
                addPlaylistTrackDialog.open()
            }
        }

        MenuSeparator {
            contentItem: Rectangle {
                implicitHeight: 1
                color: Theme.border
            }
        }

        ContextMenuItem {
            text: "从当前歌单移除"
            iconName: "remove"
            danger: true
            onTriggered: {
                root.pendingRemoveItemId = root.contextTrackItemId
                removeItemDialog.open()
            }
        }
    }

    Dialog {
        id: addPlaylistTrackDialog
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
                id: targetPlaylistPicker
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
                    width: targetPlaylistPicker.width
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
            }

            AppButton {
                Layout.fillWidth: true
                text: "新建歌单并添加"
                iconName: "add"
                primary: true
                onClicked: newPlaylistWithPlaylistTrackDialog.open()
            }
        }

        footer: Rectangle {
            implicitHeight: 58
            color: Theme.surface

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: addPlaylistTrackDialog.leftPadding
                anchors.rightMargin: addPlaylistTrackDialog.rightPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                AppButton {
                    Layout.fillWidth: true
                    text: "取消"
                    primary: true
                    onClicked: addPlaylistTrackDialog.reject()
                }

                AppButton {
                    Layout.fillWidth: true
                    text: "确定"
                    primary: true
                    enabled: root.pendingPlaylistId >= 0
                    onClicked: {
                        root.controller.addPlaylistTrackToPlaylist(
                            root.pendingTrackIndex,
                            root.pendingPlaylistId
                        )
                        addPlaylistTrackDialog.accept()
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
        id: newPlaylistWithPlaylistTrackDialog
        anchors.centerIn: parent
        description: "创建歌单并将当前歌曲添加进去"
        placeholderText: "输入歌单名称"
        onSubmitted: function(name) {
            root.controller.createPlaylistWithPlaylistTrack(
                name,
                root.pendingTrackIndex
            )
            addPlaylistTrackDialog.close()
        }
    }

    PlaylistNameDialog {
        id: createDialog
        anchors.centerIn: parent
        description: "创建一个歌单，用来整理喜欢的歌曲"
        onSubmitted: function(name) { root.controller.createPlaylist(name) }
    }

    Dialog {
        id: replaceShortcutDialog
        anchors.centerIn: parent
        width: 410
        height: 330
        modal: true
        dim: true
        title: "替换快捷歌单"
        closePolicy: Popup.CloseOnEscape
        transformOrigin: Item.Center
        onClosed: {
            root.pendingShortcutPlaylistId = -1
            root.pendingShortcutPlaylistName = ""
        }

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
            implicitHeight: 62

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
                    text: replaceShortcutDialog.title
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }
            }
        }

        contentItem: ColumnLayout {
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: "快捷位置已满。选择一个歌单，将它替换为“"
                    + root.pendingShortcutPlaylistName + "”。"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 5
                clip: true
                model: root.controller.shortcutPlaylistModel

                delegate: Button {
                    id: shortcutChoice
                    required property int playlistId
                    required property string name
                    required property string countLabel
                    width: ListView.view.width
                    height: 48
                    onClicked: {
                        root.controller.replacePlaylistShortcut(
                            shortcutChoice.playlistId,
                            root.pendingShortcutPlaylistId
                        )
                        replaceShortcutDialog.close()
                    }

                    contentItem: RowLayout {
                        spacing: 10
                        AppIcon { name: "list"; color: Theme.textSecondary; iconSize: 15 }
                        Text {
                            Layout.fillWidth: true
                            text: shortcutChoice.name
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Text {
                            text: shortcutChoice.countLabel
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                        AppIcon { name: "refresh"; color: Theme.accent; iconSize: 14 }
                    }

                    background: Rectangle {
                        color: shortcutChoice.hovered ? Theme.surfaceHover : Theme.window
                        border.color: shortcutChoice.hovered ? Theme.accent : Theme.border
                        radius: Theme.radiusMedium
                    }
                }
            }
        }

        footer: Item {
            implicitHeight: 62
            AppButton {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: "取消"
                onClicked: replaceShortcutDialog.reject()
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

    Dialog {
        id: renameDialog
        anchors.centerIn: parent
        modal: true
        title: "重命名歌单"
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 380
        onOpened: { renamedPlaylistName.text = root.dialogPlaylistName; renamedPlaylistName.selectAll(); renamedPlaylistName.forceActiveFocus() }
        onAccepted: root.controller.renamePlaylist(root.dialogPlaylistId, renamedPlaylistName.text)
        palette.window: Theme.surface; palette.windowText: Theme.textPrimary; palette.button: Theme.accent; palette.buttonText: Theme.buttonText
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
        dim: true
        width: 410
        title: "删除歌单"
        closePolicy: Popup.CloseOnEscape
        transformOrigin: Item.Center
        onAccepted: root.controller.deletePlaylist(root.dialogPlaylistId)

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

        Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, 0.46) }

        header: Item {
            implicitHeight: 64

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 14
                anchors.bottomMargin: 6
                spacing: 11

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    color: Qt.rgba(1, 0.40, 0.45, 0.14)
                    radius: 18
                    AppIcon {
                        anchors.centerIn: parent
                        name: "delete"
                        color: Theme.danger
                        iconSize: 17
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: deletePlaylistDialog.title
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "此操作无法撤销"
                        color: Theme.danger
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }
            }
        }

        contentItem: ColumnLayout {
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "确定要删除这个歌单吗？"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                color: Theme.window
                border.color: Theme.border
                radius: Theme.radiusMedium

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 13
                    anchors.rightMargin: 13
                    spacing: 10

                    AppIcon {
                        name: "list"
                        color: Theme.textSecondary
                        iconSize: 16
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.dialogPlaylistName
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "只会删除歌单及其收录关系，歌曲文件、收藏和播放历史都会保留。"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.Wrap
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

                AppButton {
                    text: "取消"
                    onClicked: deletePlaylistDialog.reject()
                }

                AppButton {
                    text: "删除歌单"
                    iconName: "delete"
                    danger: true
                    onClicked: deletePlaylistDialog.accept()
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
                shadowOpacity: 0.54
                shadowBlur: 0.78
                shadowVerticalOffset: 12
            }
        }
    }

    Dialog {
        id: removeItemDialog
        anchors.centerIn: parent
        modal: true
        width: 380
        title: "移除歌曲"
        standardButtons: Dialog.Yes | Dialog.Cancel
        onAccepted: root.controller.removePlaylistItem(root.pendingRemoveItemId)
        palette.window: Theme.surface; palette.windowText: Theme.textPrimary; palette.button: Theme.accent; palette.buttonText: Theme.buttonText
        contentItem: Text { text: "确定从当前歌单移除这首歌曲吗？"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
        background: Rectangle { color: Theme.surface; border.color: Theme.border; radius: Theme.radiusMedium }
    }
}
