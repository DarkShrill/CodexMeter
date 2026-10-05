import QtQuick

Item {
    id: root
    property real percent: 0
    property bool hasData: true
    property real bubbleScale: 1
    property bool storm: false
    property int stormDurationMs: 5000
    property bool stormCleared: false
    readonly property bool stormVisible: storm && !stormCleared
    readonly property bool rainbowVisible: false // storm && stormCleared
    property bool animationsEnabled: true
    readonly property bool weatherRunning: stormVisible && animationsEnabled && visible
    implicitWidth: 144 * bubbleScale
    implicitHeight: 96 * bubbleScale
    signal bodyClicked()
    signal settingsRequested()
    FontLoader { id: percentageFont; source: "../../assets/fonts/Poppins-Medium.ttf" }
    onStormChanged: {
        stormCleared = false
        if (storm) stormTimer.restart()
        else stormTimer.stop()
    }
    Component.onCompleted: if (storm) stormTimer.start()
    Timer {
        id: stormTimer
        interval: Math.max(1, root.stormDurationMs)
        onTriggered: root.stormCleared = true
    }
    Item {
        id: artwork
        width: 144; height: 96
        scale: root.bubbleScale
        transformOrigin: Item.TopLeft
        Canvas {
            id: cloud
            width: 144 * root.bubbleScale; height: 72 * root.bubbleScale
            scale: 1 / root.bubbleScale
            transformOrigin: Item.TopLeft
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onVisibleChanged: if (visible) requestPaint()
            Connections { target: root; function onStormVisibleChanged() { cloud.requestPaint() } }
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.scale(width / 144, height / 72)
                ctx.beginPath()
                ctx.moveTo(26, 64)
                ctx.bezierCurveTo(5, 65, -5, 43, 12, 31)
                ctx.bezierCurveTo(8, 13, 28, 4, 43, 12)
                ctx.bezierCurveTo(52, -2, 76, -2, 87, 10)
                ctx.bezierCurveTo(105, 1, 129, 12, 128, 28)
                ctx.bezierCurveTo(150, 33, 146, 58, 126, 62)
                ctx.bezierCurveTo(116, 74, 95, 70, 86, 65)
                ctx.bezierCurveTo(67, 73, 42, 72, 26, 64)
                ctx.closePath()
                if (root.stormVisible) {
                    const shade = ctx.createLinearGradient(0, 0, 0, 72)
                    shade.addColorStop(0, "#65758D")
                    shade.addColorStop(0.45, "#48576E")
                    shade.addColorStop(1, "#343E50")
                    ctx.fillStyle = shade
                } else ctx.fillStyle = "#FAFAFB"
                ctx.fill()
                ctx.strokeStyle = root.stormVisible ? "#55647A" : "#D8DADD"
                ctx.lineWidth = 1
                ctx.stroke()
                if (root.stormVisible) {
                    ctx.save()
                    ctx.clip()
                    ctx.fillStyle = "#FFFFFF"
                    ctx.globalAlpha = 0.06
                    function lobe(x, y, rx, ry) {
                        ctx.save(); ctx.translate(x, y); ctx.scale(rx, ry)
                        ctx.beginPath(); ctx.arc(0, 0, 1, 0, Math.PI * 2); ctx.fill(); ctx.restore()
                    }
                    lobe(43, 24, 26, 19)
                    lobe(73, 20, 30, 19)
                    ctx.globalAlpha = 0.12
                    ctx.fillStyle = "#1C273B"
                    lobe(78, 44, 38, 29)
                    lobe(27, 49, 25, 19)
                    lobe(121, 47, 25, 20)
                    ctx.restore()
                }
            }
        }
        Text {
            objectName: "bubblePercent"
            width: parent.width; height: 72
            text: root.hasData ? Math.round(root.percent) + "%" : "--%"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: root.stormVisible ? "#FFFFFF" : "#252A32"
            font.family: percentageFont.name || "Poppins"
            font.pixelSize: 28
            font.weight: Font.Medium
        }
        Rectangle {
            x: parent.width / 2 + 4; y: 77
            width: 10; height: 10; radius: 5
            color: root.stormVisible ? "#65758D" : "#FAFAFB"; border.color: root.stormVisible ? "#55647A" : "#D8DADD"
        }
        Rectangle {
            x: parent.width / 2 - 3; y: 90
            width: 6; height: 6; radius: 3
            color: root.stormVisible ? "#65758D" : "#FAFAFB"; border.color: root.stormVisible ? "#55647A" : "#D8DADD"
        }
        // Separate lanes leave the percentage and the thought dots readable.
        Repeater {
            model: 10
            delegate: Item {
                id: rain
                objectName: "weatherRain" + index
                required property int index
                property real fall: (index % 4) / 4
                readonly property bool binary: index % 3 !== 0
                x: [15, 30, 45, 57, 91, 104, 119, 132, 39, 110][index]
                y: 62 + fall * 29
                width: 8; height: 10
                visible: root.stormVisible
                opacity: (1 - fall * 0.65) * 0.9
                Text {
                    visible: rain.binary
                    anchors.centerIn: parent
                    text: rain.index % 2 ? "1" : "0"
                    color: "#A7C9EA"
                    font.family: "Poppins"
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }
                Canvas {
                    visible: !rain.binary
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        ctx.beginPath()
                        ctx.moveTo(5, 0)
                        ctx.bezierCurveTo(4, 3, 0, 5, 1, 8)
                        ctx.bezierCurveTo(3, 12, 8, 9, 7, 6)
                        ctx.closePath()
                        ctx.fillStyle = "#82ADD7"
                        ctx.fill()
                    }
                }
                SequentialAnimation {
                    running: root.weatherRunning
                    loops: Animation.Infinite
                    PauseAnimation { duration: rain.index * 83 }
                    NumberAnimation { target: rain; property: "fall"; from: 0; to: 1; duration: 750 + rain.index % 3 * 140 }
                }
            }
        }
        Repeater {
            model: 2
            delegate: Canvas {
                id: bolt
                objectName: "weatherBolt" + index
                required property int index
                x: index === 0 ? 19 : 109
                y: index === 0 ? 54 : 58
                width: 17 * root.bubbleScale; height: 34 * root.bubbleScale
                scale: 1 / root.bubbleScale
                transformOrigin: Item.TopLeft
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                visible: root.stormVisible
                opacity: 0.85
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.scale(width / 17, height / 34)
                    ctx.beginPath()
                    ctx.moveTo(9, 0); ctx.lineTo(1, 17); ctx.lineTo(8, 17)
                    ctx.lineTo(3, 34); ctx.lineTo(17, 12); ctx.lineTo(10, 12)
                    ctx.lineTo(15, 0); ctx.closePath()
                    const glow = ctx.createLinearGradient(0, 0, 17, 34)
                    glow.addColorStop(0, "#FFE47B"); glow.addColorStop(1, "#FFF6BD")
                    ctx.fillStyle = glow; ctx.fill()
                }
                SequentialAnimation {
                    running: root.weatherRunning
                    loops: Animation.Infinite
                    PauseAnimation { duration: bolt.index * 430 }
                    NumberAnimation { target: bolt; property: "opacity"; to: 1; duration: 80 }
                    NumberAnimation { target: bolt; property: "opacity"; to: 0.2; duration: 100 }
                    NumberAnimation { target: bolt; property: "opacity"; to: 0.95; duration: 80 }
                    NumberAnimation { target: bolt; property: "opacity"; to: 0.25; duration: 450 }
                    PauseAnimation { duration: 1400 }
                }
            }
        }
        Canvas {
            id: rainbow
            objectName: "weatherRainbow"
            x: 99; y: 0
            width: 44 * root.bubbleScale; height: 26 * root.bubbleScale
            scale: 1 / root.bubbleScale
            transformOrigin: Item.TopLeft
            visible: root.rainbowVisible
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onVisibleChanged: if (visible) requestPaint()
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: root.animationsEnabled ? 450 : 0 } }
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset(); ctx.scale(width / 44, height / 26)
                const colors = ["#EB716A", "#ECA563", "#EBCD68", "#76B990", "#77AFD8", "#9685C6"]
                ctx.lineWidth = 2.5
                for (let i = 0; i < colors.length; i++) {
                    ctx.beginPath()
                    ctx.strokeStyle = colors[i]
                    ctx.arc(22, 23, 20 - i * 2.5, Math.PI, Math.PI * 2)
                    ctx.stroke()
                }
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) root.settingsRequested()
            else root.bodyClicked()
        }
    }
}
