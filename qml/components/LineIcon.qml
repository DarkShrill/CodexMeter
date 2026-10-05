import QtQuick
Canvas {
    id: root
    property string name: "usage"
    property color stroke: "#626971"
    implicitWidth: 20; implicitHeight: 20
    onNameChanged: requestPaint()
    onStrokeChanged: requestPaint()
    onPaint: {
        const c = getContext("2d"); c.reset(); c.scale(width/24,height/24)
        c.strokeStyle = stroke; c.fillStyle = stroke; c.lineWidth = 1.5; c.lineCap = "round"; c.lineJoin = "round"
        function line(x,y,a,b) { c.beginPath(); c.moveTo(x,y); c.lineTo(a,b); c.stroke() }
        if (name === "usage") {
            c.fillRect(3,12,3,9); c.fillRect(10,3,3,18); c.fillRect(17,8,3,13)
        } else if (name === "close") { line(6,6,18,18); line(18,6,6,18) }
        else if (name === "windows") {
            c.strokeRect(3,3,18,18); line(12,3,12,21); line(3,12,21,12)
        } else if (name === "refresh") {
            c.beginPath(); c.arc(12,12,8,0.5,5.7); c.stroke(); line(19,4,20,10); line(20,10,14,9)
        } else if (name === "appearance") {
            c.strokeRect(3,4,18,13); line(12,17,12,21); line(8,21,16,21)
        } else {
            c.beginPath();
            for (let i=0;i<32;i++) { let a=i*Math.PI/16; let r=i%4<2?9:7; let x=12+Math.cos(a)*r,y=12+Math.sin(a)*r; if(i===0)c.moveTo(x,y); else c.lineTo(x,y) }
            c.closePath(); c.stroke(); c.beginPath(); c.arc(12,12,3,0,Math.PI*2); c.stroke()
        }
    }
}
