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
    property int pendingTrackIndex: -1
    property int pendingPlaylistId: -1
    property int contextTrackIndex: -1
    property bool contextTrackFavorite: false
    readonly property bool compact: width < 760

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 18

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "搜索"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 26
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }

            Button {
                id: headerShuffleButton
                implicitWidth: 38
                implicitHeight: 38
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
                background: Rectangle {
                    color: headerShuffleButton.hovered ? Theme.surfaceHover : Theme.transparent
                    radius: 19
                }
            }

            Button {
                id: refreshButton
                implicitWidth: 38
                implicitHeight: 38
                enabled: !root.controller.searching
                onClicked: root.controller.search(searchField.text)
                ToolTip.visible: hovered
                ToolTip.text: "刷新"
                contentItem: Text {
                    text: "↻"
                    color: Theme.textSecondary
                    font.family: "Segoe UI Symbol"
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: refreshButton.hovered ? Theme.surfaceHover : Theme.transparent
                    radius: 19
                    opacity: refreshButton.enabled ? 1 : 0.4
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: searchField
                Layout.fillWidth: true
                implicitHeight: 42
                leftPadding: 14
                rightPadding: 14
                placeholderText: "输入歌曲、歌手或专辑"
                placeholderTextColor: Theme.placeholderText
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
                text: "+"
                ToolTip.visible: hovered
                ToolTip.text: "打开本地音频"
                onClicked: localFileDialog.open()
            }

            AppButton {
                text: root.controller.searching ? "…" : "搜索"
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

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: root.compact ? 1 : 2
            columnSpacing: 22
            rowSpacing: 18

            Rectangle {
                Layout.fillWidth: root.compact
                Layout.preferredWidth: root.compact ? -1 : 330
                Layout.maximumWidth: root.compact ? 760 : 350
                Layout.fillHeight: !root.compact
                Layout.preferredHeight: root.compact ? 250 : -1
                color: Theme.sidebar
                border.color: Theme.border
                radius: Theme.radiusMedium

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: root.compact ? 14 : 22
                    spacing: root.compact ? 8 : 14

                    Text {
                        text: "发现新音乐"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    Text {
                        visible: !root.compact
                        text: "搜索歌曲、歌手或专辑"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }

                    Rectangle {
                        id: discoveryCover
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.compact ? 100 : width
                        Layout.maximumHeight: root.compact ? 100 : width
                        color: root.controller.hasCurrentTrack
                            ? root.controller.currentAccent
                            : Theme.surface
                        radius: Theme.radiusMedium
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            text: root.controller.hasCurrentTrack
                                ? root.controller.currentInitials
                                : "⌕"
                            color: root.controller.hasCurrentTrack
                                ? Theme.coverText
                                : Theme.textSecondary
                            font.family: root.controller.hasCurrentTrack
                                ? Theme.fontFamily
                                : "Segoe UI Symbol"
                            font.pixelSize: root.compact ? 42 : 64
                            font.bold: root.controller.hasCurrentTrack
                            opacity: root.controller.hasCurrentTrack ? 1 : 0.65
                            visible: discoveryCoverImage.status !== Image.Ready
                        }

                        Image {
                            id: discoveryCoverImage
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
                            : "从搜索结果中选择歌曲"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.controller.hasCurrentTrack && !root.compact
                        text: root.controller.currentArtist
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillHeight: true }

                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

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
            implicitHeight: 30
            visible: resultsList.count > 0
            color: Theme.transparent

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 12

                Item { Layout.preferredWidth: 28 }
                Item { Layout.preferredWidth: 48 }
                Text { Layout.fillWidth: true; text: "歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Text { visible: resultsList.showAlbum; Layout.preferredWidth: 130; text: "专辑"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Text { visible: resultsList.showSource; Layout.preferredWidth: 58; text: "来源"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Text { Layout.preferredWidth: 44; text: "时长"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Item { Layout.preferredWidth: 126 }
            }
        }

        ListView {
            id: resultsList
            readonly property bool showAlbum: width >= 720
            readonly property bool showSource: width >= 560

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
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
                required property bool isFavorite

                width: resultsList.width
                height: 72
                color: root.contextTrackIndex === trackRow.index
                    ? Theme.accentDark
                    : (rowMouse.containsMouse ? Theme.surfaceHover : Theme.transparent)
                radius: Theme.radiusMedium
                border.color: root.contextTrackIndex === trackRow.index
                    ? Theme.accent
                    : Theme.transparent

                RowLayout {
                    z: 1
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 12
                    spacing: 12

                    Text {
                        Layout.preferredWidth: 28
                        text: trackRow.index + 1
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        id: coverContainer
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        color: trackRow.accent
                        radius: Theme.radiusSmall
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            text: trackRow.initials
                            color: Theme.coverText
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.bold: true
                            visible: coverImage.status !== Image.Ready
                        }

                        Image {
                            id: coverImage
                            anchors.fill: parent
                            source: trackRow.coverUrl
                            sourceSize.width: 160
                            sourceSize.height: 160
                            asynchronous: true
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text { Layout.fillWidth: true; maximumLineCount: 1; text: trackRow.title; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; maximumLineCount: 1; text: trackRow.artist; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight }
                    }

                    Text {
                        visible: resultsList.showAlbum
                        Layout.preferredWidth: 130
                        maximumLineCount: 1
                        text: trackRow.album
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: resultsList.showSource
                        Layout.preferredWidth: 58
                        maximumLineCount: 1
                        text: trackRow.source
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.preferredWidth: 44
                        text: trackRow.duration
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }

                    Button {
                        id: favoriteButton
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        opacity: 1
                        onClicked: root.controller.toggleTrackFavorite(trackRow.index)
                        ToolTip.visible: hovered
                        ToolTip.text: trackRow.isFavorite ? "取消收藏" : "收藏"

                        contentItem: Text {
                            text: trackRow.isFavorite ? "♥" : "♡"
                            color: trackRow.isFavorite ? Theme.danger : Theme.textSecondary
                            font.family: "Segoe UI Symbol"
                            font.pixelSize: 19
                            font.weight: Font.Normal
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: favoriteButton.hovered ? Theme.surfaceHover : Theme.surface
                            border.color: trackRow.isFavorite ? Theme.danger : Theme.border
                            radius: 17
                        }
                    }

                    Button {
                        id: rowAddButton
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        opacity: 1
                        onClicked: {
                            root.pendingTrackIndex = trackRow.index
                            addToPlaylistDialog.open()
                        }
                        ToolTip.visible: hovered
                        ToolTip.text: "加入歌单"

                        contentItem: Text {
                            text: "+"
                            color: Theme.textPrimary
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: rowAddButton.hovered ? Theme.surfaceHover : Theme.surface
                            border.color: Theme.border
                            radius: 17
                        }
                    }

                    Button {
                        id: rowPlayButton
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        opacity: 1
                        onClicked: root.controller.playSearchResult(trackRow.index)
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
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    z: 0
                    onClicked: function(mouse) {
                        if (mouse.button !== Qt.RightButton)
                            return
                        root.contextTrackIndex = trackRow.index
                        root.contextTrackFavorite = trackRow.isFavorite
                        trackContextMenu.popup()
                    }
                    onDoubleClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton)
                            root.controller.playSearchResult(trackRow.index)
                    }
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
        }
    }

    Menu {
        id: trackContextMenu
        implicitWidth: 210
        modal: true
        palette.window: Theme.surface
        palette.windowText: Theme.textPrimary

        onClosed: root.contextTrackIndex = -1

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium
        }

        ContextMenuItem {
            text: "播放"
            onTriggered: root.controller.playSearchResult(root.contextTrackIndex)
        }

        ContextMenuItem {
            text: root.contextTrackFavorite ? "取消收藏" : "收藏"
            onTriggered: {
                root.controller.toggleTrackFavorite(root.contextTrackIndex)
                root.contextTrackFavorite = !root.contextTrackFavorite
            }
        }

        MenuSeparator {
            contentItem: Rectangle {
                implicitHeight: 1
                color: Theme.border
            }
        }

        ContextMenuItem {
            text: "添加到歌单..."
            onTriggered: {
                root.pendingTrackIndex = root.contextTrackIndex
                addToPlaylistDialog.open()
            }
        }

        ContextMenuItem {
            text: "复制歌曲信息"
            onTriggered: root.controller.copySearchTrackInfo(root.contextTrackIndex)
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

    Dialog {
        id: addToPlaylistDialog
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
                id: playlistPicker
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
                    width: playlistPicker.width
                    height: 52
                    onClicked: root.pendingPlaylistId = playlistChoice.playlistId

                    contentItem: RowLayout {
                        spacing: 10
                        Text { Layout.fillWidth: true; text: playlistChoice.name; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; elide: Text.ElideRight }
                        Text { text: playlistChoice.countLabel; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                        Text {
                            text: "✓"
                            visible: root.pendingPlaylistId === playlistChoice.playlistId
                            color: Theme.accent
                            font.pixelSize: 15
                            font.bold: true
                        }
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
                    visible: playlistPicker.count === 0
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
                onClicked: newPlaylistWithTrackDialog.open()
            }
        }

        footer: Rectangle {
            implicitHeight: 58
            color: Theme.surface

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: addToPlaylistDialog.leftPadding
                anchors.rightMargin: addToPlaylistDialog.rightPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Button {
                    id: cancelAddButton
                    Layout.fillWidth: true
                    implicitHeight: 36
                    onClicked: addToPlaylistDialog.reject()

                    contentItem: Text {
                        text: "取消"
                        color: Theme.buttonText
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: cancelAddButton.hovered ? Theme.accentHover : Theme.accent
                        border.color: Theme.accent
                        border.width: 1
                        radius: Theme.radiusMedium
                    }
                }

                Button {
                    id: confirmAddButton
                    Layout.fillWidth: true
                    implicitHeight: 36
                    enabled: root.pendingPlaylistId >= 0
                    onClicked: {
                        root.controller.addSearchTrackToPlaylist(
                            root.pendingTrackIndex,
                            root.pendingPlaylistId
                        )
                        addToPlaylistDialog.accept()
                    }

                    contentItem: Text {
                        text: "确定"
                        color: Theme.buttonText
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: confirmAddButton.hovered ? Theme.accentHover : Theme.accent
                        border.color: Theme.accent
                        border.width: 1
                        radius: Theme.radiusMedium
                        opacity: confirmAddButton.enabled ? 1 : 0.4
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
        id: newPlaylistWithTrackDialog
        anchors.centerIn: parent
        width: 380
        modal: true
        title: "新建歌单"
        standardButtons: Dialog.Ok | Dialog.Cancel
        onOpened: {
            newPlaylistName.text = ""
            newPlaylistName.forceActiveFocus()
        }
        onAccepted: {
            root.controller.createPlaylistWithTrack(
                newPlaylistName.text,
                root.pendingTrackIndex
            )
            addToPlaylistDialog.close()
        }
        palette.window: Theme.surface
        palette.windowText: Theme.textPrimary
        palette.button: Theme.accent
        palette.buttonText: Theme.buttonText

        contentItem: TextField {
            id: newPlaylistName
            implicitHeight: 40
            color: Theme.textPrimary
            placeholderText: "歌单名称"
            placeholderTextColor: Theme.placeholderText
            font.family: Theme.fontFamily
            background: Rectangle {
                color: Theme.window
                border.color: newPlaylistName.activeFocus ? Theme.accent : Theme.border
                radius: Theme.radiusMedium
            }
        }
        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium
        }
    }

    Component.onCompleted: root.controller.search("")
}
