import QtQuick
import QtQuick.Controls
import "../themes"

Button {
    id: control

    property bool primary: false
    property bool danger: false
    property string iconName: ""

    implicitHeight: 38
    leftPadding: 16
    rightPadding: 16

    contentItem: Item {
        implicitWidth: contentRow.implicitWidth
        implicitHeight: contentRow.implicitHeight

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: control.iconName.length > 0 && control.text.length > 0 ? 7 : 0

            AppIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: control.iconName.length > 0
                name: control.iconName
                color: control.primary || control.danger ? Theme.buttonText : Theme.textPrimary
                iconSize: 15
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: control.text
                color: control.primary || control.danger ? Theme.buttonText : Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }
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
