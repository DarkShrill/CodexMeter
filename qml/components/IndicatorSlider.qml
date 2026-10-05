import QtQuick
import QtQuick.Controls
Slider {
    id: root
    implicitHeight: 32
    background: Rectangle {
        x: root.leftPadding; y: root.topPadding + root.availableHeight/2-height/2
        width: root.availableWidth; height: 6; radius: 3; color: "#E2E4E8"
        Rectangle { width: parent.width*root.visualPosition; height: parent.height; radius: 3; color: "#2878F0" }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition*(root.availableWidth-width)
        y: root.topPadding + root.availableHeight/2-height/2
        width: 18; height: 18; radius: 9
        color: root.pressed ? "#1765D4" : "#2878F0"
        border.width: root.activeFocus ? 2 : 0; border.color: "#A6C9FF"
    }
}
