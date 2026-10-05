import QtQuick

Item {
    id: root
    property int percent: 0
    property color accent: "#2479FF"
    property color textColor: "#0B1020"
    property string subtitle: ""
    property int ringSize: 88

    RingArc {
        width: root.ringSize
        height: root.ringSize
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        thickness: 9
        progress: root.percent / 100
        progressColor: root.accent
        trackColor: "#D7E0EA"
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.ringSize / 2 - 17
        text: root.percent + "%"
        color: root.textColor
        font.family: "Poppins"
        font.pixelSize: 25
        font.weight: Font.DemiBold
    }

    Text {
        visible: root.subtitle.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.ringSize + 8
        text: root.subtitle
        color: "#516078"
        font.family: "Poppins"
        font.pixelSize: 13
    }
}
