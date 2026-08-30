pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import "../themes"

Item {
    id: root

    required property var controller
    property int contextHistoryIndex: -1
    property int contextHistoryId: -1
    property bool contextHistoryFavorite: false
    property int pendingHistoryIndex: -1
    property int pendingPlaylistId: -1

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
                required property int historyId
                required property string title
                required property string artist
                required property string album
                required property string duration
                required property string accent
                required property string initials
                required property string coverUrl
                required property string playedAt
                required property bool isFavorite

                width: historyView.width
                height: 58
                color: root.contextHistoryIndex === historyRow.index
                    ? Theme.accentDark
                    : (historyMouse.containsMouse ? Theme.surfaceHover : Theme.transparent)
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
                        color: historyCover.status === Image.Ready ? historyRow.accent : "#3d8bff"
                        radius: Theme.radiusSmall
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            text: historyRow.initials
                            color: Theme.buttonText
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.bold: true
                            visible: historyCover.status !== Image.Ready
                        }

                        Image {
                            id: historyCover
                            anchors.fill: parent
                            source: historyRow.coverUrl
                            sourceSize.width: 96
                            sourceSize.height: 96
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
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onDoubleClicked: root.controller.playHistory(historyRow.index)
                        }
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
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    z: 0
                    onClicked: function(mouse) {
                        if (mouse.button !== Qt.RightButton)
                            return
                        root.contextHistoryIndex = historyRow.index
                        root.contextHistoryId = historyRow.historyId
                        root.contextHistoryFavorite = historyRow.isFavorite
                        historyContextMenu.popup()
                    }
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

    Menu {
        id: historyContextMenu
        implicitWidth: 210
        modal: true
        palette.window: Theme.surface
        palette.windowText: Theme.textPrimary

        onClosed: {
            root.contextHistoryIndex = -1
            root.contextHistoryId = -1
        }

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium
        }

        ContextMenuItem {
            text: "播放"
            onTriggered: root.controller.playHistory(root.contextHistoryIndex)
        }

        ContextMenuItem {
            text: root.contextHistoryFavorite ? "取消收藏" : "收藏"
            onTriggered: {
                root.controller.toggleHistoryTrackFavorite(root.contextHistoryIndex)
                root.contextHistoryFavorite = !root.contextHistoryFavorite
            }
        }

        ContextMenuItem {
            text: "添加到歌单..."
            onTriggered: {
                root.pendingHistoryIndex = root.contextHistoryIndex
                addHistoryToPlaylistDialog.open()
            }
        }

        MenuSeparator {
            contentItem: Rectangle {
                implicitHeight: 1
                color: Theme.border
            }
        }

        ContextMenuItem {
            text: "从播放历史删除"
            onTriggered: root.controller.removeHistory(root.contextHistoryId)
        }
    }

    Dialog {
        id: addHistoryToPlaylistDialog
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
                id: historyPlaylistPicker
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
                    width: historyPlaylistPicker.width
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
                    visible: historyPlaylistPicker.count === 0
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
                onClicked: newPlaylistWithHistoryDialog.open()
            }
        }

        footer: Rectangle {
            implicitHeight: 58
            color: Theme.surface

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: addHistoryToPlaylistDialog.leftPadding
                anchors.rightMargin: addHistoryToPlaylistDialog.rightPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                AppButton {
                    Layout.fillWidth: true
                    text: "取消"
                    primary: true
                    onClicked: addHistoryToPlaylistDialog.reject()
                }

                AppButton {
                    Layout.fillWidth: true
                    text: "确定"
                    primary: true
                    enabled: root.pendingPlaylistId >= 0
                    onClicked: {
                        root.controller.addHistoryTrackToPlaylist(
                            root.pendingHistoryIndex,
                            root.pendingPlaylistId
                        )
                        addHistoryToPlaylistDialog.accept()
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
        id: newPlaylistWithHistoryDialog
        anchors.centerIn: parent
        width: 380
        modal: true
        title: "新建歌单"
        standardButtons: Dialog.Ok | Dialog.Cancel
        onOpened: {
            newHistoryPlaylistName.text = ""
            newHistoryPlaylistName.forceActiveFocus()
        }
        onAccepted: {
            root.controller.createPlaylistWithHistoryTrack(
                newHistoryPlaylistName.text,
                root.pendingHistoryIndex
            )
            addHistoryToPlaylistDialog.close()
        }
        palette.window: Theme.surface
        palette.windowText: Theme.textPrimary
        palette.button: Theme.accent
        palette.buttonText: Theme.buttonText

        contentItem: TextField {
            id: newHistoryPlaylistName
            implicitHeight: 40
            color: Theme.textPrimary
            placeholderText: "歌单名称"
            placeholderTextColor: Theme.placeholderText
            font.family: Theme.fontFamily
            background: Rectangle {
                color: Theme.window
                border.color: newHistoryPlaylistName.activeFocus ? Theme.accent : Theme.border
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
