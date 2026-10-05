import QtQuick

Item {
    id: root
    required property var rateModel
    required property var settings
    property var activity: null
    readonly property var layoutOffsets: settings.petLayout || ({})
    function offset(name) { return layoutOffsets[name] || ({x: 0, y: 0}) }
    property alias infoItem: thought
    property alias statusItem: taskBadge
    readonly property real contentLeft: Math.min(0, thought.x, taskBadge.x)
    readonly property real contentTop: Math.min(0, thought.y, taskBadge.y)
    readonly property real contentRight: Math.max(implicitWidth, thought.x + thought.width, taskBadge.x + taskBadge.width)
    readonly property real contentBottom: Math.max(implicitHeight, thought.y + thought.height, taskBadge.y + taskBadge.height)
    property bool animationPreviewMode: false
    readonly property bool animated: animationPreviewMode || settings.petAnimated === true
    readonly property bool bubbleInfo: settings.petInfoStyle === "bubble"
    readonly property real bubbleScale: Math.max(0.60, Math.min(1.80, settings.petBubbleScale || 1))
    readonly property real petAreaWidth: root.bubbleInfo ? Math.max(240, 144 * root.bubbleScale) : 240
    readonly property bool working: activity ? activity.working : false
    readonly property string codexState: activity && activity.state !== undefined
        ? activity.state : working ? "working" : "idle"
    readonly property string legacyMascotState: codexState === "completed" ? "happy"
        : codexState === "failed" ? "critical" : codexState === "waiting" ? "warning"
        : codexState === "idle" ? "idle" : "thinking"
    property bool celebrating: false
    readonly property bool pixelMascot: settings.petExpression === 4
    readonly property bool pipMascot: settings.petExpression !== 4
    readonly property var customPet: settings.petExpression >= 1000 ? petLibrary.pet(settings.petExpression) : ({})
    property int revision: 0
    readonly property real remainingPercent: { revision; return rateModel.count > 0 ? rateModel.get(0).remainingPercent : 50 }
    readonly property string desiredMascotState: remainingPercent > 70 ? "happy"
        : remainingPercent > 40 ? "idle" : remainingPercent > 20 ? "thinking"
        : remainingPercent > 10 ? "warning" : "critical"
    property string stableMascotState: "idle"
    onDesiredMascotStateChanged: stateDebounce.restart()
    Component.onCompleted: stableMascotState = desiredMascotState
    Timer { id: stateDebounce; interval: 1800; onTriggered: root.stableMascotState = root.desiredMascotState }
    Connections {
        target: root.rateModel
        function onModelReset() { root.revision++ }
        function onDataChanged() { root.revision++ }
        function onRowsInserted() { root.revision++ }
        function onRowsRemoved() { root.revision++ }
    }
    Loader {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -30
        y: thought.height + 10
        width: 88; height: 88
        active: root.pixelMascot
        sourceComponent: Component {
            Mascot {
                state: root.legacyMascotState
                playing: root.animated
            }
        }
    }
    Loader {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -30
        anchors.bottom: parent.bottom
        width: 168; height: 182
        active: root.pipMascot
        sourceComponent: root.settings.petExpression >= 1000 ? customPetComponent : root.settings.petExpression === 10 ? miniElonComponent : root.settings.petExpression === 8 ? doraemonComponent : root.settings.petExpression === 9 ? gokuComponent : root.settings.petExpression === 7 ? darioComponent : root.settings.petExpression === 6 ? clippitComponent : pipComponent
        Component {
            id: customPetComponent
            Mascot {
                resourceRoot: root.customPet.resourceRoot || ""
                animations: root.customPet.animations || ({})
                state: root.codexState
                playing: root.animated
                floatMotion: false
                frameSmooth: true
                occasionalAnimations: []
                implicitWidth: 192
                implicitHeight: 208
            }
        }
        Component {
            id: gokuComponent
            GokuMascot { state: root.codexState; playing: root.animated }
        }
        Component {
            id: darioComponent
            DarioMascot { state: root.codexState; playing: root.animated }
        }
        Component {
            id: doraemonComponent
            DoraemonMascot { state: root.codexState; playing: root.animated }
        }
        Component {
            id: miniElonComponent
            MiniElonMascot { state: root.codexState; playing: root.animated }
        }
        Component {
            id: clippitComponent
            ClippitMascot { state: root.codexState; playing: root.animated }
        }
        Component {
            id: pipComponent
            PipMascot {
                // Kira keeps moving between Codex events, like the pet gallery player.
                loopAnimation: root.settings.petExpression === 0
                occasionalAnimations: root.settings.petExpression === 0 ? ["waving"] : []
                resourceRoot: root.settings.petExpression === 0 ? "qrc:/assets/kira/frames/"
                    : root.settings.petExpression === 1 ? "qrc:/assets/darkshrill/frames/" : "qrc:/assets/pip/"
                state: root.codexState
                playing: root.animated
            }
        }
    }
    implicitWidth: petAreaWidth + 60
    implicitHeight: thought.implicitHeight + (pixelMascot ? 98 : 190)
    signal settingsRequested()
    signal bodyClicked()

    readonly property var primary: { revision; return rateModel.count > 0 ? rateModel.get(0) : ({ "remainingPercent": 0, "bucket": "--", "limitId": "Codex" }) }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) root.settingsRequested()
            else root.bodyClicked()
        }
    }

    Item {
        id: thought
        x: (root.width - width) / 2 - 30 + root.offset("bubble").x
        y: root.offset("bubble").y
        implicitWidth: root.bubbleInfo ? 144 * root.bubbleScale : 200
        implicitHeight: root.bubbleInfo ? 96 * root.bubbleScale : 146
        width: implicitWidth; height: implicitHeight
        UsageCard {
            anchors.fill: parent
            visible: !root.bubbleInfo
            rateModel: root.rateModel
            cardStyle: 0
            onBodyClicked: root.bodyClicked()
            onSettingsRequested: root.settingsRequested()
        }
        PetPercentBubble {
            objectName: "petPercentBubble"
            anchors.fill: parent
            visible: root.bubbleInfo
            bubbleScale: root.bubbleScale
            storm: ["thinking", "working", "review", "running", "running-left", "running-right"].indexOf(root.codexState) >= 0
            animationsEnabled: root.animated
            percent: root.primary.remainingPercent
            hasData: root.rateModel.count > 0
            onBodyClicked: root.bodyClicked()
            onSettingsRequested: root.settingsRequested()
        }
    }
    Rectangle {
        visible: !root.bubbleInfo
        width: 14; height: 14; rotation: 45; color: "#FAFAFB"
        border.color: "#D8DADD"; anchors.horizontalCenter: thought.horizontalCenter; y: thought.y + thought.height - 8; z: -1
    }
    TaskStatusBadge {
        id: taskBadge
        x: root.petAreaWidth - 16 + root.offset("status").x
        y: thought.height + (root.pixelMascot ? 32 : 76) + root.offset("status").y
        popupOffset: root.offset("tasksPopup")
        positionSettings: root.settings
        popupAnchor: root
        activity: root.activity
    }
    Connections {
        target: root.activity
        ignoreUnknownSignals: true
        function onTaskCompleted() {
            if (root.animated && root.visible) { root.celebrating = true; celebrationTimer.restart() }
        }
    }
    Timer { id: celebrationTimer; interval: 2600; onTriggered: root.celebrating = false }
    onAnimatedChanged: if (!animated) { celebrating = false; celebrationTimer.stop() }
}
