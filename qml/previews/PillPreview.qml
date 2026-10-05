import QtQuick
import "../components"

PreviewFrame {
    id: preview
    title: "QML Preview · PillView"
    PillView { anchors.centerIn: parent; rateModel: preview.mock.rateModel }
}
