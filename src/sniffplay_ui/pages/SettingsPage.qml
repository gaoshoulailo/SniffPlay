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
        anchors.fill: parent; anchors.margins: 32; spacing: 18
        Text { text: "设置"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 25; font.bold: true }
        Text { text: "外观与缓存"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
        RowLayout { Layout.fillWidth: true
            Text { text: "背景颜色"; color: Theme.textPrimary; font.pixelSize: 14; Layout.fillWidth: true }
            Rectangle { implicitWidth: 36; implicitHeight: 28; color: root.controller.backgroundColor; border.color: Theme.buttonBorder; radius: Theme.radiusSmall }
            AppButton { text: "选择颜色"; onClicked: colorDialog.open() }
        }
        RowLayout { Layout.fillWidth: true
            Text { text: "背景图片"; color: Theme.textPrimary; font.pixelSize: 14; Layout.fillWidth: true }
            AppButton { text: "选择图片"; onClicked: imageDialog.open() }
            AppButton { text: "清除图片"; danger: true; onClicked: root.controller.setBackgroundColor(root.controller.backgroundColor) }
        }
        RowLayout { Layout.fillWidth: true
            Text { text: "封面缓存"; color: Theme.textPrimary; font.pixelSize: 14; Layout.fillWidth: true }
            AppButton { text: "清空缓存"; danger: true; onClicked: root.controller.clearCoverCache() }
        }
        Item { Layout.fillHeight: true }
    }
    FileDialog { id: imageDialog; title: "选择背景图片"; nameFilters: ["图片 (*.png *.jpg *.jpeg *.bmp *.webp)", "所有文件 (*)"]; onAccepted: root.controller.setBackgroundImage(selectedFile.toString()) }
    Dialog {
        id: colorDialog; title: "选择背景颜色"; width: 340; modal: true; anchors.centerIn: parent
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
            GridLayout { Layout.fillWidth: true; columns: 6; columnSpacing: 8; rowSpacing: 8
                Repeater { model: ["#242428", "#202024", "#1B201D", "#263238", "#302A36", "#17242A", "#3A2525", "#25352B", "#3A321F", "#252C3A", "#33272A", "#1E3030"]
                    delegate: Rectangle { required property string modelData; implicitWidth: 40; implicitHeight: 30; radius: Theme.radiusSmall; color: modelData
                        border.width: colorDialog.selectedColor.toString().toUpperCase() === modelData ? 2 : 1; border.color: colorDialog.selectedColor.toString().toUpperCase() === modelData ? Theme.accent : Theme.buttonBorder
                        MouseArea { anchors.fill: parent; onClicked: { colorDialog.selectedColor = parent.color; hexField.text = parent.color.toString().toUpperCase() } }
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
                background: Rectangle { color: Theme.window; border.color: hexField.activeFocus ? Theme.accent : Theme.buttonBorder; radius: Theme.radiusSmall }
                onTextChanged: if (/^#[0-9A-Fa-f]{6}$/.test(text)) colorDialog.selectedColor = text
            }
        }
        footer: RowLayout {
            implicitHeight: 58
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10
            AppButton { Layout.fillWidth: true; text: "取消"; onClicked: colorDialog.reject() }
            AppButton { Layout.fillWidth: true; text: "确定"; primary: true; onClicked: { root.controller.setBackgroundColor(colorDialog.selectedColor.toString()); colorDialog.accept() } }
        }
        background: Rectangle { color: Theme.surface; border.color: Theme.buttonBorder; radius: Theme.radiusMedium }
    }
}
