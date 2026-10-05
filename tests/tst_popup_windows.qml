import QtQuick
import QtTest
import "../qml"
import "../qml/previews"

TestCase {
    id: test
    name: "PopupWindows"
    width: 1200; height: 800
    visible: true; when: windowShown
    PreviewData { id: data }
    QtObject {
        id: appSettings
        property string viewMode: "pet"
        property int cardStyle: 1
        property real scale: 0.85
        property real widgetOpacity: 1
        property bool alwaysOnTop: false
        property int petExpression: 5
        property bool petAnimated: false
        property string petInfoStyle: "bubble"
        property real petBubbleScale: 1
        property var petLayout: ({})
        property bool hasSavedPosition: true
        property bool launchAtStartup: false
        property bool taskbarMonitor: false
        property int refreshSeconds: 60
        function initialWindowPosition(w, h) { return {x: 900, y: 500} }
        function defaultWindowPosition(w, h) { return initialWindowPosition(w, h) }
        function availableScreenGeometry(x, y) { return {x: 0, y: 0, width: 1200, height: 800} }
        function savePosition(x, y) {}
        function setPetLayoutOffset(element, x, y) {
            const next = Object.assign({}, petLayout)
            next[element] = {x: x, y: y}
            petLayout = next
        }
    }
    property var rateLimitModel: data.rateModel
    property var codexClient: data.client
    QtObject {
        id: trayController
        property bool quitting: true
        signal showRequested()
        signal settingsRequested()
        signal hideRequested()
        function setWidgetVisible(v) {}
    }
    QtObject {
        id: taskActivity
        property string state: "idle"
        property bool working: false
        property int taskCount: 1
        property var activeTasks: [{title: "Test", state: "working"}]
        signal taskCompleted()
    }
    QtObject {
        id: petLibrary
        property var customPets: []
        signal importFinished(bool success, string message)
    }
    Component { id: mainFactory; Main {} }
    function init() { appSettings.petLayout = ({}) }
    function test_closeOnlyTaskWindow() {
        const window = createTemporaryObject(mainFactory, test)
        window.x = 200; window.y = 100
        wait(50)
        const badge = window.petBounds.statusItem
        badge.showTasks()
        tryCompare(badge.activePopup, "visible", true)
        const closeButton = findChild(badge.activePopup.contentItem, "closeActiveTasksButton")
        verify(closeButton !== null)
        mouseClick(closeButton)
        tryCompare(badge.activePopup, "visible", false)
        compare(window.detailsVisible, false)
        window.setDetailsVisible(true)
        badge.showTasks()
        tryCompare(badge.activePopup, "visible", true)
        mouseClick(closeButton)
        tryCompare(badge.activePopup, "visible", false)
        compare(window.detailsVisible, true)
        window.close()
    }
    function test_dragFarFromPet() {
        const window = createTemporaryObject(mainFactory, test)
        window.x = 200; window.y = 100
        wait(50)
        const badge = window.petBounds.statusItem
        badge.showTasks()
        tryCompare(badge.activePopup, "visible", true)
        const popup = badge.activePopup
        wait(30)
        const before = Qt.point(popup.x, popup.y)
        const handle = findChild(popup.contentItem, "tasksPopupDragArea")
        mousePress(handle, 30, 8)
        verify(handle.pressed)
        handle.moveTo(330, 308)
        mouseRelease(handle, 30, 8)
        wait(30)
        fuzzyCompare(popup.x, before.x + 300, 1)
        fuzzyCompare(popup.y, before.y + 300, 1)
        verify(popup.x > window.x + window.width)
        popup.close()
        badge.showTasks()
        fuzzyCompare(popup.x, before.x + 300, 1)
        fuzzyCompare(popup.y, before.y + 300, 1)
        popup.close(); window.close()
    }
    function test_dragActiveTasks() {
        const window = createTemporaryObject(mainFactory, test)
        window.x = 200
        window.y = 100
        wait(50)
        const pet = window.petBounds
        const beforePet = pet.mapToGlobal(0, 0)
        const badge = pet.statusItem
        const popup = badge.activePopup
        badge.showTasks()
        tryCompare(popup, "opened", true)
        wait(30)
        const dragArea = findChild(badge, "tasksPopupDragArea")
        const before = Qt.point(popup.x, popup.y)
        mousePress(dragArea, 30, 8, Qt.LeftButton)
        verify(dragArea.pressed)
        // The offscreen platform does not deliver cursor moves to native popup windows.
        dragArea.moveTo(-10, -22)
        mouseRelease(dragArea, 30, 8, Qt.LeftButton)
        wait(50)
        const after = Qt.point(popup.x, popup.y)
        verify(after.x < before.x)
        verify(after.y < before.y)
        verify(appSettings.petLayout.tasksPopup !== undefined)
        fuzzyCompare(pet.mapToGlobal(0, 0).x, beforePet.x, 1)
        fuzzyCompare(pet.mapToGlobal(0, 0).y, beforePet.y, 1)
        popup.close()
        badge.showTasks()
        tryCompare(popup, "opened", true)
        fuzzyCompare(popup.x, after.x, 1)
        fuzzyCompare(popup.y, after.y, 1)
        popup.close()
        window.close()
    }
    function test_usagePopupKeepsPetStill() {
        const window = createTemporaryObject(mainFactory, test)
        verify(window !== null)
        wait(50)
        const pet = window.petBounds
        const before = pet.mapToGlobal(0, 0)
        window.setDetailsVisible(true)
        wait(30)
        const after = pet.mapToGlobal(0, 0)
        fuzzyCompare(after.x, before.x, 1)
        fuzzyCompare(after.y, before.y, 1)
        compare(window.detailsSide, "left")
        verify(window.x >= 0 && window.y >= 0)
        verify(window.x + window.width <= 1200)
        verify(window.y + window.height <= 800)
        window.setDetailsVisible(false)
        wait(30)
        const closed = pet.mapToGlobal(0, 0)
        fuzzyCompare(closed.x, before.x, 1)
        fuzzyCompare(closed.y, before.y, 1)
        window.close()
    }
    function test_taskPopupFlips() {
        const window = createTemporaryObject(mainFactory, test)
        verify(window !== null)
        wait(50)
        const badge = window.petBounds.statusItem
        const popup = badge.activePopup
        badge.showTasks()
        tryCompare(popup, "opened", true)
        verify(badge.fittedPosition.x < 0)
        const popupOrigin = Qt.point(popup.x, popup.y)
        verify(popupOrigin.x >= 0 && popupOrigin.y >= 0)
        verify(popupOrigin.x + popup.width <= 1200)
        verify(popupOrigin.y + popup.height <= 800)
        popup.close()
        window.close()
    }
}
