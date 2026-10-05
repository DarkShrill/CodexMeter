import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import "components"
ApplicationWindow {
    id: root
    required property var settings
    required property var client
    property var rateModel: null
    property int pageIndex: 0
    property string importMessage: ""
    width: 860; height: 710; minimumWidth: 800; minimumHeight: 600
    visible: false; title: qsTr("Codex Meter - Impostazioni"); color: "#FAFAFB"
    font.family: "Poppins"; font.pixelSize: 14
    PetAnimationPreview {
        id: animationPreview
        petExpression: root.settings.petExpression
    }
    PetLayoutPreview {
        id: layoutPreview
        settings: root.settings
        rateModel: root.rateModel
        client: root.client
    }
    Connections {
        target: root.settings
        function onPetAnimatedChanged() { if (!root.settings.petAnimated) animationPreview.close() }
        function onViewModeChanged() {
            if (root.settings.viewMode !== "pet") { animationPreview.close(); layoutPreview.close() }
        }
    }
    Connections {
        target: petLibrary
        function onImportFinished(success, message) {
            root.importMessage = message
            if (success)
                root.settings.petExpression = petLibrary.lastImportedPetId
            importFeedback.open()
        }
    }
    Dialog {
        id: importSourceDialog
        title: qsTr("Aggiungi un pet")
        modal: true
        width: 460
        anchors.centerIn: parent
        padding: 0
        background: Rectangle {
            color: "#FAFAFB"
            radius: 10
            border.color: "#D9DCDF"
            border.width: 1
        }
        header: Rectangle {
            implicitHeight: 62
            color: "transparent"
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                text: importSourceDialog.title
                color: "#252A32"
                font.family: "Poppins"
                font.pixelSize: 19
                font.weight: Font.DemiBold
            }
        }
        contentItem: ColumnLayout {
            width: 460
            spacing: 18
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                wrapMode: Text.WordWrap
                text: qsTr("Scegli una cartella del pet oppure un archivio ZIP con frames-manifest.json e le sequenze PNG.")
                color: "#555C65"
                font.family: "Poppins"
                font.pixelSize: 14
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                spacing: 12
                Button {
                    id: chooseFolderButton
                    text: qsTr("Scegli cartella…")
                    onClicked: { importSourceDialog.close(); folderPicker.open() }
                    contentItem: Text {
                        text: chooseFolderButton.text
                        font.family: "Poppins"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        implicitWidth: 164
                        implicitHeight: 38
                        radius: 7
                        color: chooseFolderButton.down ? "#0078D4" : chooseFolderButton.hovered ? "#0086EB" : "#0091FF"
                    }
                }
                Button {
                    id: chooseZipButton
                    text: qsTr("Scegli ZIP…")
                    onClicked: { importSourceDialog.close(); zipPicker.open() }
                    contentItem: Text {
                        text: chooseZipButton.text
                        font.family: "Poppins"
                        font.pixelSize: 13
                        color: "#3D454D"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        implicitWidth: 118
                        implicitHeight: 38
                        radius: 7
                        color: chooseZipButton.down ? "#E5E8EA" : chooseZipButton.hovered ? "#F1F3F4" : "#FAFAFB"
                        border.color: "#D9DCDF"
                    }
                }
            }
            Item { Layout.fillHeight: true; implicitHeight: 4 }
        }
        footer: Item {
            implicitHeight: 68
            Button {
                id: cancelImportButton
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Annulla")
                onClicked: importSourceDialog.close()
                contentItem: Text {
                    text: cancelImportButton.text
                    font.family: "Poppins"
                    font.pixelSize: 13
                    color: "#555C65"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitWidth: 92
                    implicitHeight: 36
                    radius: 7
                    color: cancelImportButton.down ? "#E5E8EA" : cancelImportButton.hovered ? "#F1F3F4" : "transparent"
                    border.color: "#D9DCDF"
                }
            }
        }
    }
    FolderDialog {
        id: folderPicker
        title: qsTr("Seleziona la cartella del pet")
        onAccepted: petLibrary.importPackage(selectedFolder.toString())
    }
    FileDialog {
        id: zipPicker
        title: qsTr("Seleziona il pacchetto ZIP")
        nameFilters: [qsTr("Pacchetto pet (*.zip)")]
        onAccepted: petLibrary.importPackage(selectedFile.toString())
    }
    Dialog {
        id: importFeedback
        title: qsTr("Pacchetto pet")
        modal: true
        width: 420
        anchors.centerIn: parent
        padding: 0
        background: Rectangle { color: "#FAFAFB"; radius: 10; border.color: "#D9DCDF" }
        header: Rectangle {
            implicitHeight: 62
            color: "transparent"
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                text: importFeedback.title
                color: "#252A32"
                font.family: "Poppins"
                font.pixelSize: 19
                font.weight: Font.DemiBold
            }
        }
        contentItem: ColumnLayout {
            width: 420
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                wrapMode: Text.WordWrap
                text: root.importMessage
                color: "#555C65"
                font.family: "Poppins"
                font.pixelSize: 14
            }
            Item { Layout.fillHeight: true; implicitHeight: 12 }
        }
        footer: Item {
            implicitHeight: 68
            Button {
                id: feedbackOkButton
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: "OK"
                onClicked: importFeedback.close()
                contentItem: Text {
                    text: feedbackOkButton.text
                    font.family: "Poppins"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitWidth: 82
                    implicitHeight: 36
                    radius: 7
                    color: feedbackOkButton.down ? "#0078D4" : feedbackOkButton.hovered ? "#0086EB" : "#0091FF"
                }
            }
        }
    }
    Rectangle {
        id: sidebar; width: 196; height: parent.height; color: "#F1F2F3"
        Rectangle { anchors.right: parent.right; height: parent.height; width: 1; color: "#E1E3E6" }
        Row {
            x: 22; y: 25; spacing: 10
            LineIcon { name: "usage"; stroke: "#0091FF" }
            Text { text: "Codex Meter"; font.family: "Poppins"; font.pixelSize: 16; color: "#252A32" }
        }
        Column {
            x: 12; y: 83; width: parent.width - 24; spacing: 8
            Repeater {
                model: [qsTr("Aspetto"), qsTr("Aggiornamento"), "Windows"]
                delegate: SidebarButton {
                    required property int index
                    required property string modelData
                    width: parent.width; text: modelData; iconName: ["appearance", "refresh", "windows"][index]
                    selected: root.pageIndex === index; onClicked: root.pageIndex = index
                }
            }
        }
    }
    ScrollView {
        id: scroll

        anchors.left: sidebar.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        anchors.leftMargin: 32
        anchors.rightMargin: 32
        anchors.topMargin: 28
        anchors.bottomMargin: 24

        contentWidth: availableWidth
        clip: true

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
            parent: root.contentItem
            anchors.left: scroll.right
            anchors.top: scroll.top
            anchors.bottom: scroll.bottom
            width: 6
            onPressedChanged: if (pressed) wheelScroll.stop()


            background: Item {}
        }

        Flickable {
            id: settingsFlickable
            contentWidth: width
            contentHeight: settingsContent.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            boundsMovement: Flickable.StopAtBounds
            clip: true
            onDraggingChanged: if (dragging) wheelScroll.stop()
            onContentHeightChanged: {
                wheelScroll.stop()
                returnToBounds()
            }
            onHeightChanged: {
                wheelScroll.stop()
                returnToBounds()
            }

            NumberAnimation {
                id: wheelScroll
                target: settingsFlickable
                property: "contentY"
                duration: 160
                easing.type: Easing.OutCubic
            }

            WheelHandler {
                target: null
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                acceptedModifiers: Qt.NoModifier
                onWheel: function(event) {
                    const delta = event.pixelDelta.y !== 0
                        ? event.pixelDelta.y : event.angleDelta.y / 120 * 64
                    if (delta === 0)
                        return
                    const minimum = settingsFlickable.originY
                    const maximum = minimum + Math.max(0,
                        settingsFlickable.contentHeight - settingsFlickable.height)
                    // Accumulate fast wheel ticks, but reverse direction immediately.
                    const current = settingsFlickable.contentY
                    const base = wheelScroll.running && (wheelScroll.to - current) * delta < 0
                        ? wheelScroll.to : current
                    const destination = Math.max(minimum, Math.min(maximum, base - delta))
                    wheelScroll.stop()
                    settingsFlickable.cancelFlick()
                    if (event.pixelDelta.y !== 0) {
                        settingsFlickable.contentY = destination
                    } else {
                        wheelScroll.from = current
                        wheelScroll.to = destination
                        wheelScroll.start()
                    }
                    event.accepted = true
                }
            }

            Column {
                id: settingsContent
                width: settingsFlickable.width - 12
                spacing: 0
                Text { text: [qsTr("Aspetto"), qsTr("Aggiornamento"), "Windows"][root.pageIndex]; font.family: "Poppins"; font.pixelSize: 26; font.weight: Font.DemiBold; color: "#252A32"; height: 62 }
                Column {
                    width: parent.width; visible: root.pageIndex === 0
                    SettingRow {
                        width: parent.width; title: qsTr("Widget"); height: 76
                        Rectangle {
                            Layout.fillWidth: true; height: 38; radius: 7; color: "#ECEDEF"; border.color: "#D9DCDF"
                            Row {
                                anchors.fill: parent; anchors.margins: 3
                                Repeater {
                                    model: [qsTr("Compatto"), qsTr("3 limiti"), qsTr("Pet")]
                                    delegate: Rectangle {
                                        required property int index; required property string modelData
                                        readonly property string value: ["compact", "pill", "pet"][index]
                                        width: parent.width/3; height: parent.height; radius: 5
                                        color: root.settings.viewMode === value ? "#51565D" : "transparent"
                                        Text { anchors.centerIn: parent; text: parent.modelData; font.family: "Poppins"; font.pixelSize: 13; color: root.settings.viewMode === parent.value ? "white" : "#555C65" }
                                        MouseArea { anchors.fill: parent; onClicked: root.settings.viewMode = parent.value }
                                    }
                                }
                            }
                        }
                    }
                    SettingRow {
                        width: parent.width; title: qsTr("Formato"); height: 142; visible: root.settings.viewMode !== "pet"
                        Repeater {
                            model: [qsTr("Mini"), qsTr("Anello"), qsTr("Monitor")]
                            delegate: Column {
                                required property int index; required property string modelData
                                Layout.fillWidth: true; Layout.preferredWidth: 100; spacing: 8
                                Rectangle {
                                    width: parent.width; height: 88; radius: 7; color: "#F5F6F7"
                                    border.color: root.settings.cardStyle === parent.index ? "#51565D" : "#D9DCDF"
                                    border.width: root.settings.cardStyle === parent.index ? 2 : 1
                                    Item {
                                        anchors.centerIn: parent; width: 56; height: 56
                                        Rectangle { anchors.fill: parent; radius: 6; color: "#FAFAFB"; border.color: "#DCDFE2" }
                                        LineIcon { x: 8; y: 8; width: 10; height: 10; stroke: "#0091FF" }
                                        Text { x: 22; y: 7; text: "Codex"; font.pixelSize: 8; font.family: "Poppins"; color: "#252A32" }
                                        Column {
                                            visible: index !== 1; x: 8; y: 27; spacing: 5
                                            Repeater { model: index === 2 ? 3 : 1; Rectangle { width: 40; height: 4; radius: 2; color: "#0091FF" } }
                                        }
                                        RingArc { visible: index === 1; x: 17; y: 22; width: 28; height: 28; thickness: 3; progress: 0.83; progressColor: "#0091FF"; trackColor: "#E1E3E5" }
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: root.settings.cardStyle = index }
                                }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.modelData; font.family: "Poppins"; font.pixelSize: 13; color: "#555C65" }
                            }
                        }
                    }
                    SettingRow {
                        width: parent.width; title: qsTr("Scala")
                        IndicatorSlider { Layout.fillWidth: true; from: 0.60; to: 1.60; stepSize: 0.05; value: root.settings.scale; onMoved: root.settings.scale = value }
                        Text { text: Math.round(root.settings.scale*100)+"%"; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight; color: "#555C65" }
                    }
                    SettingRow {
                        width: parent.width; title: qsTr("Opacità")
                        IndicatorSlider { Layout.fillWidth: true; from: 0.40; to: 1; stepSize: 0.05; value: root.settings.widgetOpacity; onMoved: root.settings.widgetOpacity = value }
                        Text { text: Math.round(root.settings.widgetOpacity*100)+"%"; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight; color: "#555C65" }
                    }
                    SettingRow {
                        width: parent.width; title: qsTr("Sempre in primo piano")
                        Item { Layout.fillWidth: true }
                        ToggleSwitch { checked: root.settings.alwaysOnTop; onToggled: function(v) { root.settings.alwaysOnTop = v } }
                    }
                    SettingRow {
                        width: parent.width; title: qsTr("Anima pet"); visible: root.settings.viewMode === "pet"
                        Item { Layout.fillWidth: true }
                        ToggleSwitch { checked: root.settings.petAnimated; onToggled: function(v) { root.settings.petAnimated = v } }
                    }
                    SettingRow {
                        width: parent.width; title: qsTr("Info pet"); visible: root.settings.viewMode === "pet"
                        Rectangle {
                            Layout.fillWidth: true
                            height: 38; radius: 7; color: "#ECEDEF"; border.color: "#D9DCDF"
                            Row {
                                anchors.fill: parent; anchors.margins: 3
                                Repeater {
                                    model: [qsTr("Minimali"), qsTr("Nuvoletta")]
                                    delegate: Rectangle {
                                        id: infoOption
                                        required property int index
                                        required property string modelData
                                        readonly property string value: index === 0 ? "minimal" : "bubble"
                                        readonly property bool selected: (root.settings.petInfoStyle || "minimal") === value
                                        width: parent.width / 2; height: parent.height; radius: 5
                                        color: selected ? "#51565D" : "transparent"
                                        Text {
                                            anchors.centerIn: parent; text: infoOption.modelData
                                            font.family: "Poppins"; font.pixelSize: 13
                                            color: infoOption.selected ? "white" : "#555C65"
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: root.settings.petInfoStyle = infoOption.value
                                        }
                                    }
                                }
                            }
                        }
                    }
                    SettingRow {
                        width: parent.width; title: qsTr("Grandezza nuvoletta")
                        visible: root.settings.viewMode === "pet" && root.settings.petInfoStyle === "bubble"
                        IndicatorSlider {
                            objectName: "petBubbleScaleSlider"
                            Layout.fillWidth: true
                            from: 0.60; to: 1.80; stepSize: 0.05
                            value: root.settings.petBubbleScale
                            onMoved: root.settings.petBubbleScale = value
                        }
                        Text {
                            text: Math.round(root.settings.petBubbleScale * 100) + "%"
                            Layout.preferredWidth: 44
                            horizontalAlignment: Text.AlignRight
                            color: "#555C65"
                            font.family: "Poppins"
                            font.pixelSize: 13
                        }
                    }
                    SettingRow {
                        width: parent.width; title: qsTr("Anteprima pet")
                        visible: root.settings.viewMode === "pet" && root.settings.petAnimated
                        SettingsButton { text: qsTr("Prova animazioni"); onClicked: animationPreview.open() }
                        Item { Layout.fillWidth: true }
                    }
                    SettingRow {
                        width: parent.width; title: qsTr("Posizione elementi")
                        visible: root.settings.viewMode === "pet"
                        SettingsButton { objectName: "editPetLayoutButton"; text: qsTr("Stato e posizioni"); onClicked: layoutPreview.open() }
                        Item { Layout.fillWidth: true }
                    }
                    SettingRow {
                        width: parent.width; title: qsTr("Pet / espressione"); height: Math.max(68, petChoices.implicitHeight + 32); visible: root.settings.viewMode === "pet"
                        GridLayout {
                            id: petChoices
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                            columns: Math.max(1, Math.min(4, Math.floor((width + 8) / 104)))
                            columnSpacing: 8
                            rowSpacing: 8
                        Repeater {
                            model: ["qrc:/assets/kira/frames/idle/00.png", "qrc:/assets/darkshrill/frames/idle/00.png", "qrc:/assets/mascot/idle/00.png", "qrc:/assets/pip/idle/00.png", "qrc:/assets/clippit/frames/idle/00.png", "qrc:/assets/dario/frames/idle/00.png", "qrc:/assets/doraemon/frames/idle/00.png", "qrc:/assets/goku/frames/idle/00.png", "qrc:/assets/mini-elon/frames/idle/00.png"]
                            delegate: Rectangle {
                                required property int index; required property string modelData
                                readonly property int petId: [0, 1, 4, 5, 6, 7, 8, 9, 10][index]
                                width: 96; height: 96; radius: 7; color: "#F1F2F3"
                                border.color: root.settings.petExpression === petId ? "#51565D" : "#DCDFE2"
                                Image { anchors.fill: parent; anchors.margins: 4; source: parent.modelData; smooth: parent.petId !== 4; fillMode: Image.PreserveAspectFit }
                                ToolTip {
                                    id: petToolTip
                                    visible: petChoice.containsMouse
                                    text: ["Kira", "DarkShrill", "Germoglio", "Pip", "Clippy", "Dario", "Doraemon", "Goku", "Mini Elon"][index]
                                    // width: 96
                                    height: 16
                                    padding: 6
                                    contentItem: Text {
                                        text: petToolTip.text.toUpperCase()
                                        color: "#FFFFFF"
                                        font.family: "Poppins"
                                        font.pixelSize: 10
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                    background: Rectangle {
                                        radius: 10
                                        color: "#4B5964"
                                    }
                                }
                                MouseArea { id: petChoice; anchors.fill: parent; hoverEnabled: true; onClicked: root.settings.petExpression = parent.petId }
                            }
                        }
                        Repeater {
                            model: petLibrary.customPets
                            delegate: Rectangle {
                                required property var modelData
                                width: 96; height: 96; radius: 7; color: "#F1F2F3"
                                border.color: root.settings.petExpression === modelData.id ? "#51565D" : "#DCDFE2"
                                Image { anchors.fill: parent; anchors.margins: 4; source: modelData.preview; smooth: true; fillMode: Image.PreserveAspectFit }
                                ToolTip { visible: customPetChoice.containsMouse; text: modelData.name }
                                MouseArea { id: customPetChoice; anchors.fill: parent; hoverEnabled: true; onClicked: root.settings.petExpression = modelData.id }
                            }
                        }
                        Rectangle {
                            id: addPetTile
                            width: 96; height: 96; radius: 7; color: addPetMouse.containsMouse ? "#F5F7F8" : "transparent"
                            border.width: 0
                            Canvas {
                                id: addPetCanvas
                                anchors.fill: parent
                                onPaint: {
                                    const ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.strokeStyle = addPetMouse.containsMouse ? "#0091FF" : "#A8ADB3"
                                    ctx.lineWidth = 1.5
                                    ctx.setLineDash([5, 4])
                                    ctx.strokeRect(1, 1, width - 2, height - 2)
                                }
                                Connections { target: addPetMouse; function onContainsMouseChanged() { addPetCanvas.requestPaint() } }
                            }
                            Text { anchors.centerIn: parent; text: "+"; color: "#0091FF"; font.pixelSize: 34; font.weight: Font.Light }
                            MouseArea { id: addPetMouse; anchors.fill: parent; hoverEnabled: true; onClicked: importSourceDialog.open() }
                            ToolTip {
                                id:petCustomToolTip
                                visible: addPetMouse.containsMouse
                                text: qsTr("Aggiungi un pet personalizzato")
                                height: 16
                                padding: 6
                                contentItem: Text {
                                    text: petCustomToolTip.text.toUpperCase()
                                    color: "#FFFFFF"
                                    font.family: "Poppins"
                                    font.pixelSize: 10
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                                background: Rectangle {
                                    radius: 10
                                    color: "#4B5964"
                                }
                            }
                        }
                        }
                    }
                    Text {
                        visible: root.settings.viewMode === "pet"; width: parent.width; height: Math.max(62, implicitHeight); topPadding: 12
                        wrapMode: Text.WordWrap
                        text: qsTr("Pet: segue Codex e riproduce il gesto al cambio di stato. Per aggiungerne uno: importa una cartella o ZIP con frames-manifest.json e PNG per idle, running, review, waiting, jumping e failed. Durate facoltative (125 ms predefiniti); se manca qualcosa, l’importazione indica cosa creare.")
                        font.pixelSize: 12; color: "#777D85"
                    }
                }
                Column {
                    visible: root.pageIndex === 1; width: parent.width
                    SettingRow {
                        width: parent.width; title: qsTr("Intervallo")
                        SpinBox {
                            id: interval
                            objectName: "refreshInterval"
                            from: 15; to: 3600; stepSize: 15; editable: true
                            value: root.settings.refreshSeconds
                            onValueModified: root.settings.refreshSeconds = value
                            Layout.preferredWidth: 150; Layout.preferredHeight: 38
                            font.family: "Poppins"; font.pixelSize: 13
                            background: Rectangle { radius: 7; color: "#F0F1F3"; border.color: interval.activeFocus ? "#0091FF" : "#D8DADD" }
                            contentItem: TextInput {
                                text: interval.textFromValue(interval.value, interval.locale)
                                font: interval.font; color: "#252A32"; selectionColor: "#0091FF"
                                horizontalAlignment: Qt.AlignHCenter; verticalAlignment: Qt.AlignVCenter
                                readOnly: !interval.editable; validator: interval.validator
                                inputMethodHints: Qt.ImhDigitsOnly
                            }
                            up.indicator: Rectangle {
                                x: interval.width - width; width: 32; height: interval.height; radius: 7
                                color: interval.up.pressed ? "#D9DCDF" : interval.up.hovered ? "#E5E7EA" : "transparent"
                                Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 20; color: interval.up.enabled ? "#51565D" : "#B9BDC3" }
                            }
                            down.indicator: Rectangle {
                                width: 32; height: interval.height; radius: 7
                                color: interval.down.pressed ? "#D9DCDF" : interval.down.hovered ? "#E5E7EA" : "transparent"
                                Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 20; color: interval.down.enabled ? "#51565D" : "#B9BDC3" }
                            }
                        }
                        Text { text: qsTr("secondi"); color: "#777D85" }
                        Item { Layout.fillWidth: true }
                    }
                    SettingRow {
                        width: parent.width; title: qsTr("Dati utilizzo")
                        Item { Layout.fillWidth: true }
                        Button {
                            text: qsTr("Aggiorna adesso"); onClicked: root.client.refresh()
                            background: Rectangle { radius: 6; color: parent.down ? "#E1E3E6" : "#F0F1F3"; border.color: "#D8DADD" }
                            contentItem: Text { text: parent.text; color: "#252A32"; font.family: "Poppins"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            Layout.preferredWidth: 150; Layout.preferredHeight: 36
                        }
                    }
                    Text { width: parent.width; height: 40; topPadding: 12; text: root.client.lastError.length ? root.client.lastError : qsTr("Stato: %1").arg(root.client.status); elide: Text.ElideRight; color: root.client.lastError.length ? "#B44E4E" : "#777D85"; font.pixelSize: 12 }
                }
                Column {
                    visible: root.pageIndex === 2; width: parent.width
                    SettingRow {
                        width: parent.width; title: qsTr("Avvia con Windows")
                        Item { Layout.fillWidth: true }
                        ToggleSwitch { checked: root.settings.launchAtStartup; onToggled: function(v) { root.settings.launchAtStartup = v } }
                    }
                    SettingRow {
                        width: parent.width; title: qsTr("Monitor sulla barra di Windows")
                        Item { Layout.fillWidth: true }
                        ToggleSwitch {
                            objectName: "taskbarMonitorCheckbox"
                            checked: root.settings.taskbarMonitor
                            onToggled: function(v) { root.settings.taskbarMonitor = v }
                        }
                    }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; color: "#777D85"; font.pixelSize: 12
                        text: qsTr("Mostra le quote residue nella barra principale. Se la barra è piena, il monitor ricompare appena si libera spazio.")
                    }
                    SettingRow {
                        width: parent.width; title: qsTr("Posizione widget")
                        Item { Layout.fillWidth: true }
                        Button {
                            text: qsTr("Dimentica posizione"); onClicked: root.settings.clearPosition()
                            background: Rectangle { radius: 6; color: parent.down ? "#E1E3E6" : "#F0F1F3"; border.color: "#D8DADD" }
                            contentItem: Text { text: parent.text; color: "#252A32"; font.family: "Poppins"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            Layout.preferredWidth: 170; Layout.preferredHeight: 36
                        }
                    }
                }
            }
        }
    }
}
