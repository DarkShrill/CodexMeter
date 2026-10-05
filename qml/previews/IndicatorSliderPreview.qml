import QtQuick
import "../components"

PreviewFrame {
    title: "QML Preview · IndicatorSlider"
    IndicatorSlider {
        anchors.centerIn: parent
        width: 520
        from: 0; to: 100; value: 64
    }
}
