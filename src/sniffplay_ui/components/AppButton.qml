import QtQuick
import QtQuick.Controls
import "../themes"

Button {
    id: control

    property bool primary: false

    implicitHeight: 38
    leftPadding: 16
    rightPadding: 16

    contentItem: Text {
        text: control.text
        color: control.primary ? "#0c1710" : Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: control.primary
            ? (control.hovered ? "#72e5a0" : Theme.accent)
            : (control.hovered ? Theme.surfaceHover : Theme.surface)
        border.color: control.primary ? Theme.accent : Theme.border
        border.width: 1
        radius: Theme.radiusMedium
        opacity: control.enabled ? 1 : 0.45
    }
}

