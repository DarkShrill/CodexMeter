import QtQuick

Item {
    id: root
    state: "idle" // Item already exposes the string property state.
    property int fps: 8
    property bool playing: true
    property real mascotScale: 1.0
    property bool floatMotion: true
    property bool frameSmooth: false
    property bool loopAnimation: false
    property bool cycleDone: false
    signal animationFinished(string name)
    property url resourceRoot: "qrc:/assets/mascot/"
    property var animations: ({
        idle: { frames: 8 }, thinking: { frames: 8 }, happy: { frames: 8 },
        warning: { frames: 8 }, critical: { frames: 8 },
        blink: { frames: 4, fps: 8 }
    })
    property var occasionalAnimations: ["blink"]
    property int occasionalMinMs: 6000
    property int occasionalMaxMs: 12000
    property string temporaryAnimation: ""
    property int frameIndex: 0
    readonly property string animationName: temporaryAnimation || (animations[state] ? state : "idle")
    readonly property var config: animations[animationName] || ({ frames: 1 })
    readonly property int frameCount: Math.max(1, config.frames || 1)
    readonly property int effectiveFps: Math.max(1, config.fps || fps)
    readonly property bool framesReady: {
        for (let i = 0; i < frames.count; ++i) {
            const image = frames.itemAt(i)
            if (!image || image.status !== Image.Ready) return false
        }
        return frames.count === frameCount
    }
    implicitWidth: 80
    implicitHeight: 80

    function frameUrl(name, index) {
        const directory = animations[name] && animations[name].directory || name
        return resourceRoot + directory + "/" + (index < 10 ? "0" : "") + index + ".png"
    }
    function restartAnimation() { frameIndex = 0; cycleDone = false }
    function playOnce(name) {
        if (!playing || !animations[name]) return false
        temporaryAnimation = name
        restartAnimation()
        return true
    }
    function scheduleOccasional() {
        if (!loopAnimation) { occasional.stop(); return }
        occasional.interval = Math.max(1000, occasionalMinMs + Math.random()
            * Math.max(0, occasionalMaxMs - occasionalMinMs))
        occasional.restart()
    }
    onStateChanged: { temporaryAnimation = ""; restartAnimation(); scheduleOccasional() }
    onAnimationNameChanged: restartAnimation()
    onFrameCountChanged: restartAnimation()
    onPlayingChanged: { if (playing) { restartAnimation(); scheduleOccasional() } else occasional.stop() }
    onLoopAnimationChanged: { restartAnimation(); scheduleOccasional() }
    Component.onCompleted: scheduleOccasional()

    Item {
        anchors.centerIn: parent
        width: root.width
        height: root.height
        scale: root.mascotScale
        transform: Translate { id: drift }
        // Loaded synchronously and cached: changing frame changes visibility only.
        Repeater {
            id: frames
            model: root.frameCount
            delegate: Image {
                required property int index
                anchors.fill: parent
                source: root.frameUrl(root.animationName, index)
                asynchronous: false
                cache: true
                smooth: root.frameSmooth
                mipmap: false
                fillMode: Image.PreserveAspectFit
                visible: index === root.frameIndex
            }
        }
        SequentialAnimation {
            running: root.playing && root.visible && root.loopAnimation && root.floatMotion && root.state === "idle"
            loops: Animation.Infinite
            NumberAnimation { target: drift; property: "y"; from: 0; to: -1.5; duration: 2400; easing.type: Easing.InOutSine }
            NumberAnimation { target: drift; property: "y"; from: -1.5; to: 0; duration: 2400; easing.type: Easing.InOutSine }
            onRunningChanged: if (!running) drift.y = 0
        }
    }
    Timer {
        interval: root.config.durations
            ? root.config.durations[root.frameIndex]
            : Math.max(1, Math.round(1000 / root.effectiveFps))
        repeat: true
        running: root.playing && root.visible && root.framesReady && !root.cycleDone
        onTriggered: {
            if (root.frameIndex + 1 < root.frameCount) root.frameIndex++
            else {
                const finished = root.animationName
                if (root.temporaryAnimation) { root.temporaryAnimation = ""; root.scheduleOccasional() }
                else if (root.loopAnimation) root.frameIndex = 0
                else root.cycleDone = true
                root.animationFinished(finished)
            }
        }
    }
    Timer {
        id: occasional
        onTriggered: {
            if (root.playing && root.visible && root.loopAnimation && root.state === "idle"
                    && !root.temporaryAnimation && root.occasionalAnimations.length) {
                root.playOnce(root.occasionalAnimations[Math.floor(Math.random() * root.occasionalAnimations.length)])
            }
            root.scheduleOccasional()
        }
    }
}
