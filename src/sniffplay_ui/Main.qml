pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
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
    color: Theme.window
    flags: Qt.Window | Qt.FramelessWindowHint

    required property var controller
    property int currentPage: 0

    Rectangle {
        id: titleBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 44
        color: Theme.sidebar
        border.color: Theme.border

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
                model: ["−", "□", "×"]

                delegate: Button {
                    id: windowButton
                    required property string modelData
                    required property int index
                    width: 46
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
                    ToolTip.text: index === 0 ? "最小化" : (index === 1 ? "最大化" : "关闭")

                    contentItem: Text {
                        text: windowButton.modelData
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
                    }
                }
            }
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: titleBar.bottom
        anchors.bottom: parent.bottom
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 214
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
                    text: "搜索"
                    marker: "S"
                    selected: root.currentPage === 0
                    onClicked: root.currentPage = 0
                }

                NavButton {
                    Layout.fillWidth: true
                    text: "我的歌单"
                    marker: "P"
                    selected: root.currentPage === 1
                    onClicked: root.currentPage = 1
                }

                NavButton {
                    Layout.fillWidth: true
                    text: "播放历史"
                    marker: "H"
                    selected: root.currentPage === 2
                    onClicked: root.currentPage = 2
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

                SearchPage { controller: root.controller }
                PlaylistPage { controller: root.controller }
                HistoryPage { controller: root.controller }
            }

            PlayerBar {
                Layout.fillWidth: true
                controller: root.controller
            }
        }
    }

    MouseArea {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 12
        height: 12
        cursorShape: Qt.SizeFDiagCursor
        onPressed: root.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
    }
}
