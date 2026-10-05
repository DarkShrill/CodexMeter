import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: window
    visible: true
    width: 1180
    height: 900
    title: "Codex Meter · QML previews"
    color: "#E8F1FB"

    readonly property var previews: [
        { label: "components / CompactView", path: "CompactPreview.qml" },
        { label: "components / DetailPanel", path: "DetailsPreview.qml" },
        { label: "components / GlassCard", path: "GlassCardPreview.qml" },
        { label: "components / IndicatorSlider", path: "IndicatorSliderPreview.qml" },
        { label: "components / LimitRow", path: "LimitRowPreview.qml" },
        { label: "components / MiniRing", path: "MiniRingPreview.qml" },
        { label: "components / PetView", path: "PetPreview.qml" },
        { label: "components / PillView", path: "PillPreview.qml" },
        { label: "components / RingArc", path: "RingPreview.qml" },
        { label: "components / SectionCard", path: "SectionCardPreview.qml" },
        { label: "components / SidebarButton", path: "SidebarButtonPreview.qml" },
        { label: "components / TaskStatusBadge", path: "TaskStatusBadgePreview.qml" },
        { label: "components / ToggleSwitch", path: "TogglePreview.qml" },
        { label: "windows / SettingsWindow", path: "SettingsPreview.qml" }
    ]

    ComboBox {
        id: choice
        x: 20
        y: 16
        width: window.width - 40
        model: window.previews
        textRole: "label"
    }

    Loader {
        id: preview
        anchors.horizontalCenter: parent.horizontalCenter
        y: 80
        source: window.previews[choice.currentIndex].path
    }
}
