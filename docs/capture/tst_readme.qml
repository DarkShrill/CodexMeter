import QtQuick
import QtTest
import "../../qml"
import "../../qml/components"
import "../../qml/previews"

// Render the current production components; only account/session data is mocked.
TestCase {
    id: capture
    name: "ReadmeScreenshots"
    when: windowShown
    visible: true
    width: 1000
    height: 940
    PreviewData { id: data }
    QtObject {
        id: demoActivity
        property bool working: false
        property string state: "idle"
        property int taskCount: 2
        property var activeTasks: [
            {id: "demo-a", title: "Aggiornare il README", state: "thinking"},
            {id: "demo-b", title: "Verificare il widget", state: "working"}
        ]
    }
    Rectangle {
        id: overview
        anchors.fill: parent
        color: "#F1F2F3"
        Text { x: 40; y: 28; text: "Codex Meter"; font.family: "Poppins"; font.pixelSize: 28; font.weight: Font.DemiBold; color: "#252A32" }
        Text { x: 40; y: 74; text: "Quote residue. Il widget che scegli tu."; font.family: "Poppins"; font.pixelSize: 16; color: "#717780" }
        Text { x: 40; y: 124; text: "MINI"; font.family: "Poppins"; font.pixelSize: 12; color: "#717780" }
        CompactView { id: mini; x: 40; y: 151; width: implicitWidth; height: implicitHeight; rateModel: data.rateModel; settings: null; cardStyle: 0 }
        Text { x: 290; y: 124; text: "ANELLO"; font.family: "Poppins"; font.pixelSize: 12; color: "#717780" }
        CompactView { id: ring; x: 290; y: 151; width: implicitWidth; height: implicitHeight; rateModel: data.rateModel; settings: null; cardStyle: 1 }
        Text { x: 670; y: 124; text: "MONITOR · 3 LIMITI"; font.family: "Poppins"; font.pixelSize: 12; color: "#717780" }
        PillView { id: monitor; x: 670; y: 151; width: implicitWidth; height: implicitHeight; rateModel: data.rateModel; settings: null; cardStyle: 2 }
        Text { x: 80; y: 459; text: "PET · NUVOLETTA E TASK ATTIVI"; font.family: "Poppins"; font.pixelSize: 12; color: "#717780" }
        PetView { id: pet; x: 55; y: 500; width: implicitWidth; height: implicitHeight; rateModel: data.rateModel; settings: data.settings; activity: demoActivity }
        DetailPanel { id: details; x: 475; y: 485; width: implicitWidth; height: implicitHeight; rateModel: data.rateModel; client: data.client; pointerSide: "none" }
        Text { x: 40; y: 909; text: "Anteprima dei componenti attuali · dati dimostrativi"; font.family: "Poppins"; font.pixelSize: 11; color: "#717780" }
    }
    SettingsWindow {
        id: settingsWindow
        settings: data.settings
        client: data.client
        rateModel: data.rateModel
    }
    function initTestCase() {
        data.settings.viewMode = "pet"
        data.settings.petInfoStyle = "bubble"
        data.settings.petAnimated = false
        data.settings.petExpression = 1
        data.settings.refreshSeconds = 60
        data.settings.launchAtStartup = true
        data.settings.taskbarMonitor = true
        data.client.lastUpdated = new Date(2026, 9, 2, 12, 30)
        for (let i = 0; i < data.rateModel.count; ++i) {
            data.rateModel.setProperty(i, "resetTimestamp", Math.floor(Date.now() / 1000) + [7200, 172800, 259200][i])
            data.rateModel.setProperty(i, "resetText", ["02/10/2026 14:30", "04/10/2026 12:30", "05/10/2026 12:30"][i])
        }
        wait(400)
    }
    function save(item, name) {
        wait(200)
        const screenshot = grabImage(item)
        verify(screenshot.width > 0 && screenshot.height > 0)
        screenshot.save(Qt.resolvedUrl("../images/" + name).toString().replace("file:///", ""))
    }
    function test_capture() {
        verify(mini.x + mini.width < ring.x)
        verify(ring.x + ring.width < monitor.x)
        verify(monitor.y + monitor.height < details.y)
        save(overview, "widget-overview.png")
        settingsWindow.pageIndex = 1
        settingsWindow.show()
        wait(200)
        compare(findChild(settingsWindow, "refreshInterval").value, 60)
        save(settingsWindow.contentItem, "settings-refresh.png")
        settingsWindow.pageIndex = 2
        wait(200)
        compare(findChild(settingsWindow, "taskbarMonitorCheckbox").checked, true)
        save(settingsWindow.contentItem, "settings-windows.png")
        settingsWindow.close()
    }
}
