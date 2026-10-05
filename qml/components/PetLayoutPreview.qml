import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    objectName: "petLayoutPreview"
    required property var settings
    required property var rateModel
    required property var client
    property string testState: "working"
    property int elementIndex: 0
    readonly property var states: [
        {name: "idle", label: qsTr("Riposo")}, {name: "thinking", label: qsTr("Ragionamento")},
        {name: "working", label: qsTr("Lavoro")}, {name: "review", label: qsTr("Revisione")},
        {name: "waiting", label: qsTr("Attesa di input")}, {name: "completed", label: qsTr("Completamento")},
        {name: "failed", label: qsTr("Errore")}, {name: "running-right", label: qsTr("Corsa destra")},
        {name: "running-left", label: qsTr("Corsa sinistra")}, {name: "waving", label: qsTr("Saluto")}
    ]
    title: qsTr("Posizione elementi del pet")
    modal: true
    width: Math.min(780, parent.width - 24)
    anchors.centerIn: parent
    padding: 20
    background: Rectangle { color: "#FAFAFB"; radius: 10; border.color: "#D9DCDF" }
    function offset(name) { return (settings.petLayout || ({}))[name] || ({x: 0, y: 0}) }
    function updatePopup() {
        if (visible && elementIndex === 2) pet.statusItem.showTasks()
        else pet.statusItem.hideTasks()
    }
    onOpened: updatePopup()
    onClosed: pet.statusItem.hideTasks()
    onElementIndexChanged: updatePopup()
    QtObject {
        id: testActivity
        property string state: root.testState
        property bool working: state !== "idle" && state !== "completed" && state !== "failed"
        property int taskCount: state === "idle" ? 0 : 1
        property var activeTasks: taskCount ? [{title: qsTr("Task di esempio"), state: state}] : []
        signal taskCompleted()
    }
    contentItem: ColumnLayout {
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Label { text: qsTr("Stato di test"); color: "#252A32" }
            SettingsComboBox {
                objectName: "layoutTestState"
                Layout.fillWidth: true
                model: root.states; textRole: "label"; currentIndex: 2
                onActivated: root.testState = root.states[currentIndex].name
            }
            Label { text: qsTr("Elemento"); color: "#252A32" }
            SettingsComboBox {
                objectName: "layoutElementChoice"
                Layout.fillWidth: true
                model: [qsTr("Nuvoletta / info"), qsTr("Barra task"), qsTr("Popup task"), qsTr("Popup utilizzo")]
                currentIndex: root.elementIndex
                onActivated: root.elementIndex = currentIndex
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 420
            color: "#F1F2F3"; radius: 7; border.color: "#E1E3E6"
            clip: true
            Item {
                id: stage
                width: 1100; height: 700
                scale: Math.min(parent.width / width, parent.height / height)
                transformOrigin: Item.TopLeft
                PetView {
                    id: pet
                    x: 300; y: 200
                    width: implicitWidth; height: implicitHeight
                    settings: root.settings
                    rateModel: root.rateModel
                    activity: testActivity
                    animationPreviewMode: root.visible
                    statusItem.layoutEditing: true
                    Connections {
                        target: pet.statusItem
                        function onPopupMoved(x, y) { root.settings.setPetLayoutOffset("tasksPopup", x, y) }
                    }
                }
                DetailPanel {
                    id: details
                    visible: root.elementIndex === 3
                    x: pet.x + pet.width + 26 + root.offset("details").x
                    y: pet.y + 8 + root.offset("details").y
                    rateModel: root.rateModel; client: root.client
                }
                MouseArea {
                    id: mover
                    objectName: "petLayoutDragArea"
                    readonly property var movedItem: root.elementIndex === 0 ? pet.infoItem
                        : root.elementIndex === 1 ? pet.statusItem : details
                    readonly property string element: ["bubble", "status", "tasksPopup", "details"][root.elementIndex]
                    readonly property point itemPosition: Qt.point(
                        movedItem.x + (root.elementIndex < 2 ? pet.x : 0),
                        movedItem.y + (root.elementIndex < 2 ? pet.y : 0))
                    x: itemPosition.x; y: itemPosition.y
                    width: movedItem.width; height: movedItem.height
                    visible: root.elementIndex !== 2
                    cursorShape: Qt.SizeAllCursor
                    property point start
                    property point original
                    property point originalPosition
                    onPressed: function(mouse) {
                        start = mapToItem(stage, mouse.x, mouse.y)
                        const value = root.offset(element)
                        original = Qt.point(value.x, value.y)
                        originalPosition = itemPosition
                    }
                    onPositionChanged: function(mouse) {
                        if (!pressed) return
                        const point = mapToItem(stage, mouse.x, mouse.y)
                        const dx = Math.max(-originalPosition.x, Math.min(stage.width - originalPosition.x - width, point.x - start.x))
                        const dy = Math.max(-originalPosition.y, Math.min(stage.height - originalPosition.y - height, point.y - start.y))
                        root.settings.setPetLayoutOffset(element, original.x + dx, original.y + dy)
                    }
                    Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#0091FF"; border.width: 2; radius: 7 }
                }
            }
        }
        Label {
            Layout.fillWidth: true
            text: root.elementIndex === 2
                ? qsTr("Trascina il titolo del popup task. Le posizioni vengono salvate per questo pet.")
                : qsTr("Trascina l’elemento evidenziato. Le posizioni vengono salvate per questo pet.")
            wrapMode: Text.WordWrap; color: "#777D85"; font.pixelSize: 12
        }
        RowLayout {
            Layout.fillWidth: true
            SettingsButton { text: qsTr("Ripristina posizioni"); onClicked: root.settings.resetPetLayout() }
            Item { Layout.fillWidth: true }
            SettingsButton { text: qsTr("Chiudi"); onClicked: root.close() }
        }
    }
}
