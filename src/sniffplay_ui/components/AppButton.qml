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
        color: control.primary ? Theme.buttonText : Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: control.primary
            ? (control.hovered ? Theme.accentHover : Theme.accent)
            : (control.hovered ? Theme.surfaceHover : Theme.surface)
        border.color: control.primary ? Theme.accent : Theme.border
        border.width: 1
        radius: Theme.radiusMedium
        opacity: control.enabled ? 1 : 0.45
    }
}
