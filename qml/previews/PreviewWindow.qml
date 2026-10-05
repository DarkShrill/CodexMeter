import QtQuick
import QtQuick.Window

Window {
    id: window
    visible: true
    width: 1180
    height: 900
    title: "Codex Meter · " + previewSource.toString().split("/").pop()
    color: "#E8F1FB"

    Loader {
        anchors.centerIn: parent
        source: previewSource
    }
}
