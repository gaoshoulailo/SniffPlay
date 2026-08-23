import QtQuick
import QtQuick.Controls
import "../themes"

MenuItem {
    id: control

    implicitHeight: 38
    leftPadding: 14
    rightPadding: 14

    contentItem: Text {
        text: control.text
        color: control.highlighted ? "#0c1710" : Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        color: control.highlighted ? Theme.accent : Theme.transparent
        radius: Theme.radiusSmall
        opacity: control.enabled ? 1 : 0.45
    }
}
