import QtQuick
import "../components"

PreviewFrame {
    id: preview
    title: "QML Preview · DetailPanel"
    DetailPanel {
        anchors.centerIn: parent
        rateModel: preview.mock.rateModel
        client: preview.mock.client
    }
}
