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

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        anchors.topMargin: 26
        anchors.bottomMargin: 26
        spacing: 14

        Text {
            text: "设置"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 26
            font.weight: Font.Bold
        }

        Text {
            text: "调整界面外观并管理本地存储"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10
            spacing: 9

            AppIcon { name: "appearance"; color: Theme.accent; iconSize: 17 }
            Text {
                text: "外观"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 146
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text { text: "背景颜色"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold }
                        Text { text: "选择窗口的基础背景色"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                    }

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 26
                        color: root.controller.backgroundColor
                        border.color: Theme.buttonBorder
                        radius: Theme.radiusSmall
                    }

                    AppButton {
                        text: "选择颜色"
                        iconName: "appearance"
                        onClicked: colorDialog.open()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    Layout.preferredHeight: 1
                    color: Theme.border
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text { text: "背景图片"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold }
                        Text {
                            text: root.controller.backgroundImage.length > 0 ? "已设置自定义图片" : "当前未设置"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    AppButton {
                        text: "选择图片"
                        iconName: "folder-open"
                        onClicked: imageDialog.open()
                    }
                    AppButton {
                        text: "清除"
                        iconName: "remove"
                        enabled: root.controller.backgroundImage.length > 0
                        onClicked: root.controller.clearBackgroundImage()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 9

            AppIcon { name: "storage"; color: Theme.accent; iconSize: 17 }
            Text {
                text: "存储"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 74
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text { text: "封面缓存"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Text { text: "删除已下载的歌曲封面，下次使用时会重新加载"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                }

                AppButton {
                    text: "清空缓存"
                    iconName: "delete"
                    danger: true
                    onClicked: root.controller.clearCoverCache()
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    FileDialog {
        id: imageDialog
        title: "选择背景图片"
        nameFilters: ["图片 (*.png *.jpg *.jpeg *.bmp *.webp)", "所有文件 (*)"]
        onAccepted: root.controller.setBackgroundImage(selectedFile.toString())
    }

    Dialog {
        id: colorDialog
        title: "选择背景颜色"
        width: 340
        modal: true
        anchors.centerIn: parent
        property color selectedColor: root.controller.backgroundColor
        onOpened: hexField.text = selectedColor.toString().toUpperCase()

        header: Rectangle {
            implicitHeight: 46
            color: Theme.window
            Text {
                anchors.fill: parent
                anchors.leftMargin: 18
                text: colorDialog.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }
        }

        contentItem: ColumnLayout {
            spacing: 14
            Text { text: "主题色板"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
            GridLayout {
                Layout.fillWidth: true
                columns: 6
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: ["#242428", "#202024", "#1B201D", "#263238", "#302A36", "#17242A", "#3A2525", "#25352B", "#3A321F", "#252C3A", "#33272A", "#1E3030"]
                    delegate: Rectangle {
                        required property string modelData
                        implicitWidth: 40
                        implicitHeight: 30
                        radius: Theme.radiusSmall
                        color: modelData
                        border.width: colorDialog.selectedColor.toString().toUpperCase() === modelData ? 2 : 1
                        border.color: colorDialog.selectedColor.toString().toUpperCase() === modelData ? Theme.accent : Theme.buttonBorder
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                colorDialog.selectedColor = parent.color
                                hexField.text = parent.color.toString().toUpperCase()
                            }
                        }
                    }
                }
            }

            TextField {
                id: hexField
                Layout.fillWidth: true
                implicitHeight: 38
                color: Theme.textPrimary
                placeholderText: "例如 #242428"
                placeholderTextColor: Theme.placeholderText
                background: Rectangle {
                    color: Theme.window
                    border.color: hexField.activeFocus ? Theme.accent : Theme.buttonBorder
                    radius: Theme.radiusSmall
                }
                onTextChanged: if (/^#[0-9A-Fa-f]{6}$/.test(text)) colorDialog.selectedColor = text
            }
        }

        footer: RowLayout {
            implicitHeight: 58
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10
            AppButton { Layout.fillWidth: true; text: "取消"; onClicked: colorDialog.reject() }
            AppButton {
                Layout.fillWidth: true
                text: "确定"
                primary: true
                onClicked: {
                    root.controller.setBackgroundColor(colorDialog.selectedColor.toString())
                    colorDialog.accept()
                }
            }
        }

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.buttonBorder
            radius: Theme.radiusMedium
        }
    }
}
