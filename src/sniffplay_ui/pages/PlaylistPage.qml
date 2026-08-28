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
    property int contextTrackIndex: -1
    property int contextTrackItemId: -1
    property bool contextTrackFavorite: false
    property int pendingTrackIndex: -1
    property int pendingPlaylistId: -1
    property int contextPlaylistId: -1
    property string contextPlaylistName: ""
    property int dialogPlaylistId: -1
    property string dialogPlaylistName: ""

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
                        color: root.contextPlaylistId === playlistRow.playlistId
                            ? Theme.accentDark
                            : (playlistMouse.containsMouse ? Theme.surfaceHover : Theme.transparent)
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
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.LeftButton) {
                                    root.controller.openPlaylist(playlistRow.playlistId)
                                    return
                                }
                                root.contextPlaylistId = playlistRow.playlistId
                                root.contextPlaylistName = playlistRow.name
                                playlistContextMenu.popup()
                            }
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
                    AppButton {
                        text: "重命名"
                        onClicked: root.openRenameDialog(
                            root.controller.selectedPlaylistId,
                            root.controller.selectedPlaylistName
                        )
                    }
                    AppButton {
                        text: "删除歌单"
                        onClicked: root.openDeleteDialog(
                            root.controller.selectedPlaylistId,
                            root.controller.selectedPlaylistName
                        )
                    }
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
                                color: Theme.accent
                                radius: Theme.radiusSmall
                                clip: true
                                Text { anchors.centerIn: parent; text: trackRow.initials; color: Theme.buttonText; font.family: Theme.fontFamily; font.bold: true; visible: trackCover.status !== Image.Ready }
                                Image { id: trackCover; anchors.fill: parent; source: trackRow.coverUrl; sourceSize.width: 96; sourceSize.height: 96; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: status === Image.Ready }
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
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(mouse) {
                                if (mouse.button !== Qt.RightButton)
                                    return
                                root.contextTrackIndex = trackRow.index
                                root.contextTrackItemId = trackRow.itemId
                                root.contextTrackFavorite = trackRow.isFavorite
                                playlistTrackContextMenu.popup()
                            }
                            onDoubleClicked: function(mouse) {
                                if (mouse.button === Qt.LeftButton)
                                    root.controller.playPlaylistItem(trackRow.index)
                            }
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

    Menu {
        id: playlistContextMenu
        implicitWidth: 210
        modal: true
        palette.window: Theme.surface
        palette.windowText: Theme.textPrimary

        onClosed: {
            root.contextPlaylistId = -1
            root.contextPlaylistName = ""
        }

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium
        }

        ContextMenuItem {
            text: "打开歌单"
            onTriggered: root.controller.openPlaylist(root.contextPlaylistId)
        }

        ContextMenuItem {
            text: "播放全部"
            onTriggered: root.controller.playPlaylist(root.contextPlaylistId)
        }

        MenuSeparator {
            contentItem: Rectangle {
                implicitHeight: 1
                color: Theme.border
            }
        }

        ContextMenuItem {
            text: "重命名"
            onTriggered: root.openRenameDialog(
                root.contextPlaylistId,
                root.contextPlaylistName
            )
        }

        ContextMenuItem {
            text: "删除歌单"
            onTriggered: root.openDeleteDialog(
                root.contextPlaylistId,
                root.contextPlaylistName
            )
        }
    }

    Menu {
        id: playlistTrackContextMenu
        implicitWidth: 210
        modal: true
        palette.window: Theme.surface
        palette.windowText: Theme.textPrimary

        onClosed: {
            root.contextTrackIndex = -1
            root.contextTrackItemId = -1
        }

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium
        }

        ContextMenuItem {
            text: "播放"
            onTriggered: root.controller.playPlaylistItem(root.contextTrackIndex)
        }

        ContextMenuItem {
            text: root.contextTrackFavorite ? "取消收藏" : "收藏"
            onTriggered: {
                root.controller.togglePlaylistTrackFavorite(root.contextTrackIndex)
                root.contextTrackFavorite = !root.contextTrackFavorite
            }
        }

        ContextMenuItem {
            text: "添加到歌单..."
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
            }

            AppButton {
                Layout.fillWidth: true
                text: "新建歌单并添加"
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

    Dialog {
        id: newPlaylistWithPlaylistTrackDialog
        anchors.centerIn: parent
        width: 380
        modal: true
        title: "新建歌单"
        standardButtons: Dialog.Ok | Dialog.Cancel
        onOpened: {
            newPlaylistWithTrackName.text = ""
            newPlaylistWithTrackName.forceActiveFocus()
        }
        onAccepted: {
            root.controller.createPlaylistWithPlaylistTrack(
                newPlaylistWithTrackName.text,
                root.pendingTrackIndex
            )
            addPlaylistTrackDialog.close()
        }
        palette.window: Theme.surface
        palette.windowText: Theme.textPrimary
        palette.button: Theme.accent
        palette.buttonText: Theme.buttonText

        contentItem: TextField {
            id: newPlaylistWithTrackName
            implicitHeight: 40
            color: Theme.textPrimary
            placeholderText: "歌单名称"
            placeholderTextColor: Theme.placeholderText
            font.family: Theme.fontFamily
            background: Rectangle {
                color: Theme.window
                border.color: newPlaylistWithTrackName.activeFocus ? Theme.accent : Theme.border
                radius: Theme.radiusMedium
            }
        }

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium
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
        palette.window: Theme.surface; palette.windowText: Theme.textPrimary; palette.button: Theme.accent; palette.buttonText: Theme.buttonText
        contentItem: TextField {
            id: playlistName
            implicitHeight: 40
            color: Theme.textPrimary
            placeholderText: "例如：通勤播放"
            placeholderTextColor: Theme.placeholderText
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
        width: 380
        title: "删除歌单"
        standardButtons: Dialog.Yes | Dialog.Cancel
        onAccepted: root.controller.deletePlaylist(root.dialogPlaylistId)
        palette.window: Theme.surface; palette.windowText: Theme.textPrimary; palette.button: Theme.accent; palette.buttonText: Theme.buttonText
        contentItem: Text { text: "确定删除“" + root.dialogPlaylistName + "”吗？\n歌曲文件和播放历史不会被删除。"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
        background: Rectangle { color: Theme.surface; border.color: Theme.border; radius: Theme.radiusMedium }
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
