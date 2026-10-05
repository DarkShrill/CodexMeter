import QtQuick

Item {
    id: root
    property real radius: 28
    property color topColor: "#F6FAFF"
    property color bottomColor: "#E7F1FC"
    property color borderColor: "#D7E2EF"
    property real borderWidth: 1
    property real shadowOpacity: 0.16
    default property alias contentData: surface.data

    Rectangle {
        anchors.fill: surface
        anchors.topMargin: 8
        anchors.leftMargin: 3
        anchors.rightMargin: -3
        radius: root.radius
        color: "#243954"
        opacity: root.shadowOpacity
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: root.radius
        border.color: root.borderColor
        border.width: root.borderWidth
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.topColor }
            GradientStop { position: 1.0; color: root.bottomColor }
        }
    }
}
