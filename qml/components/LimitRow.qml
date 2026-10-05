import QtQuick
Rectangle {
    id: root
    property string limitTitle: qsTr("Codex - 5 ore")
    property string resetText: ""
    property int percent: 0
    property color accent: "#0091FF"
    property string symbol: ""
    property bool compact: false
    function usageColor() {
        if (percent < 10) return "#D9534F"
        if (percent < 35) return "#F0A020"
        return accent
    }
    implicitWidth: 320; implicitHeight: 86
    color: "transparent"
    Text { x: 0; y: 10; width: parent.width - 60; text: root.limitTitle; elide: Text.ElideRight; font.family: "Poppins"; font.pixelSize: 15; color: "#252A32" }
    Text { anchors.right: parent.right; y: 10; text: root.percent+"%"; font.family: "Poppins"; font.pixelSize: 15; color: "#252A32" }
    Rectangle {
        y: 37; width: parent.width; height: 7; radius: 3.5; color: "#E1E3E5"
        Rectangle { width: parent.width*Math.max(0,Math.min(100,root.percent))/100; height: parent.height; radius: 3.5; color: root.usageColor() }
    }
    Text { y: 53; width: parent.width; text: root.resetText.length ? qsTr("Reset %1").arg(root.resetText) : qsTr("Reset non disponibile"); elide: Text.ElideRight; color: "#777D85"; font.family: "Poppins"; font.pixelSize: 12 }
}
