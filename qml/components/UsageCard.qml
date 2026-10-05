import QtQuick
Rectangle {
    id: root
    required property var rateModel
    property int cardStyle: 1
    property bool allLimits: false
    property int revision: 0
    property color accent: "#0091FF"
    readonly property var primary: { revision; return rateModel.count ? rateModel.get(0) : ({remainingPercent: 0, bucket: "5h", resetText: ""}) }
    function usageColor(percent) {
        if (percent < 10) return "#D9534F"
        if (percent < 35) return "#F0A020"
        return accent
    }
    function label(row) {
        if (row.isReserve || ((row.limitId || "") + " " + (row.limitName || "")).toLowerCase().indexOf("reserve") >= 0) return qsTr("Reserve")
        return row.displayBucket || (row.bucket === "5h" ? qsTr("5 ore") : (row.bucket === "Week" ? qsTr("Settimanale") : row.bucket))
    }
    property double nowSeconds: Date.now()/1000
    Timer { interval: 30000; running: root.visible; repeat: true; onTriggered: root.nowSeconds = Date.now()/1000 }
    function resetLabel(row) {
        if (!row.resetTimestamp) return row.resetText ? qsTr("Reset %1").arg(row.resetText) : qsTr("Reset non disponibile")
        const minutes = Math.max(0, Math.ceil((row.resetTimestamp - nowSeconds)/60))
        if (minutes === 0) return qsTr("Reset in corso")
        const days = Math.floor(minutes/1440), hours = Math.floor((minutes%1440)/60), mins = minutes%60
        const parts = []
        if (days) parts.push(qsTr("%1 g").arg(days))
        if (hours) parts.push(qsTr("%1 h").arg(hours))
        if (mins || !hours && !days) parts.push(qsTr("%1 min").arg(mins))
        return qsTr("Reset tra %1").arg(parts.join(" "))
    }
    implicitWidth: cardStyle === 0 ? 200 : (cardStyle === 1 ? 330 : 240)
    implicitHeight: cardStyle === 2 ? 286 : (allLimits ? 242 : 146)
    radius: 12; color: "#FAFAFB"; border.color: "#D8DADD"
    signal settingsRequested()
    signal bodyClicked()
    Connections {
        target: root.rateModel; ignoreUnknownSignals: true
        function onModelReset() { root.revision++ }
        function onDataChanged() { root.revision++ }
    }
    MouseArea { anchors.fill: parent; onClicked: root.bodyClicked() }
    LineIcon { x: 16; y: 17; width: 19; height: 19; stroke: root.accent }
    Text { x: 44; y: 16; text: "Codex"; color: "#252A32"; font.family: "Poppins"; font.pixelSize: 16 }
    Rectangle {
        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
        width: 30; height: 30; radius: 6; color: more.containsMouse ? "#ECEDEF" : "transparent"
        LineIcon { anchors.centerIn: parent; width: 18; height: 18; name: "settings" }
        MouseArea { id: more; anchors.fill: parent; hoverEnabled: true; onClicked: root.settingsRequested() }
    }
    Column {
        x: 16; y: 62
        width: root.cardStyle === 1 ? root.width - 130 : root.width - 32
        spacing: root.cardStyle === 2 ? 24 : 14
        Repeater {
            model: Math.min(root.cardStyle === 2 || root.allLimits ? 3 : 1, root.rateModel.count)
            delegate: Item {
                id: entry
                required property int index
                readonly property var row: { root.revision; return root.rateModel.get(index) }
                width: parent.width; height: 34
                Text { width: parent.width - 48; text: root.label(entry.row); elide: Text.ElideRight; color: "#252A32"; font.family: "Poppins"; font.pixelSize: 14 }
                Text { anchors.right: parent.right; text: entry.row.remainingPercent + "%"; color: "#252A32"; font.family: "Poppins"; font.pixelSize: 14 }
                Rectangle {
                    y: 24; width: parent.width; height: 7; radius: 3.5; color: "#E1E3E5"
                    Rectangle { height: parent.height; width: parent.width * Math.max(0,Math.min(100,entry.row.remainingPercent))/100; radius: 3.5; color: root.usageColor(entry.row.remainingPercent) }
                }
            }
        }
        Text { visible: !root.rateModel.count; text: qsTr("In attesa di dati"); font.family: "Poppins"; font.pixelSize: 13; color: "#777D85" }
    }
    Item {
        visible: root.cardStyle === 1
        width: 86; height: 86; anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 16
        RingArc { anchors.fill: parent; thickness: 7; progress: root.primary.remainingPercent/100; progressColor: root.usageColor(root.primary.remainingPercent); trackColor: "#E1E3E5" }
        Text { anchors.centerIn: parent; text: root.rateModel.count ? root.primary.remainingPercent + "%" : "--"; color: "#252A32"; font.family: "Poppins"; font.pixelSize: 20 }
    }
    Rectangle { visible: root.cardStyle === 2; x: 16; width: parent.width - 32; height: 1; y: parent.height - 49; color: "#E1E3E5" }
    Text {
        x: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 17
        width: root.cardStyle === 1 ? parent.width - 130 : parent.width - 32
        text: root.resetLabel(root.primary)
        elide: Text.ElideRight; color: "#717780"; font.family: "Poppins"; font.pixelSize: 12
    }
}
