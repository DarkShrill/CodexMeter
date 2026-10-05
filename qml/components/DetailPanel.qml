import QtQuick
import QtQuick.Controls
Rectangle {
    id: root
    required property var rateModel
    required property var client
    property string pointerSide: "left"
    signal settingsRequested()
    implicitWidth: 360; implicitHeight: 410
    radius: 12; color: "#FAFAFB"; border.color: "#D8DADD"
    Rectangle { visible: root.pointerSide !== "none"; width: 14; height: 14; rotation: 45; color: root.color; border.color: root.border.color; z: -1; x: root.pointerSide === "left" ? -7 : root.pointerSide === "right" ? root.width - 7 : 40; y: root.pointerSide === "top" ? -7 : 50 }
    LineIcon { x: 20; y: 20; stroke: "#0091FF" }
    Text { x: 51; y: 18; text: qsTr("Dettagli utilizzo"); font.family: "Poppins"; font.pixelSize: 18; color: "#252A32" }
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 12; y: 12; width: 32; height: 32; radius: 6; color: more.containsMouse ? "#ECEDEF" : "transparent"
        LineIcon { anchors.centerIn: parent; name: "settings"; width: 18; height: 18 }
        MouseArea { id: more; anchors.fill: parent; hoverEnabled: true; onClicked: root.settingsRequested() }
    }
    Rectangle { x: 0; y: 58; width: parent.width; height: 1; color: "#E1E3E6" }
    ListView {
        x: 20; y: 74; width: parent.width - 40; height: parent.height - 130
        clip: true; spacing: 3; model: root.rateModel; interactive: contentHeight > height
        delegate: LimitRow {
            required property string limitName
            required property string limitId
            required property string bucket
            readonly property string displayBucket: model.displayBucket || ""
            required property int remainingPercent
            required property var model
            resetText: model.resetText
            width: ListView.view.width; height: 86
            limitTitle: model.isReserve || (limitId + " " + limitName).toLowerCase().indexOf("reserve") >= 0 ? qsTr("Reserve") : ((limitName || "Codex") + " - " + (displayBucket || (bucket === "5h" ? qsTr("5 ore") : (bucket === "Week" ? qsTr("Settimanale") : bucket))))
            percent: remainingPercent; accent: "#0091FF"
        }
    }
    Rectangle { x: 20; width: parent.width - 40; height: 1; y: parent.height - 48; color: "#E1E3E6" }
    Text {
        x: 20; y: parent.height - 32; width: parent.width - 40
        text: root.client.lastError.length ? root.client.lastError : qsTr("Aggiornato %1").arg(root.client.lastUpdated ? Qt.formatDateTime(root.client.lastUpdated,"HH:mm:ss") : "--:--:--")
        color: root.client.lastError.length ? "#B44E4E" : "#777D85"; font.family: "Poppins"; font.pixelSize: 12; elide: Text.ElideRight
    }
}
