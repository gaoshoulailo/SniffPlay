import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import "../themes"

Item {
    id: root
    required property var controller

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 18
        Text { text: "设置"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 25; font.bold: true }
        Text { text: "外观与缓存"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "背景颜色"; color: Theme.textPrimary; font.pixelSize: 14; Layout.fillWidth: true }
            Rectangle { implicitWidth: 36; implicitHeight: 28; color: root.controller.backgroundColor; border.color: Theme.border; radius: 4 }
            Button { text: "选择颜色"; onClicked: colorDialog.open() }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "背景图片"; color: Theme.textPrimary; font.pixelSize: 14; Layout.fillWidth: true }
            Button { text: "选择图片"; onClicked: imageDialog.open() }
            Button { text: "清除图片"; onClicked: root.controller.setBackgroundColor(root.controller.backgroundColor) }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "封面缓存"; color: Theme.textPrimary; font.pixelSize: 14; Layout.fillWidth: true }
            Button { text: "清空缓存"; onClicked: root.controller.clearCoverCache() }
        }
        Item { Layout.fillHeight: true }
    }

    FileDialog {
        id: imageDialog
        title: "选择背景图片"
        nameFilters: ["图片 (*.png *.jpg *.jpeg *.bmp *.webp)", "所有文件 (*)"]
        onAccepted: root.controller.setBackgroundImage(selectedFile.toString())
    }

    ColorDialog {
        id: colorDialog
        title: "选择背景颜色"
        selectedColor: root.controller.backgroundColor
        onAccepted: root.controller.setBackgroundColor(selectedColor.toString())
    }
}
