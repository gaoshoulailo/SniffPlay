import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../themes"

Menu {
    id: control

    implicitWidth: 220
    topPadding: 6
    bottomPadding: 6
    leftPadding: 6
    rightPadding: 6
    modal: true
    transformOrigin: Item.TopLeft
    palette.window: Theme.surface
    palette.windowText: Theme.textPrimary

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 170; easing.type: Easing.OutCubic }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 90; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1; to: 0.98; duration: 90; easing.type: Easing.InCubic }
        }
    }

    background: Rectangle {
        color: Qt.rgba(0.105, 0.105, 0.12, 0.98)
        border.color: Theme.buttonBorder
        border.width: 1
        radius: Theme.radiusMedium

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.48
            shadowBlur: 0.72
            shadowVerticalOffset: 8
        }
    }
}
