import QtQuick
import "../components"

PreviewFrame {
    title: "QML Preview · SectionCard"
    SectionCard {
        anchors.centerIn: parent
        width: 650; height: 270
        title: "Aspetto"
        iconText: "◉"
        Column {
            anchors.fill: parent
            spacing: 18
            Text { text: "Contenuto della sezione"; color: "#172033"; font.family: "Poppins"; font.pixelSize: 17 }
            IndicatorSlider { width: parent.width; from: 0; to: 100; value: 64 }
            ToggleSwitch { checked: true }
        }
    }
}
