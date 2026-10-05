import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    title: qsTr("Prova animazioni")
    modal: true
    width: 450
    anchors.centerIn: parent
    padding: 24
    topPadding: 0
    bottomPadding: 0
    font.family: "Poppins"
    font.pixelSize: 13
    background: Rectangle {
        color: "#FAFAFB"
        radius: 10
        border.color: "#D9DCDF"
    }
    header: Item {
        implicitHeight: 72
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: "#252A32"
            font.family: "Poppins"
            font.pixelSize: 19
            font.weight: Font.DemiBold
        }
    }
    property int petExpression: 5
    readonly property var customPet: petExpression >= 1000 ? petLibrary.pet(petExpression) : ({})
    property url resourceRoot: petExpression === 0 ? "qrc:/assets/kira/frames/"
        : petExpression === 1 ? "qrc:/assets/darkshrill/frames/"
        : petExpression === 9 ? "qrc:/assets/goku/frames/"
        : petExpression === 7 ? "qrc:/assets/dario/frames/"
        : petExpression === 8 ? "qrc:/assets/doraemon/frames/"
        : petExpression === 10 ? "qrc:/assets/mini-elon/frames/"
        : petExpression === 6 ? "qrc:/assets/clippit/frames/"
        : petExpression >= 1000 ? customPet.resourceRoot
        : petExpression === 5 ? "qrc:/assets/pip/" : "qrc:/assets/mascot/"
    property int previewIndex: 0
    property bool testingAll: false
    property bool previewPlaying: false
    property string statusSource: "initial"
    readonly property string statusText: statusSource === "playing"
        ? qsTr("In riproduzione: %1").arg(choices[previewIndex].label)
        : statusSource === "finished" ? qsTr("Animazione terminata.")
        : statusSource === "allFinished" ? qsTr("Tutte le animazioni sono state provate.")
        : statusSource === "stopped" ? qsTr("Prova interrotta.")
        : qsTr("Scegli un'animazione oppure provale tutte.")
    readonly property var choices: petExpression !== 4 ? [
        {name:"idle", label:qsTr("Riposo")}, {name:"running-right", label:qsTr("Corsa destra")},
        {name:"running-left", label:qsTr("Corsa sinistra")}, {name:"waving", label:qsTr("Saluto")},
        {name:"completed", label:qsTr("Salto / completamento")}, {name:"failed", label:qsTr("Errore")},
        {name:"waiting", label:qsTr("Attesa di input")}, {name:"working", label:qsTr("Lavoro")},
        {name:"review", label:qsTr("Revisione")}
    ] : petExpression === 4 ? [
        {name:"idle",label:qsTr("Riposo")}, {name:"thinking",label:qsTr("Pensiero")},
        {name:"happy",label:qsTr("Felice")}, {name:"warning",label:qsTr("Avviso")},
        {name:"critical",label:qsTr("Errore")}, {name:"blink",label:qsTr("Blink")}
    ] : [{name:"idle",label:qsTr("Respiro")},{name:"working",label:qsTr("Lavoro")},{name:"completed",label:qsTr("Salto")}]
    readonly property string animationName: choices[Math.min(previewIndex, choices.length - 1)].name
    function play(index, all) {
        next.stop()
        testingAll = all
        previewPlaying = true
        previewIndex = index
        statusSource = "playing"
        if (sprite.item) sprite.item.restartAnimation()

    }
    function finished() {
        if (testingAll) next.restart()
        else statusSource = "finished"
    }
    onOpened: { previewIndex = 0; testingAll = false; previewPlaying = false; statusSource = "initial" }
    onClosed: { testingAll = false; previewPlaying = false; next.stop() }
    onPetExpressionChanged: { testingAll = false; previewPlaying = false; next.stop(); previewIndex = 0 }
    Timer {
        id: next
        interval: 300
        onTriggered: {
            if (root.previewIndex + 1 < root.choices.length) root.play(root.previewIndex + 1, true)
            else { root.testingAll = false; root.statusSource = "allFinished" }
        }
    }
    contentItem: ColumnLayout {
        spacing: 12
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            radius: 7
            color: "#F1F2F3"
            border.color: "#E1E3E6"
            Loader {
                id: sprite
                anchors.centerIn: parent
                width: 192; height: 208
                active: root.visible
                sourceComponent: root.petExpression >= 1000 ? custom : root.petExpression === 10 ? miniElon : root.petExpression === 8 ? doraemon : root.petExpression === 9 ? goku : root.petExpression === 7 ? dario : root.petExpression === 6 ? clippit : root.petExpression !== 4 ? pip : germoglio
            }
            Component { id: goku; GokuMascot { resourceRoot: root.resourceRoot; state: root.animationName; playing: root.visible && root.previewPlaying } }
            Component { id: dario; DarioMascot { resourceRoot: root.resourceRoot; state: root.animationName; playing: root.visible && root.previewPlaying } }
            Component { id: doraemon; DoraemonMascot { resourceRoot: root.resourceRoot; state: root.animationName; playing: root.visible && root.previewPlaying } }
            Component { id: miniElon; MiniElonMascot { resourceRoot: root.resourceRoot; state: root.animationName; playing: root.visible && root.previewPlaying } }
            Component { id: clippit; ClippitMascot { resourceRoot: root.resourceRoot; state: root.animationName; playing: root.visible && root.previewPlaying } }
            Component { id: pip; PipMascot { resourceRoot: root.resourceRoot; state: root.animationName; playing: root.visible && root.previewPlaying } }
            Component { id: custom; Mascot { resourceRoot: root.resourceRoot; animations: root.customPet.animations || ({}); state: root.animationName; playing: root.visible && root.previewPlaying; floatMotion: false; occasionalAnimations: [] } }
            Component { id: germoglio; Mascot { resourceRoot: root.resourceRoot; state: root.animationName; playing: root.visible && root.previewPlaying; occasionalAnimations: [] } }

        }
        Label {
            text: qsTr("Animazione")
            color: "#252A32"
            font.family: "Poppins"
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
        ComboBox {
            id: animationChoice
            Layout.fillWidth: true
            implicitHeight: 38
            leftPadding: 12
            rightPadding: 36
            model: root.choices
            textRole: "label"
            currentIndex: root.previewIndex
            enabled: !root.testingAll
            onActivated: root.play(currentIndex, false)
            font.family: "Poppins"
            font.pixelSize: 13
            contentItem: Text {
                text: animationChoice.displayText
                font: animationChoice.font
                color: animationChoice.enabled ? "#3D454D" : "#A8ADB3"
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            background: Rectangle {
                radius: 7
                color: animationChoice.enabled ? "#FAFAFB" : "#ECEDEF"
                border.color: animationChoice.activeFocus ? "#0091FF" : "#D9DCDF"
            }
            indicator: Canvas {
                x: animationChoice.width - width - 14
                y: (animationChoice.height - height) / 2
                width: 10; height: 6
                opacity: animationChoice.enabled ? 1 : 0.4
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = "#626971"
                    ctx.lineWidth = 1.5
                    ctx.beginPath()
                    ctx.moveTo(1, 1); ctx.lineTo(5, 5); ctx.lineTo(9, 1)
                    ctx.stroke()
                }
            }
            delegate: ItemDelegate {
                required property int index
                required property var modelData
                width: animationChoice.width - 2
                height: 38
                highlighted: animationChoice.highlightedIndex === index
                contentItem: Text {
                    text: modelData.label
                    font: animationChoice.font
                    color: "#3D454D"
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    radius: 5
                    color: parent.highlighted ? "#E5EEEE" : "transparent"
                }
            }
            popup: Popup {
                y: animationChoice.height + 4
                width: animationChoice.width
                padding: 1
                implicitHeight: contentItem.implicitHeight + 2
                background: Rectangle { color: "#FAFAFB"; radius: 7; border.color: "#D9DCDF" }
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: animationChoice.popup.visible ? animationChoice.delegateModel : null
                    currentIndex: animationChoice.highlightedIndex
                    ScrollIndicator.vertical: ScrollIndicator {}
                }
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.minimumHeight: 40
            text: root.statusText
            wrapMode: Text.WordWrap
            color: "#777D85"
            font.family: "Poppins"
            font.pixelSize: 12
        }
    }
    footer: Item {
        implicitHeight: 72
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            spacing: 10
            SettingsButton { text: qsTr("Riproduci"); primary: true; enabled: !root.testingAll; onClicked: root.play(root.previewIndex, false) }
            SettingsButton { text: root.testingAll ? qsTr("Ferma") : qsTr("Prova tutte"); onClicked: { if (root.testingAll) { root.testingAll = false; root.previewPlaying = false; next.stop(); root.statusSource = "stopped" } else root.play(0, true) } }
            Item { Layout.fillWidth: true }
            SettingsButton { text: qsTr("Chiudi"); onClicked: root.close() }
        }
    }
    Connections { target: sprite.item; ignoreUnknownSignals: true; function onAnimationFinished(name) { root.finished() } }
}
