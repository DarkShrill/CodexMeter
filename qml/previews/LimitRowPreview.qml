import QtQuick
import "../components"

PreviewFrame {
    title: "QML Preview · LimitRow"
    LimitRow {
        anchors.centerIn: parent
        width: 590
        limitTitle: "Codex · 5h"
        resetText: "30/09/2026 18:12"
        percent: 24
        accent: "#19B989"
        symbol: "◯"
    }
}
