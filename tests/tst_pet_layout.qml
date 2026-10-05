import QtQuick
import QtTest
import "../qml/components"
import "../qml/previews"

TestCase {
    id: test
    name: "PetLayout"
    when: windowShown
    width: 900; height: 720; visible: true
    PreviewData { id: data }
    QtObject {
        id: settings
        property int petExpression: 5
        property string petInfoStyle: "bubble"
        property real petBubbleScale: 1
        property bool petAnimated: false
        property var petLayout: ({})
        function setPetLayoutOffset(name, x, y) {
            const next = Object.assign({}, petLayout)
            next[name] = {x: x, y: y}
            petLayout = next
        }
        function resetPetLayout() { petLayout = ({}) }
    }
    PetLayoutPreview {
        id: editor
        settings: settings; rateModel: data.rateModel; client: data.client
    }
    function useLocalFrames(item) {
        if (item.resourceRoot !== undefined) item.resourceRoot = Qt.resolvedUrl("../assets/pip/")
        for (let child of item.children || []) useLocalFrames(child)
    }
    function init() {
        settings.resetPetLayout(); editor.elementIndex = 0; editor.open()
        tryCompare(editor, "opened", true); useLocalFrames(editor.contentItem)
    }
    function cleanup() { editor.close(); tryCompare(editor, "visible", false) }
    function test_dragElements_data() {
        return [{tag: "bubble", index: 0, key: "bubble"},
                {tag: "status", index: 1, key: "status"},
                {tag: "details", index: 3, key: "details"}]
    }
    function test_dragElements(row) {
        editor.elementIndex = row.index
        wait(30)
        const handle = findChild(editor, "petLayoutDragArea")
        verify(handle !== null)
        const x = handle.x
        const y = handle.y
        mouseDrag(handle, handle.width / 2, handle.height / 2, 30, 20, Qt.LeftButton)
        verify(settings.petLayout[row.key].x > 0)
        verify(settings.petLayout[row.key].y > 0)
        verify(handle.x > x)
        verify(handle.y > y)
        editor.close(); editor.open(); tryCompare(editor, "opened", true)
        compare(handle.x, x + settings.petLayout[row.key].x)
        settings.resetPetLayout()
        compare(handle.x, x)
        compare(handle.y, y)
    }
    function test_stateAndPopup() {
        editor.testState = "waiting"
        editor.elementIndex = 2
        const popup = findChild(editor, "activeTasksPreviewPopup")
        tryCompare(popup, "visible", true)
        compare(popup.closePolicy, 0)
        const titleHandle = findChild(editor, "tasksPopupDragArea")
        mouseDrag(titleHandle, 30, 10, 40, 30, Qt.LeftButton)
        verify(settings.petLayout.tasksPopup.x > 0)
        verify(settings.petLayout.tasksPopup.y > 0)
        settings.setPetLayoutOffset("tasksPopup", 60, -20)
        const previousX = popup.x
        settings.setPetLayoutOffset("tasksPopup", 90, -20)
        compare(popup.x, previousX + 30)
        editor.elementIndex = 0
        tryCompare(popup, "visible", false)
    }
    function test_visualCapture() {
        editor.elementIndex = 3
        wait(100)
        grabImage(test).save("C:/QT_WORKSPACE/CodexMeter/build/Debug/pet-layout-preview.png")
    }
    function test_dropdownStyleAndSelection() {
        const states = findChild(editor, "layoutTestState")
        compare(states.font.family, "Poppins")
        compare(states.background.radius, 7)
        states.popup.open()
        tryCompare(states.popup, "opened", true)
        compare(states.popup.background.radius, 7)
        const list = states.popup.contentItem
        list.positionViewAtBeginning()
        tryVerify(function() { return list.itemAtIndex(0) !== null })
        const first = list.itemAtIndex(0)
        verify(first !== null)
        compare(first.contentItem.text, "Riposo")
        mouseClick(first)
        compare(editor.testState, "idle")
        const elements = findChild(editor, "layoutElementChoice")
        elements.popup.open()
        tryCompare(elements.popup, "opened", true)
        tryVerify(function() { return elements.popup.contentItem.itemAtIndex(0) !== null })
        compare(elements.popup.contentItem.itemAtIndex(0).contentItem.text, "Nuvoletta / info")
        grabImage(test).save("C:/QT_WORKSPACE/CodexMeter/build/Debug/pet-layout-dropdown.png")
        elements.popup.close()
    }
}
