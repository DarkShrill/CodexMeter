import QtQuick

Canvas {
    id: root
    property real progress: 0.0
    property real thickness: 10
    property color trackColor: "#D6DFEB"
    property color progressColor: "#2479FF"
    property real startAngle: -Math.PI / 2
    property bool rounded: true

    onProgressChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onProgressColorChanged: requestPaint()
    onTrackColorChanged: requestPaint()
    onThicknessChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const cx = width / 2
        const cy = height / 2
        const radius = Math.max(1, Math.min(width, height) / 2 - thickness / 2 - 1)
        ctx.lineWidth = thickness
        ctx.lineCap = rounded ? "round" : "butt"

        ctx.strokeStyle = trackColor
        ctx.beginPath()
        ctx.arc(cx, cy, radius, 0, Math.PI * 2)
        ctx.stroke()

        const p = Math.max(0, Math.min(1, progress))
        if (p > 0.001) {
            ctx.strokeStyle = progressColor
            ctx.beginPath()
            ctx.arc(cx, cy, radius, startAngle, startAngle + Math.PI * 2 * p)
            ctx.stroke()
        }
    }
}
