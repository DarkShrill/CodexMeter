import QtQuick
Rectangle {
    id: root
    property string text: ""
    property string iconText: ""
    property string iconName: "settings"
    property bool selected: false
    signal clicked()
    height: 46; radius: 7
    color: selected ? "#E0E1E3" : (mouse.containsMouse ? "#E9EAEC" : "transparent")
    LineIcon { x: 15; anchors.verticalCenter: parent.verticalCenter; name: root.iconName; width: 21; height: 21; stroke: "#454B54" }
    Text { x: 49; anchors.verticalCenter: parent.verticalCenter; text: root.text; font.family: "Poppins"; font.pixelSize: 14; color: "#292F38" }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
}
