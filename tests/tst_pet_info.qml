import QtQuick
import QtTest
import "../qml/components"
import "../qml/previews"

TestCase {
    id: test
    name: "PetInfo"
    width: 700; height: 460
    visible: true
    when: windowShown
    FontLoader { source: "../assets/fonts/Poppins-Regular.ttf" }
    FontLoader { source: "../assets/fonts/Poppins-SemiBold.ttf" }
    PreviewData { id: minimalData }
    PreviewData { id: bubbleData }
    QtObject {
        id: mockActivity
        property string state: "idle"
        property bool working: false
        property int taskCount: 2
        property var activeTasks: [
            {id: "first", title: "Aggiornare la grafica del pet", state: "thinking"},
            {id: "second", title: "Verificare il monitor sulla barra", state: "working"}
        ]
    }
    Rectangle { anchors.fill: parent; color: "#F1F2F3" }
    Text { x: 70; y: 15; text: "Info minimali"; color: "#252A32"; font.family: "Poppins"; font.pixelSize: 16 }
    Text { x: 428; y: 15; text: "Nuvoletta"; color: "#252A32"; font.family: "Poppins"; font.pixelSize: 16 }
    PetView {
        id: minimalPet
        x: 20; y: 54; width: implicitWidth; height: implicitHeight
        settings: minimalData.settings
        rateModel: minimalData.rateModel
    }
    PetView {
        id: bubblePet
        x: 390; y: 104; width: implicitWidth; height: implicitHeight
        settings: bubbleData.settings
        rateModel: bubbleData.rateModel
        activity: mockActivity
    }
    SignalSpy { id: bodySpy; target: bubblePet; signalName: "bodyClicked" }
    SignalSpy { id: settingsSpy; target: bubblePet; signalName: "settingsRequested" }
    function useLocalFrames(item) {
        if (item.resourceRoot !== undefined) item.resourceRoot = Qt.resolvedUrl("../assets/pip/")
        for (let child of item.children || []) useLocalFrames(child)
    }
    function initTestCase() {
        minimalData.settings.petExpression = 5
        bubbleData.settings.petExpression = 5
        bubbleData.settings.petInfoStyle = "bubble"
        minimalData.rateModel.setProperty(0, "remainingPercent", 95)
        bubbleData.rateModel.setProperty(0, "remainingPercent", 95)
        wait(50)
        useLocalFrames(minimalPet)
        useLocalFrames(bubblePet)
    }
    function test_livePercentAndClicks() {
        const label = findChild(bubblePet, "bubblePercent")
        compare(label.text, "95%")
        bubbleData.rateModel.setProperty(0, "remainingPercent", 41)
        tryCompare(label, "text", "41%")
        mouseClick(label, label.width / 2, label.height / 2)
        compare(bodySpy.count, 1)
        mouseClick(label, label.width / 2, label.height / 2, Qt.RightButton)
        compare(settingsSpy.count, 1)
        bubbleData.settings.petInfoStyle = "minimal"
        compare(bubblePet.implicitHeight, 336)
        bubbleData.settings.petInfoStyle = "bubble"
        compare(bubblePet.implicitHeight, 286)
        const first = Object.assign({}, bubbleData.rateModel.get(0))
        bubbleData.rateModel.clear()
        tryCompare(label, "text", "--%")
        bubbleData.rateModel.append(first)
        bubbleData.rateModel.setProperty(0, "remainingPercent", 95)
        tryCompare(label, "text", "95%")
    }
    function test_visualComparison() {
        wait(150)
        grabImage(test).save("C:/QT_WORKSPACE/CodexMeter/build/Debug/pet-info-comparison.png")
    }
    function test_stormAndScale() {
        const bubble = findChild(bubblePet, "petPercentBubble")
        const rain = findChild(bubblePet, "weatherRain0")
        const bolt = findChild(bubblePet, "weatherBolt0")
        verify(bubble !== null && rain !== null && bolt !== null)
        for (let scale of [0.6, 1, 1.8]) {
            bubbleData.settings.petBubbleScale = scale
            compare(bubblePet.implicitHeight, 96 * scale + 190)
            compare(bubblePet.implicitWidth, Math.max(240, 144 * scale) + 60)
            compare(bubble.implicitWidth, 144 * scale)
        }
        bubbleData.settings.petAnimated = true
        for (let state of ["thinking", "working", "review"]) {
            mockActivity.state = state
            compare(bubble.storm, true)
            compare(bubble.weatherRunning, true)
        }
        const previous = rain.fall
        wait(120)
        verify(rain.fall !== previous)
        compare(rain.visible, true)
        compare(bolt.visible, true)
        bubbleData.settings.petAnimated = false
        compare(bubble.weatherRunning, false)
        const stopped = rain.fall
        wait(120)
        compare(rain.fall, stopped)
        bubbleData.settings.petAnimated = true
        bubbleData.settings.petInfoStyle = "minimal"
        compare(bubble.weatherRunning, false)
        bubbleData.settings.petInfoStyle = "bubble"
        bubbleData.settings.petBubbleScale = 1.4
        useLocalFrames(bubblePet)
        wait(200)
        grabImage(test).save("C:/QT_WORKSPACE/CodexMeter/build/Debug/pet-storm-comparison.png")
        for (let state of ["waiting", "completed", "failed", "idle"]) {
            mockActivity.state = state
            compare(bubble.storm, false)
            compare(bubble.weatherRunning, false)
            compare(rain.visible, false)
        }
        bubbleData.settings.petBubbleScale = 1
        bubbleData.settings.petAnimated = false
    }
    function test_rainbowAndTaskList() {
        const bubble = findChild(bubblePet, "petPercentBubble")
        const badge = findChild(bubblePet, "taskStatusBadge")
        const popup = findChild(bubblePet, "activeTasksPopup")
        const label = findChild(bubblePet, "bubblePercent")
        compare(label.font.family, "Poppins")
        compare(bubble.stormDurationMs, 5000)
        bubble.stormDurationMs = 200
        bubbleData.settings.petAnimated = true
        mockActivity.state = "thinking"
        compare(bubble.stormVisible, true)
        tryCompare(bubble, "rainbowVisible", true, 1000)
        compare(bubble.stormVisible, false)
        compare(bubble.weatherRunning, false)
        mockActivity.state = "working"
        compare(bubble.rainbowVisible, true)
        wait(500)
        grabImage(test).save("C:/QT_WORKSPACE/CodexMeter/build/Debug/pet-rainbow-tasks.png")
        verify(badge.x >= bubblePet.petAreaWidth)
        compare(badge.taskCount, 2)
        mouseClick(badge)
        tryCompare(popup, "opened", true)
        const list = findChild(bubblePet, "activeTasksList")
        compare(list.count, 2)
        compare(list.model[0].title, "Aggiornare la grafica del pet")
        wait(100)
        grabImage(popup.contentItem).save("C:/QT_WORKSPACE/CodexMeter/build/Debug/active-task-list.png")
        popup.close()
        mockActivity.taskCount = 0
        mockActivity.activeTasks = []
        mouseClick(badge)
        tryCompare(popup, "opened", true)
        compare(list.count, 0)
        popup.close()
        mockActivity.taskCount = 2
        mockActivity.activeTasks = [{id: "first", title: "Aggiornare la grafica del pet", state: "thinking"}, {id: "second", title: "Verificare il monitor sulla barra", state: "working"}]
        mockActivity.state = "idle"
        compare(bubble.rainbowVisible, false)
        mockActivity.state = "thinking"
        compare(bubble.stormVisible, true)
        mockActivity.state = "idle"
        bubble.stormDurationMs = 5000
        bubbleData.settings.petAnimated = false
    }
}
