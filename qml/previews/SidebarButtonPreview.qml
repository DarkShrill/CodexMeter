import QtQuick
import "../components"

PreviewFrame {
    title: "QML Preview · SidebarButton"
    SidebarButton {
        anchors.centerIn: parent
        width: 310
        text: "Aspetto"
        iconText: "◉"
        selected: true
    }
}
