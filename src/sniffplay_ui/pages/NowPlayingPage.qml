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
    readonly property bool compact: width < 650
    property int contextQueueIndex: -1
    property bool contextQueueCurrent: false
    property int detailTab: 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.compact ? 18 : 26
        spacing: 16

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 3

                Text {
                    text: "正在播放"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 24
                    font.weight: Font.Bold
                }

                Text {
                    text: root.controller.hasCurrentTrack
                        ? "来自当前播放队列"
                        : "选择一首歌曲开始播放"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                id: shuffleButton
                visible: false
                implicitWidth: 38
                implicitHeight: 38
                onClicked: root.controller.toggleShuffle()
                ToolTip.visible: hovered
                ToolTip.text: root.controller.shuffleEnabled ? "关闭随机播放" : "开启随机播放"

                contentItem: AppIcon {
                    name: "shuffle"
                    color: root.controller.shuffleEnabled ? Theme.accent : Theme.textSecondary
                    iconSize: 18
                }
                background: Rectangle {
                    color: root.controller.shuffleEnabled ? Theme.accentDark : (shuffleButton.hovered ? Theme.surfaceHover : Theme.surface)
                    border.color: root.controller.shuffleEnabled ? Theme.accent : Theme.border
                    radius: 19
                }
            }

            Button {
                id: repeatButton
                visible: false
                implicitWidth: 38
                implicitHeight: 38
                onClicked: root.controller.cycleRepeatMode()
                ToolTip.visible: hovered
                ToolTip.text: root.controller.repeatMode === 0 ? "开启列表循环"
                    : (root.controller.repeatMode === 1 ? "切换为单曲循环" : "关闭循环播放")

                contentItem: Item {
                    AppIcon {
                        anchors.centerIn: parent
                        name: "repeat"
                        color: root.controller.repeatMode > 0 ? Theme.accent : Theme.textSecondary
                        iconSize: 18
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 2
                        anchors.bottomMargin: 1
                        visible: root.controller.repeatMode === 2
                        text: "1"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
                background: Rectangle {
                    color: root.controller.repeatMode > 0 ? Theme.accentDark : (repeatButton.hovered ? Theme.surfaceHover : Theme.surface)
                    border.color: root.controller.repeatMode > 0 ? Theme.accent : Theme.border
                    radius: 19
                }
            }

            Button {
                id: favoriteButton
                implicitWidth: 38
                implicitHeight: 38
                enabled: root.controller.hasCurrentTrack
                onClicked: root.controller.toggleCurrentFavorite()
                ToolTip.visible: hovered
                ToolTip.text: root.controller.currentFavorite ? "取消收藏" : "收藏"

                contentItem: AppIcon {
                    name: root.controller.currentFavorite ? "favorite-filled" : "favorite"
                    color: root.controller.currentFavorite ? Theme.danger : Theme.textSecondary
                    iconSize: 18
                }
                background: Rectangle {
                    color: favoriteButton.hovered ? Theme.surfaceHover : Theme.surface
                    border.color: root.controller.currentFavorite ? Theme.danger : Theme.border
                    radius: 19
                }
            }

            Button {
                id: moreButton
                implicitWidth: 38
                implicitHeight: 38
                ToolTip.visible: hovered
                ToolTip.text: "更多操作"
                onClicked: nowPlayingMenu.popup()
                contentItem: AppIcon {
                    name: "more"
                    color: Theme.textSecondary
                    iconSize: 17
                }
                background: Rectangle {
                    color: moreButton.hovered ? Theme.surfaceHover : Theme.transparent
                    radius: 19
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: root.compact ? 1 : 3
            columnSpacing: root.compact ? 0 : 24
            rowSpacing: 22

            Rectangle {
                id: nowPlayingCard
                Layout.fillWidth: root.compact
                Layout.preferredWidth: root.compact ? -1 : 330
                Layout.maximumWidth: root.compact ? 430 : 350
                Layout.fillHeight: !root.compact
                Layout.preferredHeight: root.compact ? 430 : -1
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                color: Theme.transparent
                border.color: Theme.transparent
                radius: Theme.radiusMedium

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: root.compact ? 16 : 24
                    anchors.rightMargin: root.compact ? 16 : 24
                    spacing: 10

                    Rectangle {
                        id: cover
                        Layout.fillWidth: true
                        Layout.preferredHeight: width
                        Layout.maximumHeight: Math.min(width, 300)
                        color: coverImage.status === Image.Error || coverImage.status === Image.Null
                            ? "#3d8bff"
                            : (root.controller ? root.controller.currentAccent : "#3d8bff")
                        radius: Theme.radiusMedium
                        clip: true
                        scale: coverHover.hovered ? 1.018 : 1.0

                        Behavior on scale {
                            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                        }

                        HoverHandler { id: coverHover }

                        Text {
                            anchors.centerIn: parent
                            text: root.controller.currentInitials
                            color: Theme.coverText
                            font.family: Theme.fontFamily
                            font.pixelSize: 44
                            font.bold: true
                            visible: coverImage.status !== Image.Ready
                        }

                        Image {
                            id: coverImage
                            anchors.fill: parent
                            source: root.controller.currentCoverUrl
                            sourceSize.width: 512
                            sourceSize.height: 512
                            asynchronous: true
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 10
                            width: playbackStateRow.implicitWidth + 18
                            height: 28
                            radius: Theme.radiusSmall
                            color: Qt.rgba(0.07, 0.07, 0.08, 0.82)
                            border.color: Qt.rgba(1, 1, 1, 0.14)

                            Row {
                                id: playbackStateRow
                                anchors.centerIn: parent
                                spacing: 6

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: root.controller.playing ? Theme.accent : Theme.textSecondary
                                }

                                Text {
                                    text: root.controller.playing ? "正在播放" : "已暂停"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: root.controller.currentTitle
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 22
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.controller.currentArtist
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.controller.currentAlbum
                            color: Theme.disabledText
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: sourceLabel.implicitWidth + 14
                            Layout.preferredHeight: 24
                            color: Theme.accentDark
                            radius: Theme.radiusSmall

                            Text {
                                id: sourceLabel
                                anchors.centerIn: parent
                                text: root.controller.currentSource
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            text: root.controller.queueLabel
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.controller.durationText
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    Slider {
                        id: progressSlider
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        from: 0
                        to: Math.max(1, root.controller.durationMs)
                        value: root.controller.positionMs
                        enabled: root.controller.hasCurrentTrack
                        onMoved: root.controller.seek(Math.round(value))

                        background: Rectangle {
                            x: progressSlider.leftPadding
                            y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                            width: progressSlider.availableWidth
                            height: 3
                            radius: 2
                            color: Theme.border
                            Rectangle {
                                width: progressSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: Theme.accent
                            }
                        }
                        handle: Rectangle {
                            x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                            y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                            width: progressSlider.hovered || progressSlider.pressed ? 12 : 8
                            height: width
                            radius: width / 2
                            color: Theme.accent
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: root.controller.positionText; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text { text: root.controller.durationText; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        spacing: 18
                        Item { Layout.fillWidth: true }

                        Button {
                            id: mainShuffleButton
                            implicitWidth: 38; implicitHeight: 38
                            onClicked: root.controller.toggleShuffle()
                            ToolTip.visible: hovered
                            ToolTip.text: root.controller.shuffleEnabled ? "关闭随机播放" : "开启随机播放"
                            contentItem: AppIcon {
                                name: "shuffle"
                                color: root.controller.shuffleEnabled ? Theme.accent : Theme.textSecondary
                                iconSize: 17
                            }
                            background: Rectangle {
                                color: mainShuffleButton.hovered ? Theme.surfaceHover : Theme.transparent
                                radius: 19
                            }
                        }

                        Button {
                            id: previousButton
                            implicitWidth: 38; implicitHeight: 38
                            enabled: root.controller.canGoPrevious
                            onClicked: root.controller.previousTrack()
                            ToolTip.visible: hovered; ToolTip.text: "上一首"
                            contentItem: AppIcon { name: "previous"; color: previousButton.enabled ? Theme.textPrimary : Theme.textSecondary; iconSize: 18 }
                            background: Rectangle { color: previousButton.hovered ? Theme.surfaceHover : Theme.transparent; radius: 19 }
                        }

                        Button {
                            id: playButton
                            implicitWidth: 54; implicitHeight: 54
                            enabled: root.controller.hasCurrentTrack
                            onClicked: root.controller.togglePlayback()
                            ToolTip.visible: hovered
                            ToolTip.text: root.controller.playing ? "暂停" : "播放"
                            contentItem: Item {
                                AppIcon { anchors.centerIn: parent; visible: !root.controller.loading; name: root.controller.playing ? "pause" : "play"; color: Theme.buttonText; iconSize: 20 }
                                Text { anchors.centerIn: parent; visible: root.controller.loading; text: "…"; color: Theme.buttonText; font.family: Theme.fontFamily; font.pixelSize: 18; font.bold: true }
                            }
                            background: Rectangle {
                                color: playButton.enabled ? (playButton.hovered ? Theme.accentHover : Theme.accent) : Theme.surface
                                radius: 27
                                opacity: playButton.enabled ? 1 : 0.45
                            }
                        }

                        Button {
                            id: nextButton
                            implicitWidth: 38; implicitHeight: 38
                            enabled: root.controller.canGoNext
                            onClicked: root.controller.nextTrack()
                            ToolTip.visible: hovered; ToolTip.text: "下一首"
                            contentItem: AppIcon { name: "next"; color: nextButton.enabled ? Theme.textPrimary : Theme.textSecondary; iconSize: 18 }
                            background: Rectangle { color: nextButton.hovered ? Theme.surfaceHover : Theme.transparent; radius: 19 }
                        }

                        Button {
                            id: mainRepeatButton
                            implicitWidth: 38; implicitHeight: 38
                            onClicked: root.controller.cycleRepeatMode()
                            ToolTip.visible: hovered
                            ToolTip.text: root.controller.repeatMode === 0 ? "开启列表循环"
                                : (root.controller.repeatMode === 1 ? "切换为单曲循环" : "关闭循环播放")
                            contentItem: Item {
                                AppIcon {
                                    anchors.centerIn: parent
                                    name: "repeat"
                                    color: root.controller.repeatMode > 0 ? Theme.accent : Theme.textSecondary
                                    iconSize: 17
                                }
                                Text {
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    visible: root.controller.repeatMode === 2
                                    text: "1"
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }
                            background: Rectangle {
                                color: mainRepeatButton.hovered ? Theme.surfaceHover : Theme.transparent
                                radius: 19
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    RowLayout {
                        visible: false
                        Layout.fillWidth: true

                        Text {
                            text: root.controller.queueLabel
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "VOL"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                        }

                        Slider {
                            id: volumeSlider
                            Layout.preferredWidth: 86
                            Layout.preferredHeight: 20
                            from: 0
                            to: 100
                            value: root.controller.volume
                            onMoved: root.controller.setVolume(Math.round(value))

                            background: Rectangle {
                                x: volumeSlider.leftPadding
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                width: volumeSlider.availableWidth
                                height: 3
                                radius: 2
                                color: Theme.border
                                Rectangle {
                                    width: volumeSlider.visualPosition * parent.width
                                    height: parent.height
                                    radius: 2
                                    color: Theme.textSecondary
                                }
                            }
                            handle: Rectangle {
                                x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                width: 9
                                height: 9
                                radius: 5
                                color: Theme.textPrimary
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: !root.compact
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                color: Theme.border
                opacity: 0.55
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: root.compact ? 250 : 0
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 158
                    Layout.preferredHeight: 38
                    color: Theme.surface
                    border.color: Theme.border
                    radius: Theme.radiusMedium

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3

                        Button {
                            id: queueTabButton
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            onClicked: root.detailTab = 0
                            contentItem: Text {
                                text: "播放队列"
                                color: root.detailTab === 0 ? Theme.textPrimary : Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: root.detailTab === 0 ? Font.DemiBold : Font.Normal
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: root.detailTab === 0
                                    ? Theme.surfaceHover
                                    : (queueTabButton.hovered ? Theme.buttonSurface : Theme.transparent)
                                radius: Theme.radiusSmall
                            }
                        }

                        Button {
                            id: lyricsTabButton
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            onClicked: root.detailTab = 1
                            contentItem: Text {
                                text: "歌词"
                                color: root.detailTab === 1 ? Theme.textPrimary : Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: root.detailTab === 1 ? Font.DemiBold : Font.Normal
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: root.detailTab === 1
                                    ? Theme.surfaceHover
                                    : (lyricsTabButton.hovered ? Theme.buttonSurface : Theme.transparent)
                                radius: Theme.radiusSmall
                            }
                        }
                    }
                }

                RowLayout {
                    visible: root.detailTab === 0
                    Layout.fillWidth: true
                    Text { text: "接下来播放"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
                    Item { Layout.fillWidth: true }
                    Text { text: queueView.count + " 首"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                    Button {
                        id: clearQueueButton
                        implicitWidth: 30
                        implicitHeight: 30
                        enabled: queueView.count > 1
                        onClicked: root.controller.clearQueueExceptCurrent()
                        ToolTip.visible: hovered
                        ToolTip.text: "清除其他歌曲"
                        contentItem: AppIcon {
                            name: "close"
                            color: clearQueueButton.enabled ? Theme.textSecondary : Theme.border
                            iconSize: 14
                        }
                        background: Rectangle {
                            color: clearQueueButton.hovered ? Theme.surfaceHover : Theme.transparent
                            radius: Theme.radiusSmall
                        }
                    }
                }

                ListView {
                    id: queueView
                    visible: root.detailTab === 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 3
                    model: root.controller.queueModel
                    currentIndex: root.controller.queueIndex
                    onCurrentIndexChanged: {
                        if (currentIndex >= 0)
                            positionViewAtIndex(currentIndex, ListView.Contain)
                    }
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        id: queueRow
                        required property int index
                        required property string title
                        required property string artist
                        required property string duration
                        required property string accent
                        required property string initials
                        required property string coverUrl
                        required property bool isCurrent
                        required property bool isFavorite

                        width: queueView.width
                        height: 56
                        color: queueRow.isCurrent ? Theme.accentDark : (queueHover.hovered ? Theme.surfaceHover : Theme.transparent)
                        radius: Theme.radiusMedium

                        RowLayout {
                            z: 1
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 12
                            spacing: 12

                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24

                                AppIcon {
                                    anchors.centerIn: parent
                                    visible: queueRow.isCurrent && !root.controller.loading
                                    name: root.controller.playing ? "pause" : "play"
                                    color: Theme.accent
                                    iconSize: 13
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !queueRow.isCurrent || root.controller.loading
                                    text: root.controller.loading && queueRow.isCurrent ? "…" : queueRow.index + 1
                                    color: queueRow.isCurrent ? Theme.accent : Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                color: queueCover.status === Image.Ready
                                    ? queueRow.accent
                                    : "#3d8bff"
                                radius: Theme.radiusSmall
                                clip: true

                                Text {
                                    anchors.centerIn: parent
                                    text: queueRow.initials
                                    color: Theme.buttonText
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    visible: queueCover.status !== Image.Ready
                                }

                                Image {
                                    id: queueCover
                                    anchors.fill: parent
                                    source: queueRow.coverUrl
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
                                Text { Layout.fillWidth: true; text: queueRow.title; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                Text { Layout.fillWidth: true; text: queueRow.artist; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight }
                            }
                            Text { text: queueRow.duration; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }

                            Row {
                                Layout.preferredWidth: 72
                                Layout.preferredHeight: 32
                                spacing: 4
                                opacity: queueHover.hovered ? 1 : 0
                                enabled: queueHover.hovered

                                Behavior on opacity {
                                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                                }

                                Button {
                                    id: queueFavoriteButton
                                    width: 32
                                    height: 32
                                    onClicked: root.controller.toggleQueueTrackFavorite(queueRow.index)
                                    ToolTip.visible: hovered
                                    ToolTip.text: queueRow.isFavorite ? "取消收藏" : "收藏"
                                    contentItem: AppIcon {
                                        name: queueRow.isFavorite ? "favorite-filled" : "favorite"
                                        color: queueRow.isFavorite ? Theme.danger : Theme.textSecondary
                                        iconSize: 16
                                    }
                                    background: Rectangle {
                                        color: queueFavoriteButton.hovered ? Theme.surfaceHover : Theme.surface
                                        border.color: queueRow.isFavorite ? Theme.danger : Theme.border
                                        radius: 16
                                    }
                                }

                                Button {
                                    id: queuePlayButton
                                    width: 32
                                    height: 32
                                    onClicked: queueRow.isCurrent
                                        ? root.controller.togglePlayback()
                                        : root.controller.playQueueTrack(queueRow.index)
                                    ToolTip.visible: hovered
                                    ToolTip.text: queueRow.isCurrent && root.controller.playing ? "暂停" : "播放"
                                    contentItem: AppIcon {
                                        name: queueRow.isCurrent && root.controller.playing ? "pause" : "play"
                                        color: Theme.textPrimary
                                        iconSize: 14
                                    }
                                    background: Rectangle {
                                        color: queuePlayButton.hovered ? Theme.accentDark : Theme.surface
                                        border.color: Theme.border
                                        radius: 16
                                    }
                                }
                            }
                        }

                        HoverHandler { id: queueHover }

                        MouseArea {
                            id: queueMouse
                            z: 0
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.LeftButton) {
                                    queueClickTimer.restart()
                                    return
                                }
                                root.contextQueueIndex = queueRow.index
                                root.contextQueueCurrent = queueRow.isCurrent
                                queueContextMenu.popup()
                            }
                            onDoubleClicked: function(mouse) {
                                if (mouse.button === Qt.LeftButton) {
                                    queueClickTimer.stop()
                                    root.controller.playQueueTrack(queueRow.index)
                                }
                            }
                        }

                        Timer {
                            id: queueClickTimer
                            interval: 250
                            repeat: false
                            onTriggered: root.controller.playQueueTrack(queueRow.index)
                        }
                    }

                    EmptyState {
                        anchors.centerIn: parent
                        visible: queueView.count === 0
                        width: Math.min(340, queueView.width)
                        iconName: "music"
                        title: "播放队列为空"
                        description: "从搜索、收藏或歌单中选择歌曲"
                        actionText: "去搜索歌曲"
                        actionIcon: "search"
                        onActionTriggered: root.browseRequested()
                    }
                }

                EmptyState {
                    visible: root.detailTab === 1
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    iconName: "music"
                    title: "暂无歌词"
                    description: "当前歌曲没有可用的歌词数据"
                }
            }
        }
    }

    AppMenu {
        id: nowPlayingMenu
        implicitWidth: 190

        ContextMenuItem {
            text: root.controller.currentFavorite ? "取消收藏" : "收藏"
            iconName: root.controller.currentFavorite ? "favorite-filled" : "favorite"
            enabled: root.controller.hasCurrentTrack
            onTriggered: root.controller.toggleCurrentFavorite()
        }

        ContextMenuItem {
            text: "清除其他歌曲"
            iconName: "close"
            enabled: queueView.count > 1
            onTriggered: root.controller.clearQueueExceptCurrent()
        }

        MenuSeparator {
            contentItem: Rectangle { implicitHeight: 1; color: Theme.border }
        }

        ContextMenuItem {
            text: "搜索更多歌曲"
            iconName: "search"
            onTriggered: root.browseRequested()
        }
    }

    AppMenu {
        id: queueContextMenu
        implicitWidth: 190
        onClosed: {
            root.contextQueueIndex = -1
            root.contextQueueCurrent = false
        }

        ContextMenuItem {
            text: "播放"
            iconName: "play"
            onTriggered: root.controller.playQueueTrack(root.contextQueueIndex)
        }

        ContextMenuItem {
            text: "下一首播放"
            iconName: "next"
            enabled: !root.contextQueueCurrent
            onTriggered: root.controller.playQueueTrackNext(root.contextQueueIndex)
        }

        MenuSeparator {
            contentItem: Rectangle { implicitHeight: 1; color: Theme.border }
        }

        ContextMenuItem {
            text: "从队列移除"
            iconName: "remove"
            danger: true
            enabled: !root.contextQueueCurrent
            onTriggered: root.controller.removeQueueTrack(root.contextQueueIndex)
        }
    }
}
