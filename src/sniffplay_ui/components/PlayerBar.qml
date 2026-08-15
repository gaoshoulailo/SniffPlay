import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../themes"

Rectangle {
    id: root

    required property var controller

    implicitHeight: 106
    color: Theme.sidebar
    border.color: Theme.border
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.topMargin: 7
        anchors.bottomMargin: 10
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            Text {
                Layout.preferredWidth: 38
                text: root.controller.positionText
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 10
                horizontalAlignment: Text.AlignRight
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

            Text {
                Layout.preferredWidth: 38
                text: root.controller.durationText
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: Theme.radiusMedium
                color: root.controller.currentAccent

                Text {
                    anchors.centerIn: parent
                    text: root.controller.currentInitials
                    color: "#101311"
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                    font.bold: true
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 220
                Layout.maximumWidth: 280
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.controller.currentTitle
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.controller.currentArtist
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                id: previousButton
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                enabled: root.controller.canGoPrevious
                onClicked: root.controller.previousTrack()
                ToolTip.visible: hovered
                ToolTip.text: "上一首"
                contentItem: Text {
                    text: "◀|"
                    color: previousButton.enabled ? Theme.textPrimary : "#58605b"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: previousButton.hovered ? Theme.surfaceHover : Theme.transparent
                    radius: 17
                }
            }

            Button {
                id: playButton
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                enabled: root.controller.hasCurrentTrack
                onClicked: root.controller.togglePlayback()
                ToolTip.visible: hovered
                ToolTip.text: root.controller.playing ? "暂停" : "播放"

                contentItem: Text {
                    text: root.controller.loading ? "…" : (root.controller.playing ? "Ⅱ" : "▶")
                    color: playButton.enabled ? "#0c1710" : "#58605b"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: playButton.enabled
                        ? (playButton.hovered ? "#72e5a0" : Theme.accent)
                        : Theme.surface
                    radius: 21
                }
            }

            Button {
                id: nextButton
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                enabled: root.controller.canGoNext
                onClicked: root.controller.nextTrack()
                ToolTip.visible: hovered
                ToolTip.text: "下一首"
                contentItem: Text {
                    text: "|▶"
                    color: nextButton.enabled ? Theme.textPrimary : "#58605b"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: nextButton.hovered ? Theme.surfaceHover : Theme.transparent
                    radius: 17
                }
            }

            Item { Layout.fillWidth: true }

            ColumnLayout {
                Layout.preferredWidth: 175
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: root.controller.statusMessage
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.controller.queueLabel
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignRight
                }
            }

            Text {
                text: "VOL"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 9
            }

            Slider {
                id: volumeSlider
                Layout.preferredWidth: 92
                Layout.preferredHeight: 22
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
