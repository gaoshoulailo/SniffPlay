pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
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
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 22
        anchors.bottomMargin: 22
        spacing: 14

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 4

                Text {
                    text: "搜索"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.pageTitleSize
                    font.weight: Font.Bold
                }

                Text {
                    text: searchField.text.length > 0
                        ? "找到 " + resultsList.count + " 首歌曲"
                        : "为你推荐 " + resultsList.count + " 首歌曲"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                id: refreshButton
                implicitWidth: 38
                implicitHeight: 38
                enabled: !root.controller.searching
                onClicked: {
                    sortBox.currentIndex = 0
                    root.controller.search(searchField.text)
                }
                ToolTip.visible: hovered
                ToolTip.text: "刷新"
                contentItem: AppIcon {
                    name: "refresh"
                    color: Theme.textSecondary
                    iconSize: 17
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
                leftPadding: 42
                rightPadding: 44
                placeholderText: "输入歌曲、歌手或专辑"
                placeholderTextColor: Theme.placeholderText
                color: Theme.textPrimary
                selectionColor: Theme.accentDark
                selectedTextColor: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                onAccepted: {
                    sortBox.currentIndex = 0
                    root.controller.search(text)
                }

                AppIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    name: "search"
                    color: searchField.activeFocus ? Theme.accent : Theme.textSecondary
                    iconSize: 16

                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                Button {
                    id: clearSearchButton
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 30
                    visible: searchField.text.length > 0
                    onClicked: {
                        searchField.clear()
                        searchField.forceActiveFocus()
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: "清空搜索"
                    contentItem: AppIcon {
                        name: "close"
                        color: clearSearchButton.hovered ? Theme.textPrimary : Theme.textSecondary
                        iconSize: 12
                    }
                    background: Rectangle {
                        color: clearSearchButton.hovered ? Theme.surfaceHover : Theme.transparent
                        radius: 15
                    }
                }

                background: Rectangle {
                    id: searchFieldBackground
                    color: Theme.surface
                    border.color: searchField.activeFocus ? Theme.accent : Theme.border
                    border.width: searchField.activeFocus ? 2 : 1
                    radius: Theme.radiusMedium

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Theme.accent
                        shadowOpacity: searchField.activeFocus ? 0.30 : 0
                        shadowBlur: 0.55
                        shadowScale: 1.015

                        Behavior on shadowOpacity { NumberAnimation { duration: 160 } }
                    }

                    Behavior on border.color { ColorAnimation { duration: 140 } }
                }
            }

            ComboBox {
                id: sortBox
                implicitWidth: 102
                implicitHeight: 38
                model: ["相关度", "时长", "歌名"]
                onActivated: root.controller.sortSearchResults(currentIndex)

                contentItem: Text {
                    leftPadding: 11
                    rightPadding: 28
                    text: sortBox.displayText
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                indicator: AppIcon {
                    x: sortBox.width - width - 10
                    anchors.verticalCenter: parent.verticalCenter
                    name: "down"
                    color: Theme.textSecondary
                    iconSize: 12
                }

                background: Rectangle {
                    color: sortBox.hovered ? Theme.buttonHover : Theme.buttonSurface
                    border.color: sortBox.activeFocus ? Theme.accent : Theme.border
                    radius: Theme.radiusMedium
                }
            }

            AppButton {
                iconName: "folder-open"
                text: root.width >= 820 ? "本地音频" : ""
                ToolTip.visible: hovered
                ToolTip.text: "打开本地音频"
                onClicked: localFileDialog.open()
            }

            AppButton {
                text: root.controller.searching ? "…" : "搜索"
                iconName: root.controller.searching ? "" : "search"
                primary: true
                enabled: !root.controller.searching
                onClicked: {
                    sortBox.currentIndex = 0
                    root.controller.search(searchField.text)
                }
            }

            BusyIndicator {
                running: root.controller.searching
                visible: root.controller.searching
                palette.highlight: Theme.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 3

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
                Item { Layout.preferredWidth: 40 }
                Text { Layout.fillWidth: true; Layout.maximumWidth: 320; text: "歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.listMetaSize }
                Item { Layout.fillWidth: true }
                Text { visible: resultsList.showAlbum; Layout.preferredWidth: 130; text: "专辑"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.listMetaSize }
                Text { visible: resultsList.showSource; Layout.preferredWidth: 58; text: "来源"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.listMetaSize }
                Text { Layout.preferredWidth: 44; text: "时长"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.listMetaSize }
                Item { Layout.preferredWidth: 104 }
            }
        }

        ListView {
            id: resultsList
            readonly property bool showAlbum: width >= 720
            readonly property bool showSource: width >= 560

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 3
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

                height: 60
                x: rowHover.hovered ? 2 : 0
                width: resultsList.width - 2
                color: root.contextTrackIndex === trackRow.index
                    ? Theme.accentDark
                    : (rowHover.hovered ? Theme.surfaceHover : Theme.transparent)
                radius: Theme.radiusMedium

                Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: root.contextTrackIndex === trackRow.index ? 34 : 0
                    radius: 1
                    color: Theme.accent
                    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                }

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
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        color: coverImage.status === Image.Ready ? trackRow.accent : "#3d8bff"
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
                        Layout.maximumWidth: 320
                        spacing: 1

                        Text {
                            id: titleText
                            Layout.fillWidth: true
                            maximumLineCount: 1
                            text: trackRow.title
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.listTitleSize
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Text { Layout.fillWidth: true; maximumLineCount: 1; text: trackRow.artist; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.listMetaSize; elide: Text.ElideRight }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: resultsList.showAlbum
                        Layout.preferredWidth: 130
                        maximumLineCount: 1
                        text: trackRow.album
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.listMetaSize
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: resultsList.showSource
                        Layout.preferredWidth: 58
                        maximumLineCount: 1
                        text: trackRow.source
                        color: Theme.sourceAccent
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.preferredWidth: 44
                        text: trackRow.duration
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }

                    Row {
                        Layout.preferredWidth: 104
                        Layout.preferredHeight: 30
                        spacing: 2
                        opacity: rowHover.hovered || root.contextTrackIndex === trackRow.index ? 1 : 0
                        enabled: opacity > 0

                        Behavior on opacity { NumberAnimation { duration: 140 } }

                        Button {
                            id: favoriteButton
                            width: 30; height: 30
                            onClicked: root.controller.toggleTrackFavorite(trackRow.index)
                            ToolTip.visible: hovered
                            ToolTip.text: trackRow.isFavorite ? "取消收藏" : "收藏"
                            contentItem: AppIcon { name: trackRow.isFavorite ? "favorite-filled" : "favorite"; color: trackRow.isFavorite ? Theme.danger : Theme.textSecondary; iconSize: 15 }
                            background: Rectangle { color: favoriteButton.hovered ? Theme.buttonHover : Theme.transparent; radius: 15 }
                        }

                        Button {
                            id: rowAddButton
                            width: 30; height: 30
                            onClicked: {
                                root.pendingTrackIndex = trackRow.index
                                addToPlaylistDialog.open()
                            }
                            ToolTip.visible: hovered
                            ToolTip.text: "加入歌单"
                            contentItem: AppIcon { name: "add"; color: Theme.textSecondary; iconSize: 15 }
                            background: Rectangle { color: rowAddButton.hovered ? Theme.buttonHover : Theme.transparent; radius: 15 }
                        }

                        Button {
                            id: rowPlayButton
                            width: 30; height: 30
                            onClicked: root.controller.playSearchResult(trackRow.index)
                            ToolTip.visible: hovered
                            ToolTip.text: "播放"
                            contentItem: AppIcon { name: "play"; color: Theme.textPrimary; iconSize: 13 }
                            background: Rectangle { color: rowPlayButton.hovered ? Theme.buttonHover : Theme.transparent; radius: 15 }
                        }
                    }
                }

                HoverHandler { id: rowHover }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    z: 0
                    onDoubleClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton)
                            root.controller.playSearchResult(trackRow.index)
                    }
                    onClicked: function(mouse) {
                        if (mouse.button !== Qt.RightButton)
                            return
                        root.contextTrackIndex = trackRow.index
                        root.contextTrackFavorite = trackRow.isFavorite
                        trackContextMenu.popup()
                    }
                }

            }

            EmptyState {
                anchors.centerIn: parent
                visible: resultsList.count === 0 && !root.controller.searching
                width: Math.min(360, resultsList.width)
                iconName: "search"
                title: "没有找到匹配的歌曲"
                description: "换一个歌名、歌手或专辑关键词试试"
                actionText: "重新输入"
                actionIcon: "search"
                onActionTriggered: searchField.forceActiveFocus()
            }
        }
    }
    }

    AppMenu {
        id: trackContextMenu

        onClosed: root.contextTrackIndex = -1

        ContextMenuItem {
            text: "播放"
            iconName: "play"
            onTriggered: root.controller.playSearchResult(root.contextTrackIndex)
        }

        ContextMenuItem {
            text: root.contextTrackFavorite ? "取消收藏" : "收藏"
            iconName: root.contextTrackFavorite ? "favorite-filled" : "favorite"
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
            iconName: "add"
            onTriggered: {
                root.pendingTrackIndex = root.contextTrackIndex
                addToPlaylistDialog.open()
            }
        }

        ContextMenuItem {
            text: "复制歌曲信息"
            iconName: "copy"
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
                        AppIcon {
                            name: "check"
                            visible: root.pendingPlaylistId === playlistChoice.playlistId
                            color: Theme.accent
                            iconSize: 14
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
                iconName: "add"
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

    PlaylistNameDialog {
        id: newPlaylistWithTrackDialog
        anchors.centerIn: parent
        description: "创建歌单并将当前歌曲添加进去"
        placeholderText: "输入歌单名称"
        onSubmitted: function(name) {
            root.controller.createPlaylistWithTrack(
                name,
                root.pendingTrackIndex
            )
            addToPlaylistDialog.close()
        }
    }

    Component.onCompleted: root.controller.loadInitialSearch("")
}
