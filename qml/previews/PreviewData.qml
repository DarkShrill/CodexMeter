import QtQuick

Item {
    id: root
    visible: false

    property alias rateModel: limits
    property alias settings: settingsMock
    property alias client: clientMock

    ListModel {
        id: limits
        ListElement { limitName: "Codex"; limitId: "codex"; bucket: "5h"; remainingPercent: 24; resetText: "30/09/2026 18:12" }
        ListElement { limitName: "Codex"; limitId: "codex"; bucket: "Week"; remainingPercent: 45; resetText: "05/10/2026 08:50" }
        ListElement { limitName: "gpt-reserve"; limitId: "gpt-reserve"; bucket: "Week"; remainingPercent: 100; resetText: "07/10/2026 14:03" }
        property string planType: "plus"
    }

    QtObject {
        id: settingsMock
        property string viewMode: "pet"
        property int petExpression: 0
        property string petInfoStyle: "minimal"
        property real petBubbleScale: 1.0
        property var petLayout: ({})
        function setPetLayoutOffset(element, x, y) {
            const next = Object.assign({}, petLayout)
            next[element] = {x: x, y: y}
            petLayout = next
        }
        function resetPetLayout() { petLayout = ({}) }
        property int cardStyle: 1
        property bool petAnimated: false
        property bool launchAtStartup: false
        property bool taskbarMonitor: false
        property bool alwaysOnTop: true
        property int refreshSeconds: 60
        property real scale: 0.85
        property real widgetOpacity: 1.0
        function clearPosition() {}
    }

    QtObject {
        id: clientMock
        property string status: "Aggiornato"
        property string lastError: ""
        property var lastUpdated: new Date(2026, 8, 30, 14, 3, 40)
        function refresh() {}
    }
}
