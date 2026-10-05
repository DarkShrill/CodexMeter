import QtQuick
import QtQuick.Layouts
import "../components"

PreviewFrame {
    title: "QML Preview · TaskStatusBadge"

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 28

        Text {
            text: "Passa sul badge per il tooltip e clicca per aprire l'elenco."
            color: "#626971"
            font.family: "Poppins"
            font.pixelSize: 13
        }

        Repeater {
            model: [
                { label: "Nessun task", tasks: [] },
                { label: "Un task attivo", tasks: [
                    { title: "Creare la preview di TaskStatusBadge", state: "working" }
                ] },
                { label: "Stati e titoli lunghi", tasks: [
                    { title: "Analizzare i componenti del progetto", state: "thinking" },
                    { title: "Implementare una preview con un titolo molto lungo per verificare il ritorno a capo nell'elenco dei task", state: "working" },
                    { title: "Verificare le modifiche", state: "review" },
                    { title: "Scegliere la variante", state: "waiting" },
                    { title: "Riprovare la compilazione", state: "failed" }
                ] },
                { label: "Elenco con scorrimento", tasks: Array.from({ length: 12 }, function(_, index) {
                    return { title: "Task di esempio " + (index + 1), state: "working" }
                }) }
            ]

            delegate: RowLayout {
                id: scenario
                required property var modelData
                spacing: 24

                Text {
                    Layout.preferredWidth: 240
                    text: scenario.modelData.label
                    color: "#252A32"
                    font.family: "Poppins"
                    font.pixelSize: 14
                }

                TaskStatusBadge {
                    activity: ({ taskCount: scenario.modelData.tasks.length, activeTasks: scenario.modelData.tasks })
                }
            }
        }
    }
}
