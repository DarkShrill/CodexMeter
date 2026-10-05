import QtQuick
import "../components"

PreviewFrame {
    title: "QML Preview · GlassCard"
    GlassCard {
        anchors.centerIn: parent
        width: 520; height: 300
        radius: 34
        Text {
            anchors.centerIn: parent
            text: "GlassCard"
            color: "#10172A"
            font.family: "Poppins"
            font.pixelSize: 30
            font.weight: Font.DemiBold
        }
    }
}
