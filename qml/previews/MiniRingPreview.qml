import QtQuick
import "../components"

PreviewFrame {
    title: "QML Preview · MiniRing"
    MiniRing {
        anchors.centerIn: parent
        width: 180; height: 150
        ringSize: 126
        percent: 45
        accent: "#315DEB"
        subtitle: "Codex · Week"
    }
}
