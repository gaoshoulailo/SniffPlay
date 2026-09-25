import QtQuick
import QtQuick.Controls
import "../themes"

Button {
    id: control

    property string iconName: ""
    property bool selected: false

    implicitHeight: 42
    leftPadding: 13
    rightPadding: 13

    contentItem: Row {
        spacing: 12

        Rectangle {
            width: 24
            height: 24
            radius: 6
            color: control.selected ? Theme.accentDark : Theme.surface

            AppIcon {
                anchors.centerIn: parent
                name: control.iconName
                color: control.selected ? Theme.accent : Theme.textSecondary
                iconSize: 14
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: control.text
            color: control.selected ? Theme.textPrimary : Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: control.selected ? Font.DemiBold : Font.Normal
        }
    }

    background: Rectangle {
        color: control.selected
            ? Theme.accentDark
            : (control.hovered ? Theme.surface : Theme.transparent)
        radius: Theme.radiusMedium
    }
}
