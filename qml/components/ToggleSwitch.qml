import QtQuick

Item {
    id: root
    property bool checked: false
    signal toggled(bool checked)
    implicitWidth: 46
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? "#51565D" : "#B9BDC3"
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    Rectangle {
        width: 20
        height: 20
        radius: 10
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: "white"
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
