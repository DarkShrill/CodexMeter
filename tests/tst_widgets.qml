import QtQuick
import QtTest
import "../qml/components"
import "../qml"
import "../qml/previews"
TestCase {
    id: test
    name: "WidgetStyles"
    when: windowShown
    visible: true
    width: 1000; height: 700
    FontLoader { source: "../assets/fonts/Poppins-Regular.ttf" }
    FontLoader { source: "../assets/fonts/Poppins-Medium.ttf" }
    FontLoader { source: "../assets/fonts/Poppins-SemiBold.ttf" }
    FontLoader { source: "../assets/fonts/Poppins-Bold.ttf" }
    PreviewData { id: mockData }
    QtObject { id: mockActivity; property bool working: false; signal taskCompleted() }
    Component { id: detailFactory; DetailPanel { rateModel: mockData.rateModel; client: mockData.client } }
    Component { id: cardFactory; UsageCard { rateModel: mockData.rateModel } }
    Component { id: petFactory; PetView { rateModel: mockData.rateModel; settings: mockData.settings; activity: mockActivity; neutralSource: Qt.resolvedUrl("../assets/pet-neutral.png"); happySource: Qt.resolvedUrl("../assets/pet-happy.png") } }
    Component { id: settingsFactory; SettingsWindow { settings: mockData.settings; client: mockData.client; petNeutralSource: Qt.resolvedUrl("../assets/pet-neutral.png"); petSleepySource: Qt.resolvedUrl("../assets/pet-sleepy.png"); petHappySource: Qt.resolvedUrl("../assets/pet-happy.png"); petWinkSource: Qt.resolvedUrl("../assets/pet-wink.png") } }
    function test_cards() {
        for (let style = 0; style < 3; ++style) {
            let card = createTemporaryObject(cardFactory, test, {cardStyle: style, allLimits: true})
            verify(card !== null)
            compare(card.implicitWidth, style === 0 ? 200 : (style === 1 ? 330 : 240))
            wait(80)
            verify(card.height >= 146)
            card.destroy()
            wait(10)
        }
    }
    function test_pet() {
        mockData.settings.petAnimated = true
        for (let style = 0; style < 3; ++style) {
            mockData.settings.cardStyle = style
            let pet = createTemporaryObject(petFactory, test)
            verify(pet !== null)
            mockActivity.working = true
            wait(100)
            mockActivity.working = false
            mockActivity.taskCompleted()
            compare(pet.celebrating, true)
            mockData.settings.petAnimated = false
            compare(pet.celebrating, false)
            mockData.settings.petAnimated = true
            pet.destroy()
            wait(20)
        }
    }
    function test_settings() {
        mockData.settings.viewMode = "compact"
        mockData.settings.viewMode = "compact"
        let settings = createTemporaryObject(settingsFactory, test, {visible: true})
        verify(settings !== null)
        wait(150)
        grabImage(settings.contentItem).save("C:/QT_WORKSPACE/CodexMeter/tests/settings-current.png")
        settings.pageIndex = 1
        wait(80)
        let interval = findChild(settings, "refreshInterval")
        verify(interval !== null)
        let seconds = mockData.settings.refreshSeconds
        mouseClick(interval, interval.width - 16, interval.height / 2)
        compare(mockData.settings.refreshSeconds, seconds + 15)
        grabImage(settings.contentItem).save("C:/QT_WORKSPACE/CodexMeter/tests/settings-refresh.png")
        settings.pageIndex = 2
        wait(80)
        let monitorToggle = findChild(settings, "taskbarMonitorCheckbox")
        verify(monitorToggle !== null)
        mouseClick(monitorToggle)
        compare(mockData.settings.taskbarMonitor, true)
        grabImage(settings.contentItem).save("C:/QT_WORKSPACE/CodexMeter/tests/settings-windows.png")
        mockData.settings.taskbarMonitor = false
        mockData.settings.refreshSeconds = seconds
    }
    function test_updates() {
        let card = createTemporaryObject(cardFactory, test)
        let original = mockData.rateModel.get(0).remainingPercent
        mockData.rateModel.setProperty(0, "remainingPercent", 92)
        tryCompare(card, "revision", 1)
        compare(card.primary.remainingPercent, 92)
        mockData.rateModel.setProperty(0, "remainingPercent", original)
    }
    function test_visual() {
        mockData.settings.petAnimated = false
        let positions = [20, 250, 610]
        for (let style = 0; style < 3; ++style) {
            let card = createTemporaryObject(cardFactory, test, {cardStyle: style, x: positions[style], y: 20})
            verify(card !== null)
        }
        let pet = createTemporaryObject(petFactory, test, {x: 20, y: 210})
        verify(pet !== null)
        let details = createTemporaryObject(detailFactory, test, {x: 280, y: 210, width: 360, height: 410})
        verify(details !== null)
        wait(150)
        grabImage(test).save("C:/QT_WORKSPACE/CodexMeter/tests/widgets-current.png")
    }
}
