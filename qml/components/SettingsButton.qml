import QtQuick
import QtQuick.Controls

Button {
    id: root
    property bool primary: false
    implicitHeight: 38
    implicitWidth: Math.max(92, contentItem.implicitWidth + 32)
    leftPadding: 16
    rightPadding: 16
    hoverEnabled: true
    font.family: "Poppins"
    font.pixelSize: 13
    font.weight: primary ? Font.DemiBold : Font.Normal
    contentItem: Text {
        text: root.text
        font: root.font
        color: !root.enabled ? "#A8ADB3" : root.primary ? "white" : "#3D454D"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: 7
        color: !root.enabled ? "#ECEDEF"
            : root.primary ? (root.down ? "#0078D4" : root.hovered ? "#0086EB" : "#0091FF")
            : root.down ? "#E5E8EA" : root.hovered ? "#F1F3F4" : "#FAFAFB"
        border.color: root.visualFocus ? "#0091FF" : root.primary && root.enabled ? color : "#D9DCDF"
        border.width: root.visualFocus ? 2 : 1
    }
}
