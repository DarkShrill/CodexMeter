import QtQuick
import QtQuick.Layouts
Item {
    id: root
    property string title: ""
    property bool divider: true
    default property alias controls: content.data
    implicitHeight: 68
    Text { width: 196; anchors.verticalCenter: parent.verticalCenter; text: root.title; color: "#252A32"; font.family: "Poppins"; font.pixelSize: 14; wrapMode: Text.WordWrap }
    RowLayout { id: content; x: 208; width: parent.width - x; anchors.verticalCenter: parent.verticalCenter; spacing: 12 }
    Rectangle { visible: root.divider; anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#E1E3E6" }
}
