import QtQuick
import QtQuick.Controls
import "../themes"

Button {
    id: control

    property bool primary: false
    property bool danger: false

    implicitHeight: 38
    leftPadding: 16
    rightPadding: 16

    contentItem: Text {
        text: control.text
        color: control.primary || control.danger ? Theme.buttonText : Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: !control.enabled
            ? Theme.buttonPressed
            : control.primary
                ? (control.down ? Theme.accentDark : (control.hovered ? Theme.accentHover : Theme.accent))
                : control.danger
                    ? (control.down ? Theme.danger : (control.hovered ? "#ed7d84" : "#b94f59"))
                    : (control.down ? Theme.buttonPressed : (control.hovered ? Theme.buttonHover : Theme.buttonSurface))
        border.color: control.primary ? Theme.accent : (control.danger ? Theme.danger : Theme.buttonBorder)
        border.width: 1
        radius: Theme.radiusMedium
        opacity: control.enabled ? 1 : 0.55
    }
}
