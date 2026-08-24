import QtQuick
import QtQuick.Controls
import "../themes"

Button {
    id: control

    property string marker: ""
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
            color: control.selected ? Theme.accent : Theme.surface

            Text {
                anchors.centerIn: parent
                text: control.marker
                color: control.selected ? "#0c1710" : Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
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
