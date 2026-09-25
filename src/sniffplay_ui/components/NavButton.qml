import QtQuick
import QtQuick.Controls
import "../themes"

Button {
    id: control

    property string iconName: ""
    property bool selected: false
    property real contentOffset: hovered && !selected ? 3 : 0

    implicitHeight: 42
    leftPadding: 13
    rightPadding: 13

    contentItem: Row {
        spacing: 12
        transform: Translate { x: control.contentOffset }

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
        radius: Theme.radiusMedium

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: control.selected
                    ? Qt.rgba(0.04, 0.52, 1.0, 0.24)
                    : (control.hovered ? Theme.surfaceHover : Theme.transparent)
            }
            GradientStop {
                position: 1
                color: control.selected
                    ? Qt.rgba(0.12, 0.25, 0.38, 0.72)
                    : (control.hovered ? Qt.rgba(0.12, 0.12, 0.14, 0.24) : Theme.transparent)
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: control.selected ? 22 : 0
            color: Theme.accent
            radius: 2
            opacity: control.selected ? 1 : 0

            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 130 } }
        }
    }

    Behavior on contentOffset {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
}
