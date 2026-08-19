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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 18

        Text {
            text: "搜索"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 26
            font.weight: Font.Bold
        }

        Text {
            text: "在已启用的音乐来源中查找歌曲、歌手或专辑"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            TextField {
                id: searchField
                Layout.fillWidth: true
                Layout.maximumWidth: 680
                implicitHeight: 42
                leftPadding: 14
                rightPadding: 14
                placeholderText: "输入歌曲、歌手或专辑"
                placeholderTextColor: "#6f7a73"
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
                text: "打开音频"
                onClicked: localFileDialog.open()
            }

            AppButton {
                text: root.controller.searching ? "搜索中" : "搜索"
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
            implicitHeight: 34
            color: Theme.transparent

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 58
                anchors.rightMargin: 18
                spacing: 14

                Text { Layout.fillWidth: true; text: "歌曲"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Text { Layout.preferredWidth: 180; text: "专辑"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Text { Layout.preferredWidth: 72; text: "来源"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Text { Layout.preferredWidth: 52; text: "时长"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Item { Layout.preferredWidth: 114 }
            }
        }

        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
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
                height: 58
                color: rowMouse.containsMouse ? Theme.surfaceHover : Theme.transparent
                radius: Theme.radiusMedium

                RowLayout {
                    z: 1
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 18
                    spacing: 14

                    Rectangle {
                        id: coverContainer
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        color: trackRow.accent
                        radius: Theme.radiusSmall
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            text: trackRow.initials
                            color: "#101311"
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.bold: true
                            visible: coverImage.status !== Image.Ready
                        }

                        Image {
                            id: coverImage
                            anchors.fill: parent
                            source: trackRow.coverUrl
                            asynchronous: false
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text { Layout.fillWidth: true; text: trackRow.title; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: trackRow.artist; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; elide: Text.ElideRight }
                    }

                    Text { Layout.preferredWidth: 180; text: trackRow.album; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; elide: Text.ElideRight }
                    Text { Layout.preferredWidth: 72; text: trackRow.source; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.DemiBold }
                    Text { Layout.preferredWidth: 52; text: trackRow.duration; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }

                    Button {
                        id: favoriteButton
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        onClicked: root.controller.toggleTrackFavorite(trackRow.index)
                        ToolTip.visible: hovered
                        ToolTip.text: trackRow.isFavorite ? "取消收藏" : "收藏"

                        contentItem: Text {
                            text: trackRow.isFavorite ? "♥" : "♡"
                            color: trackRow.isFavorite ? Theme.danger : Theme.textSecondary
                            font.pixelSize: 19
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
                        onClicked: root.controller.playTrack(trackRow.index)
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
                    acceptedButtons: Qt.LeftButton
                    z: 0
                    onDoubleClicked: root.controller.playTrack(trackRow.index)
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
        palette.buttonText: Theme.textPrimary

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
                        color: "#ffffff"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: "#000000"
                        border.color: cancelAddButton.hovered ? "#ffffff" : Theme.border
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
                        color: "#ffffff"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: "#000000"
                        border.color: confirmAddButton.enabled && confirmAddButton.hovered
                            ? "#ffffff"
                            : Theme.border
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
        palette.buttonText: Theme.textPrimary

        contentItem: TextField {
            id: newPlaylistName
            implicitHeight: 40
            color: Theme.textPrimary
            placeholderText: "歌单名称"
            placeholderTextColor: "#6f7a73"
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
