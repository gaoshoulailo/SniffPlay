pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import "../themes"

Item {
    id: root

    required property var controller
    readonly property bool compact: width < 650
    property int contextQueueIndex: -1
    property bool contextQueueCurrent: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.compact ? 20 : 30
        spacing: 20

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "正在播放"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 26
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }

            Button {
                id: favoriteButton
                implicitWidth: 38
                implicitHeight: 38
                enabled: root.controller.hasCurrentTrack
                onClicked: root.controller.toggleCurrentFavorite()
                ToolTip.visible: hovered
                ToolTip.text: root.controller.currentFavorite ? "取消收藏" : "收藏"

                contentItem: Text {
                    text: root.controller.currentFavorite ? "♥" : "♡"
                    color: root.controller.currentFavorite ? Theme.danger : Theme.textSecondary
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: favoriteButton.hovered ? Theme.surfaceHover : Theme.transparent
                    border.color: favoriteButton.hovered ? Theme.border : Theme.transparent
                    radius: Theme.radiusMedium
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: root.compact ? 1 : 2
            columnSpacing: 32
            rowSpacing: 22

            Rectangle {
                Layout.fillWidth: root.compact
                Layout.preferredWidth: root.compact ? -1 : 330
                Layout.maximumWidth: root.compact ? 430 : 350
                Layout.fillHeight: !root.compact
                Layout.preferredHeight: root.compact ? 430 : -1
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                color: Theme.sidebar
                border.color: Theme.border
                radius: Theme.radiusMedium

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 12

                    Rectangle {
                        id: cover
                        Layout.fillWidth: true
                        Layout.preferredHeight: width
                        Layout.maximumHeight: Math.min(width, 300)
                        color: root.controller.currentAccent
                        radius: Theme.radiusMedium
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            text: root.controller.currentInitials
                            color: "#101311"
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
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: root.controller.currentTitle
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.controller.currentArtist
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            elide: Text.ElideRight
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
                            id: previousButton
                            implicitWidth: 38; implicitHeight: 38
                            enabled: root.controller.canGoPrevious
                            onClicked: root.controller.previousTrack()
                            ToolTip.visible: hovered; ToolTip.text: "上一首"
                            contentItem: Text { text: "|◀"; color: previousButton.enabled ? Theme.textPrimary : Theme.textSecondary; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: previousButton.hovered ? Theme.surfaceHover : Theme.transparent; radius: 19 }
                        }

                        Button {
                            id: playButton
                            implicitWidth: 54; implicitHeight: 54
                            enabled: root.controller.hasCurrentTrack
                            onClicked: root.controller.togglePlayback()
                            ToolTip.visible: hovered
                            ToolTip.text: root.controller.playing ? "暂停" : "播放"
                            contentItem: Text {
                                text: root.controller.loading ? "…" : (root.controller.playing ? "Ⅱ" : "▶")
                                color: "#0c1710"
                                font.family: Theme.fontFamily
                                font.pixelSize: 18
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: playButton.enabled ? (playButton.hovered ? "#72e5a0" : Theme.accent) : Theme.surface
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
                            contentItem: Text { text: "▶|"; color: nextButton.enabled ? Theme.textPrimary : Theme.textSecondary; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: nextButton.hovered ? Theme.surfaceHover : Theme.transparent; radius: 19 }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    RowLayout {
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

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: root.compact ? 250 : 0
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "播放队列"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
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
                        contentItem: Text {
                            text: "×"
                            color: clearQueueButton.enabled ? Theme.textSecondary : Theme.border
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: clearQueueButton.hovered ? Theme.surfaceHover : Theme.transparent
                            radius: Theme.radiusSmall
                        }
                    }
                }

                ListView {
                    id: queueView
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
                        required property bool isCurrent

                        width: queueView.width
                        height: 56
                        color: queueRow.isCurrent ? Theme.accentDark : (queueMouse.containsMouse ? Theme.surfaceHover : Theme.transparent)
                        radius: Theme.radiusMedium

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 12
                            spacing: 12

                            Text {
                                Layout.preferredWidth: 24
                                text: queueRow.isCurrent
                                    ? (root.controller.playing ? "▶" : "Ⅱ")
                                    : queueRow.index + 1
                                color: queueRow.isCurrent ? Theme.accent : Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text { Layout.fillWidth: true; text: queueRow.title; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                Text { Layout.fillWidth: true; text: queueRow.artist; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight }
                            }
                            Text { text: queueRow.duration; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                        }

                        MouseArea {
                            id: queueMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.LeftButton) {
                                    root.controller.playQueueTrack(queueRow.index)
                                    return
                                }
                                root.contextQueueIndex = queueRow.index
                                root.contextQueueCurrent = queueRow.isCurrent
                                queueContextMenu.popup()
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        visible: queueView.count === 0
                        spacing: 7
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "播放队列为空"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 15; font.weight: Font.DemiBold }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "从搜索、收藏或歌单中选择歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                    }
                }
            }
        }
    }

    Menu {
        id: queueContextMenu
        implicitWidth: 190
        modal: true
        palette.window: Theme.surface
        palette.windowText: Theme.textPrimary
        onClosed: {
            root.contextQueueIndex = -1
            root.contextQueueCurrent = false
        }

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium
        }

        ContextMenuItem {
            text: "播放"
            onTriggered: root.controller.playQueueTrack(root.contextQueueIndex)
        }

        ContextMenuItem {
            text: "下一首播放"
            enabled: !root.contextQueueCurrent
            onTriggered: root.controller.playQueueTrackNext(root.contextQueueIndex)
        }

        MenuSeparator {
            contentItem: Rectangle { implicitHeight: 1; color: Theme.border }
        }

        ContextMenuItem {
            text: "从队列移除"
            enabled: !root.contextQueueCurrent
            onTriggered: root.controller.removeQueueTrack(root.contextQueueIndex)
        }
    }
}
