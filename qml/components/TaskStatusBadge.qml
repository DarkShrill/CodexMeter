import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "PopupPlacement.js" as PopupPlacement

Button {
    id: root
    objectName: "taskStatusBadge"
    property var activity: null
    property var popupOffset: ({x: 0, y: 0})
    property bool layoutEditing: false
    property var positionSettings: null
    property Item popupAnchor: root
    property point fittedPosition: Qt.point(width + 8, 0)
    property bool placingWindow: false
    readonly property var activePopup: layoutEditing ? tasksPopup : tasksWindow
    function fitPopup() {
        const origin = mapToGlobal(0, 0)
        const preferred = mapToGlobal(width + 8 + popupOffset.x,
            (height - tasksWindow.height) / 2 + popupOffset.y)
        const anchor = popupAnchor.mapToGlobal(0, 0)
        const end = popupAnchor.mapToGlobal(popupAnchor.width, popupAnchor.height)
        let placed = preferred
        if (positionSettings && positionSettings.availableScreenGeometry) {
            const bounds = positionSettings.availableScreenGeometry(Math.round(preferred.x + tasksWindow.width / 2),
                Math.round(preferred.y + tasksWindow.height / 2))
            placed = PopupPlacement.place({x: anchor.x, y: anchor.y, width: end.x - anchor.x, height: end.y - anchor.y},
                {width: tasksWindow.width, height: tasksWindow.height}, preferred, bounds)
        }
        placingWindow = true
        tasksWindow.x = Math.round(placed.x)
        tasksWindow.y = Math.round(placed.y)
        placingWindow = false
        fittedPosition = Qt.point(placed.x - origin.x, placed.y - origin.y)
    }
    function savePopupPosition() {
        if (!tasksWindow.visible || !positionSettings || !positionSettings.setPetLayoutOffset) return
        const origin = mapToGlobal(0, 0)
        const unit = mapToGlobal(1, 1)
        positionSettings.setPetLayoutOffset("tasksPopup",
            (tasksWindow.x - origin.x) / (unit.x - origin.x) - width - 8,
            (tasksWindow.y - origin.y) / (unit.y - origin.y) - (height - tasksWindow.height) / 2)
    }
    signal popupMoved(real x, real y)
    function showTasks() {
        if (layoutEditing) tasksPopup.open()
        else {
            fitPopup(); tasksWindow.show(); tasksWindow.raise()
            // Include the list's final height after the first visible layout pass.
            Qt.callLater(function() { if (tasksWindow.visible) root.fitPopup() })
        }
    }
    function hideTasks() { if (layoutEditing) tasksPopup.close(); else tasksWindow.hide() }
    readonly property int taskCount: activity && activity.taskCount !== undefined ? activity.taskCount : 0
    readonly property var tasks: activity && activity.activeTasks !== undefined ? activity.activeTasks : []
    implicitWidth: 46
    implicitHeight: 34
    hoverEnabled: true
    onClicked: root.showTasks()
    Accessible.name: (taskCount === 1 ? qsTr("%1 task attivo") : qsTr("%1 task attivi")).arg(taskCount)

    ToolTip {
        id: taskToolTip
        visible: hovered
        text: qsTr("Task attivi: %1 · Clicca per i nomi").arg(taskCount)
        // width: 96
        height: 16
        padding: 6
        contentItem: Text {
            text: taskToolTip.text
            color: "#FFFFFF"
            font.family: "Poppins"
            font.pixelSize: 10
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 10
            color: "#4B5964"
        }
    }
    background: Rectangle {
        radius: 9
        color: root.down ? "#DCE8E7" : root.hovered ? "#E5EEEE" : "#FAFAFB"
        border.color: root.visualFocus ? "#0091FF" : "#D8DADD"
    }
    contentItem: Row {
        spacing: 5
        LineIcon { width: 14; height: 18; name: "usage"; stroke: root.taskCount ? "#0091FF" : "#9298A0" }
        Text {
            text: root.taskCount
            color: "#252A32"
            font.family: "Poppins"
            font.pixelSize: 13
            font.weight: Font.Medium
        }
    }
    Popup {
        id: tasksPopup
        objectName: "activeTasksPreviewPopup"
        popupType: Popup.Item
        x: root.width + 8 + root.popupOffset.x
        y: (root.height - height) / 2 + root.popupOffset.y
        width: 320
        padding: 12
        closePolicy: Popup.NoAutoClose
        background: Rectangle { color: "#FAFAFB"; radius: 10; border.color: "#D8DADD" }
        contentItem: Loader {
            sourceComponent: root.layoutEditing ? taskContent : null
        }
    }
    Window {
        id: tasksWindow
        objectName: "activeTasksPopup"
        title: qsTr("Task attivi")
        transientParent: root.Window.window
        flags: Qt.Tool | Qt.FramelessWindowHint | (root.positionSettings && root.positionSettings.alwaysOnTop ? Qt.WindowStaysOnTopHint : 0)
        color: "transparent"
        width: 320
        height: taskLoader.implicitHeight + 24
        readonly property int padding: 12
        readonly property bool opened: visible
        onXChanged: if (visible && !root.placingWindow) savePositionTimer.restart()
        onYChanged: if (visible && !root.placingWindow) savePositionTimer.restart()
        Rectangle { anchors.fill: parent; color: "#FAFAFB"; radius: 10; border.color: "#D8DADD" }
        Loader {
            id: taskLoader
            x: 12; y: 12; width: parent.width - 24
            sourceComponent: root.layoutEditing ? null : taskContent
        }
        Shortcut { sequence: "Escape"; enabled: tasksWindow.visible; onActivated: root.hideTasks() }
    }
    Timer { id: savePositionTimer; interval: 200; onTriggered: root.savePopupPosition() }
    Component {
        id: taskContent
        ColumnLayout {
            spacing: 4
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: qsTr("Task attivi · %1").arg(root.taskCount)
                    color: "#252A32"
                    font.family: "Poppins"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    MouseArea {
                        id: popupDrag
                        objectName: "tasksPopupDragArea"
                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor
                        preventStealing: true
                        property point start
                        property point original
                        onPressed: function(mouse) {
                            if (root.layoutEditing) {
                                start = mapToItem(root.parent, mouse.x, mouse.y)
                                original = Qt.point(root.popupOffset.x, root.popupOffset.y)
                            } else {
                                start = mapToGlobal(mouse.x, mouse.y)
                                original = Qt.point(tasksWindow.x, tasksWindow.y)
                            }
                        }
                        onPositionChanged: function(mouse) { moveTo(mouse.x, mouse.y) }
                        function moveTo(mouseX, mouseY) {
                            if (!pressed) return
                            if (root.layoutEditing) {
                                const point = mapToItem(root.parent, mouseX, mouseY)
                                root.popupMoved(original.x + point.x - start.x, original.y + point.y - start.y)
                            } else {
                                const point = mapToGlobal(mouseX, mouseY)
                                tasksWindow.x = Math.round(original.x + point.x - start.x)
                                tasksWindow.y = Math.round(original.y + point.y - start.y)
                            }
                        }
                        onReleased: if (!root.layoutEditing) root.savePopupPosition()
                    }
                }
                ToolButton {
                    implicitWidth: 24; implicitHeight: 24
                    objectName: "closeActiveTasksButton"
                    onClicked: Qt.callLater(root.hideTasks)
                    Accessible.name: qsTr("Chiudi elenco task")
                    contentItem: LineIcon { name: "close"; stroke: "#626971" }
                    background: Rectangle { radius: 5; color: parent.hovered ? "#ECEDEF" : "transparent" }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#E1E3E6" }
            Text {
                visible: root.taskCount === 0
                Layout.fillWidth: true
                text: qsTr("Nessun task attivo.")
                color: "#777D85"
                font.family: "Poppins"
                font.pixelSize: 13
            }
            ListView {
                id: taskList
                objectName: "activeTasksList"
                visible: root.taskCount > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 280)
                clip: true
                spacing: 8
                model: root.tasks
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; background: Item{}}
                delegate: Rectangle {
                    required property var modelData
                    width: taskList.width
                    height: taskName.implicitHeight + taskState.implicitHeight + 24
                    radius: 7; color: "#F1F2F3"
                    Text {
                        id: taskName
                        x: 12; y: 10; width: parent.width - 24
                        text: modelData.title
                        wrapMode: Text.Wrap
                        color: "#252A32"
                        font.family: "Poppins"
                        font.pixelSize: 13
                    }
                    Text {
                        id: taskState
                        x: 12; y: taskName.y + taskName.implicitHeight + 4
                        text: ({thinking: qsTr("Ragionamento"), working: qsTr("In esecuzione"), review: qsTr("Revisione"), waiting: qsTr("In attesa di input"), failed: qsTr("Errore")})[modelData.state] || qsTr("In esecuzione")
                        color: "#777D85"
                        font.family: "Poppins"
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
