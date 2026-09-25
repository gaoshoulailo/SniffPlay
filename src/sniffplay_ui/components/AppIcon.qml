import QtQuick

Item {
    id: root

    property string name: ""
    property color color: "white"
    property int iconSize: 18

    implicitWidth: iconSize
    implicitHeight: iconSize

    function glyph(iconName) {
        const icons = {
            "add": "\uE710",
            "appearance": "\uE790",
            "back": "\uE72B",
            "check": "\uE73E",
            "chevron-right": "\uE76C",
            "close": "\uE8BB",
            "copy": "\uE8C8",
            "delete": "\uE74D",
            "down": "\uE74B",
            "edit": "\uE70F",
            "favorite": "\uE734",
            "favorite-filled": "\uEB52",
            "folder-open": "\uE838",
            "history": "\uE81C",
            "info": "\uE946",
            "library": "\uE8F1",
            "list": "\uE8FD",
            "maximize": "\uE922",
            "minimize": "\uE921",
            "more": "\uE712",
            "music": "\uE8D6",
            "next": "\uE893",
            "pause": "\uE769",
            "play": "\uE768",
            "previous": "\uE892",
            "refresh": "\uE72C",
            "remove": "\uE738",
            "repeat": "\uE8EE",
            "restore": "\uE923",
            "search": "\uE721",
            "settings": "\uE713",
            "shuffle": "\uE8B1",
            "storage": "\uEDA2",
            "up": "\uE74A",
            "volume": "\uE767"
        }
        return icons[iconName] || ""
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph(root.name)
        color: root.color
        font.family: "Segoe Fluent Icons"
        font.pixelSize: root.iconSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
    }
}
