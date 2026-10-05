import QtQuick
import "../components"

PreviewFrame {
    title: "QML Preview · RingArc"
    RingArc {
        anchors.centerIn: parent
        width: 220; height: 220
        thickness: 18
        progress: 0.68
        progressColor: "#2479FF"
        trackColor: "#CBD8E7"
    }
}
