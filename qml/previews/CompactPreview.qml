import QtQuick
import "../components"

PreviewFrame {
    id: preview
    title: "QML Preview · CompactView"
    CompactView { anchors.centerIn: parent; rateModel: preview.mock.rateModel }
}
