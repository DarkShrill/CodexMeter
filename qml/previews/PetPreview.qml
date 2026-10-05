import QtQuick
import "../components"

PreviewFrame {
    id: preview
    title: "QML Preview · PetView"
    PetView {
        anchors.centerIn: parent
        rateModel: preview.mock.rateModel
        settings: preview.mock.settings
    }
}
