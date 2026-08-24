pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "components"
import "pages"
import "themes"

ApplicationWindow {
    id: root

    width: 1180
    height: 760
    minimumWidth: 920
    minimumHeight: 620
    visible: true
    title: "SniffPlay"
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    required property var controller
    property int currentPage: 0
    readonly property int frameMargin: visibility === Window.Maximized ? 0 : 8

    Rectangle {
        id: windowFrame
        anchors.fill: parent
        anchors.margins: root.frameMargin
        color: Theme.window
        border.color: Theme.border
        border.width: 1
        radius: root.visibility === Window.Maximized ? 0 : 12
    }

    MultiEffect {
        anchors.fill: windowFrame
        source: windowFrame
        visible: root.visibility !== Window.Maximized
        shadowEnabled: true
        shadowColor: "#99000000"
        shadowBlur: 1
        shadowVerticalOffset: 4
        autoPaddingEnabled: true
    }

    Rectangle {
        id: titleBar
        anchors.left: windowFrame.left
        anchors.right: windowFrame.right
        anchors.top: windowFrame.top
        height: 42
        color: Theme.sidebar
        border.color: Theme.border
        radius: root.visibility === Window.Maximized ? 0 : 12

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: root.startSystemMove()
            onDoubleClicked: root.visibility === Window.Maximized
                ? root.showNormal()
                : root.showMaximized()
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Rectangle {
                width: 24
                height: 24
                radius: 6
                color: Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: "S"
                    color: "#0c1710"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "SniffPlay"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }

        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height

            Repeater {
                model: ["—", "□", "×"]

                delegate: Button {
                    id: windowButton
                    required property string modelData
                    required property int index
                    width: 44
                    height: titleBar.height
                    onClicked: {
                        if (index === 0)
                            root.showMinimized()
                        else if (index === 1)
                            root.visibility === Window.Maximized ? root.showNormal() : root.showMaximized()
                        else
                            root.close()
                    }

                    ToolTip.visible: hovered
                    ToolTip.text: index === 0
                        ? "最小化"
                        : (index === 1
                            ? (root.visibility === Window.Maximized ? "还原" : "最大化")
                            : "关闭")

                    contentItem: Text {
                        text: windowButton.index === 1 && root.visibility === Window.Maximized
                            ? "❐"
                            : windowButton.modelData
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: windowButton.hovered
                            ? (windowButton.index === 2 ? Theme.danger : Theme.surfaceHover)
                            : Theme.transparent
                        radius: windowButton.index === 2 && root.visibility !== Window.Maximized ? 12 : 0
                    }
                }
            }
        }
    }

    RowLayout {
        anchors.left: windowFrame.left
        anchors.right: windowFrame.right
        anchors.top: titleBar.bottom
        anchors.bottom: windowFrame.bottom
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 204
            Layout.fillHeight: true
            color: Theme.sidebar
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 5

                Text {
                    Layout.leftMargin: 10
                    Layout.topMargin: 12
                    Layout.bottomMargin: 8
                    text: "音乐库"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                NavButton {
                    Layout.fillWidth: true
                    text: "正在播放"
                    marker: "▶"
                    selected: root.currentPage === 0
                    onClicked: root.currentPage = 0
                }

                NavButton {
                    Layout.fillWidth: true
                    text: "搜索"
                    marker: "⌕"
                    selected: root.currentPage === 1
                    onClicked: root.currentPage = 1
                }

                NavButton {
                    Layout.fillWidth: true
                    text: "我的收藏"
                    marker: "♥"
                    selected: root.currentPage === 2
                    onClicked: root.currentPage = 2
                }

                NavButton {
                    Layout.fillWidth: true
                    text: "我的歌单"
                    marker: "≡"
                    selected: root.currentPage === 3
                    onClicked: root.currentPage = 3
                }

                NavButton {
                    Layout.fillWidth: true
                    text: "播放历史"
                    marker: "↶"
                    selected: root.currentPage === 4
                    onClicked: root.currentPage = 4
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58
                    color: Theme.surface
                    border.color: Theme.border
                    radius: Theme.radiusMedium

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text { text: "Bilibili 数据源"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.DemiBold }
                        Text { text: "模拟搜索数据"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7
                        height: 7
                        radius: 4
                        color: Theme.accent
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentPage

                NowPlayingPage { controller: root.controller }
                SearchPage { controller: root.controller }
                FavoritesPage { controller: root.controller }
                PlaylistPage { controller: root.controller }
                HistoryPage { controller: root.controller }
            }

            PlayerBar {
                Layout.fillWidth: true
                visible: root.currentPage !== 0
                controller: root.controller
            }
        }
    }

    MouseArea { enabled: root.visibility !== Window.Maximized; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 5; cursorShape: Qt.SizeHorCursor; onPressed: root.startSystemResize(Qt.LeftEdge) }
    MouseArea { enabled: root.visibility !== Window.Maximized; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 5; cursorShape: Qt.SizeHorCursor; onPressed: root.startSystemResize(Qt.RightEdge) }
    MouseArea { enabled: root.visibility !== Window.Maximized; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 5; cursorShape: Qt.SizeVerCursor; onPressed: root.startSystemResize(Qt.TopEdge) }
    MouseArea { enabled: root.visibility !== Window.Maximized; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 5; cursorShape: Qt.SizeVerCursor; onPressed: root.startSystemResize(Qt.BottomEdge) }
    MouseArea { enabled: root.visibility !== Window.Maximized; anchors.left: parent.left; anchors.top: parent.top; width: 12; height: 12; cursorShape: Qt.SizeFDiagCursor; onPressed: root.startSystemResize(Qt.LeftEdge | Qt.TopEdge) }
    MouseArea { enabled: root.visibility !== Window.Maximized; anchors.right: parent.right; anchors.top: parent.top; width: 12; height: 12; cursorShape: Qt.SizeBDiagCursor; onPressed: root.startSystemResize(Qt.RightEdge | Qt.TopEdge) }
    MouseArea { enabled: root.visibility !== Window.Maximized; anchors.left: parent.left; anchors.bottom: parent.bottom; width: 12; height: 12; cursorShape: Qt.SizeBDiagCursor; onPressed: root.startSystemResize(Qt.LeftEdge | Qt.BottomEdge) }
    MouseArea { enabled: root.visibility !== Window.Maximized; anchors.right: parent.right; anchors.bottom: parent.bottom; width: 12; height: 12; cursorShape: Qt.SizeFDiagCursor; onPressed: root.startSystemResize(Qt.RightEdge | Qt.BottomEdge) }
}
