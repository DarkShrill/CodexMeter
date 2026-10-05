import QtQuick
import QtTest
import "../../qml/components"
import "../../qml/previews"

// Production PetView on a fictional desktop. No real sessions or account data.
TestCase {
    id: capture
    name: "ReadmePetDemo"
    when: windowShown
    visible: true
    width: 960
    height: 600
    property int scene: 0
    readonly property var scenes: [
        {state: "idle", title: "Pronto, sul tuo desktop", app: "Desktop", detail: "La quota resta a portata di sguardo.", percent: 82},
        {state: "working", title: "Mentre Codex scrive codice", app: "Editor · dashboard.ts", detail: "Il pet si anima mentre la chat lavora.", percent: 79},
        {state: "review", title: "Durante la revisione", app: "Browser · Anteprima dashboard", detail: "Controlli il risultato, Codex rivede le modifiche.", percent: 76},
        {state: "waiting", title: "Quando serve il tuo input", app: "Codex · Aggiornare la dashboard", detail: "Una scelta da confermare: il pet entra in attesa.", percent: 76},
        {state: "working", title: "Mentre girano i test", app: "Terminale · Verifica del progetto", detail: "Continui a lavorare con la quota sempre visibile.", percent: 73},
        {state: "completed", title: "Al completamento del task", app: "Codex · Aggiornare la dashboard", detail: "Lavoro concluso: il pet festeggia.", percent: 72},
        {state: "failed", title: "Se qualcosa si interrompe", app: "Terminale · Verifica del progetto", detail: "Anche un errore ha la sua reazione.", percent: 72},
        {state: "idle", pet: 1, title: "Scegli chi ti accompagna", app: "Impostazioni · Aspetto · Pet", detail: "Puoi cambiare mascotte mentre lavori.", percent: 72},
        {state: "working", pet: 10, title: "Un cambio di pet: Mini Elon", app: "Impostazioni · Aspetto · Pet", detail: "Selezioni Mini Elon: il widget cambia subito.", percent: 72},
        {state: "working", pet: 7, title: "E poi arriva Dario", app: "Impostazioni · Aspetto · Pet", detail: "Stesse quote e attività, un nuovo compagno sul desktop.", percent: 72}
    ]
    readonly property var current: scenes[scene]
    PreviewData { id: data }
    readonly property int selectedPet: data.settings.petExpression
    QtObject {
        id: activity
        property string state: capture.current.state
        property bool working: state === "working" || state === "review"
        property int taskCount: state === "idle" || state === "completed" || state === "failed" ? 0 : 1
        property var activeTasks: taskCount ? [{id: "demo", title: "Aggiornare la dashboard", state: state}] : []
    }
    Rectangle {
        id: desktop
        anchors.fill: parent
        color: "#15263B"
        gradient: Gradient {
            GradientStop { position: 0; color: "#122237" }
            GradientStop { position: 1; color: "#294E65" }
        }
        Text { x: 32; y: 22; text: "Codex Meter"; color: "#A9CCDA"; font.family: "Poppins"; font.pixelSize: 13; font.weight: Font.Medium }
        Text { x: 32; y: 49; text: capture.current.title; color: "#FFFFFF"; font.family: "Poppins"; font.pixelSize: 26; font.weight: Font.DemiBold }
        Text { x: 32; y: 91; text: capture.current.detail; color: "#C1D1DE"; font.family: "Poppins"; font.pixelSize: 14 }
        Rectangle {
            x: 32; y: 144; width: 572; height: 352; radius: 12
            color: "#17202D"; border.color: "#42536A"
            Rectangle { width: parent.width - 2; height: 40; x: 1; y: 1; radius: 11; color: "#273346" }
            Text { x: 17; y: 12; text: capture.current.app; color: "#DBE5EF"; font.family: "Poppins"; font.pixelSize: 12 }
            Rectangle { x: 493; y: 20; width: 10; height: 1; color: "#9AAABE" }
            Rectangle { x: 520; y: 15; width: 10; height: 10; color: "transparent"; border.color: "#9AAABE" }
            LineIcon { x: 544; y: 12; width: 16; height: 16; name: "close"; stroke: "#9AAABE" }
            Item {
                x: 22; y: 61; width: 528; height: 269
                visible: capture.scene === 0
                Text { y: 15; text: "Uno spazio per lavorare"; color: "#EFF5FA"; font.family: "Poppins"; font.pixelSize: 23 }
                Text { y: 60; text: "Editor, browser, terminale.\nIl pet ti accompagna tra le finestre."; lineHeight: 1.5; color: "#A6B8CB"; font.family: "Poppins"; font.pixelSize: 15 }
                Row {
                    y: 153; spacing: 14
                    Repeater {
                        model: ["Progetto", "Anteprima", "Terminale"]
                        Rectangle {
                            required property string modelData
                            width: 150; height: 74; radius: 9; color: "#25374A"
                            Text { anchors.centerIn: parent; text: parent.modelData; font.family: "Poppins"; font.pixelSize: 13; color: "#A9D6E3" }
                        }
                    }
                }
            }
            Text {
                x: 22; y: 62; color: "#B9D7E6"; font.family: "Poppins"; font.pixelSize: 16; lineHeight: 1.55
                visible: capture.scene === 1
                text: "01  import { loadUsage } from './api';\n02\n03  export async function dashboard() {\n04    const usage = await loadUsage();\n05    return {\n06      remaining: usage.remaining,\n07      resetAt: usage.resetAt\n08    };\n09  }"
            }
            Item {
                x: 22; y: 60; width: 528; height: 265; visible: capture.scene === 2
                Rectangle { width: parent.width; height: 28; radius: 5; color: "#324054"; Text { x: 12; y: 5; text: "localhost:3000/dashboard"; color: "#A9BDCE"; font.family: "Poppins"; font.pixelSize: 13 } }
                Text { y: 51; text: "La tua dashboard"; color: "#FFFFFF"; font.family: "Poppins"; font.pixelSize: 21 }
                Row {
                    y: 104; spacing: 16
                    Repeater {
                        model: ["Progetti\n12", "Task conclusi\n48", "Test superati\n24"]
                        Rectangle {
                            required property string modelData
                            width: 165; height: 99; radius: 9; color: "#263E4F"
                            Text { anchors.centerIn: parent; text: parent.modelData; lineHeight: 1.7; horizontalAlignment: Text.AlignHCenter; color: "#BCE8E3"; font.family: "Poppins"; font.pixelSize: 17 }
                        }
                    }
                }
                Text { y: 225; text: "Codex sta rivedendo le modifiche…"; color: "#A7BECD"; font.family: "Poppins"; font.pixelSize: 13 }
            }
            Item {
                x: 22; y: 66; width: 528; height: 260; visible: capture.scene === 3 || capture.scene === 5
                Text { text: capture.scene === 3 ? "Aggiornare la dashboard" : "Modifiche completate"; color: "#FFFFFF"; font.family: "Poppins"; font.pixelSize: 21 }
                Text { y: 49; text: capture.scene === 3 ? "Vuoi includere anche il riepilogo settimanale?" : "Dashboard aggiornata e verificata.\n24 test superati. Tutto pronto per la revisione."; lineHeight: 1.6; color: "#B4C9D7"; font.family: "Poppins"; font.pixelSize: 15 }
                Rectangle {
                    y: 145; width: 284; height: 44; radius: 8; color: capture.scene === 3 ? "#385E7A" : "#255B52"
                    Text { anchors.centerIn: parent; text: capture.scene === 3 ? "In attesa della tua risposta" : "Task completato"; color: "#E0F5F0"; font.family: "Poppins"; font.pixelSize: 14 }
                }
            }
            Text {
                x: 22; y: 65; visible: capture.scene === 4 || capture.scene === 6
                text: capture.scene === 4 ? "> npm test\n\n RUN  dashboard.test.ts\n OK  caricamento quote\n OK  calcolo percentuali\n OK  orari di reset\n\n Verifica delle interazioni…" : "> npm test\n\n OK  23 test superati\n ERRORE  connessione al servizio\n\n Error: servizio non raggiungibile\n\n Controlla la connessione e riprova."
                color: capture.scene === 6 ? "#E6A9AB" : "#A8DEC5"; font.family: "Poppins"; font.pixelSize: 16; lineHeight: 1.5
            }
            Item {
                x: 22; y: 62; width: 528; height: 269; visible: capture.scene >= 7
                Text { text: "Pet / espressione"; font.family: "Poppins"; font.pixelSize: 21; color: "#FFFFFF" }
                Text { y: 39; text: "Scegli una mascotte dalla raccolta"; font.family: "Poppins"; font.pixelSize: 14; color: "#B4C9D7" }
                Row {
                    y: 80; spacing: 12
                    Repeater {
                        model: [
                            {name: "DarkShrill", pet: 1, resource: "darkshrill"},
                            {name: "Mini Elon", pet: 10, resource: "mini-elon"},
                            {name: "Dario", pet: 7, resource: "dario"}
                        ]
                        Rectangle {
                            required property var modelData
                            readonly property bool selected: capture.selectedPet === modelData.pet
                            width: 168; height: 153; radius: 9
                            color: selected ? "#28576B" : "#25374A"
                            border.color: selected ? "#91DADE" : "#42536A"
                            border.width: selected ? 2 : 1
                            Image {
                                x: 38; y: 6; width: 92; height: 96
                                source: "qrc:/assets/" + parent.modelData.resource + "/frames/idle/00.png"
                                fillMode: Image.PreserveAspectFit; smooth: true
                            }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 107; text: parent.modelData.name; font.family: "Poppins"; font.pixelSize: 14; color: "#EFF5FA" }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 129; text: parent.selected ? "Selezionato" : "Disponibile"; font.family: "Poppins"; font.pixelSize: 10; color: parent.selected ? "#91DADE" : "#9EAFBE" }
                        }
                    }
                }
            }
        }
        PetView {
            id: pet
            x: 632; y: 191; width: implicitWidth; height: implicitHeight
            rateModel: data.rateModel; settings: data.settings; activity: activity
        }
        Row {
            x: 32; y: 518; spacing: 8
            Repeater {
                model: capture.scenes.length
                Rectangle { required property int index; width: index === capture.scene ? 30 : 8; height: 8; radius: 4; color: index === capture.scene ? "#91DADE" : "#536F85" }
            }
        }
        Text { x: 618; y: 512; text: "Widget reale · desktop e dati simulati"; color: "#ACC5D5"; font.family: "Poppins"; font.pixelSize: 11 }
        Rectangle {
            y: 550; width: parent.width; height: 50; color: "#142033"
            Row {
                anchors.centerIn: parent; spacing: 13
                Repeater {
                    model: ["windows", "appearance", "usage", "refresh", "settings"]
                    Rectangle {
                        required property string modelData
                        width: 34; height: 32; radius: 5; color: "#273D52"
                        LineIcon { anchors.centerIn: parent; width: 22; height: 22; name: parent.modelData; stroke: "#C0DAE6" }
                    }
                }
            }
            Text { x: 869; y: 8; text: "10:24\n05/10/2026"; color: "#C2D1DE"; font.family: "Poppins"; font.pixelSize: 11; horizontalAlignment: Text.AlignRight }
        }
    }
    function test_capture() {
        data.settings.petExpression = 1
        data.settings.petInfoStyle = "bubble"
        data.settings.petAnimated = true
        wait(300)
        let frame = 0
        for (let s = 0; s < scenes.length; ++s) {
            scene = s
            data.settings.petExpression = current.pet === undefined ? 1 : current.pet
            data.rateModel.setProperty(0, "remainingPercent", current.percent)
            // Each state plays once, matching production behavior.
            for (let i = 0; i < 32; ++i) {
                wait(80)
                const shot = grabImage(desktop)
                compare(shot.width, 960)
                compare(shot.height, 600)
                shot.save(Qt.resolvedUrl("../../build/docs-capture/pet-frames/frame-" + String(frame).padStart(4, "0") + ".png").toString().replace("file:///", ""))
                ++frame
            }
        }
    }
}
