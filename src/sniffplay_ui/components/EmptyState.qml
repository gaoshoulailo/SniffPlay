import QtQuick
import QtQuick.Layouts
import "../themes"

Item {
    id: root

    property string iconName: "music"
    property string title: "暂无内容"
    property string description: ""
    property string actionText: ""
    property string actionIcon: ""
    signal actionTriggered()

    implicitWidth: 320
    implicitHeight: content.implicitHeight

    ColumnLayout {
        id: content
        anchors.centerIn: parent
        width: Math.min(360, root.width)
        spacing: 10

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 54
            Layout.preferredHeight: 54
            color: Theme.surface
            border.color: Theme.border
            radius: 27

            AppIcon {
                anchors.centerIn: parent
                name: root.iconName
                color: Theme.accent
                iconSize: 23
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 2
            text: root.title
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.description
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        AppButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 5
            visible: root.actionText.length > 0
            text: root.actionText
            iconName: root.actionIcon
            primary: true
            onClicked: root.actionTriggered()
        }
    }
}
