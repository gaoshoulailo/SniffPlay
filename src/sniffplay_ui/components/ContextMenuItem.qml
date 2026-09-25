import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../themes"

MenuItem {
    id: control

    property string iconName: ""
    property bool danger: false

    implicitHeight: 38
    leftPadding: highlighted ? 15 : 12
    rightPadding: 12

    contentItem: RowLayout {
        spacing: 10
        AppIcon {
            Layout.preferredWidth: 18
            name: control.iconName
            color: control.danger ? Theme.danger : (control.highlighted ? Theme.accent : Theme.textSecondary)
            iconSize: 15
        }

        Text {
            Layout.fillWidth: true
            text: control.text
            color: control.danger ? Theme.danger : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    Behavior on leftPadding {
        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
    }

    background: Rectangle {
        color: control.highlighted ? Theme.surfaceHover : Theme.transparent
        radius: Theme.radiusSmall
        opacity: control.enabled ? 1 : 0.45

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: control.highlighted ? 20 : 0
            radius: 1
            color: control.danger ? Theme.danger : Theme.accent
            opacity: control.highlighted ? 1 : 0
            Behavior on height { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }
    }
}
