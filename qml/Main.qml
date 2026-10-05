import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "components"
import "components/PopupPlacement.js" as PopupPlacement

Window {
    id: root
    visible: true
    color: "transparent"
    title: "Codex Meter"
    opacity: appSettings.widgetOpacity

    property bool detailsVisible: false
    readonly property real s: appSettings.scale
    readonly property string mode: appSettings.viewMode
    readonly property real cardWidth: appSettings.cardStyle === 0 ? 200 : (appSettings.cardStyle === 1 ? 330 : 240)
    readonly property real cardHeight: appSettings.cardStyle === 2 ? 286 : (mode === "pill" ? 242 : 146)
    readonly property real bubbleScale: appSettings.petBubbleScale
    readonly property real baseWidth: mode === "pet"
        ? Math.max(240, appSettings.petInfoStyle === "bubble" ? 144 * bubbleScale : 240) + 60 : cardWidth
    readonly property real baseHeight: mode === "pet"
        ? (appSettings.petInfoStyle === "bubble" ? 96 * bubbleScale : 146) + (appSettings.petExpression === 4 ? 98 : 190)
        : cardHeight
    readonly property real detailWidth: 360
    readonly property real detailHeight: 410
    readonly property real gap: 26
    readonly property real detailY: mode === "pill" ? baseHeight + gap : (mode === "pet" ? 8 : 0)
    readonly property var detailOffset: mode === "pet" ? (appSettings.petLayout.details || ({x: 0, y: 0})) : ({x: 0, y: 0})
    property point fittedDetails: Qt.point(0, 0)
    property string detailsSide: "right"
    readonly property real detailX: fittedDetails.x
    readonly property real panelY: fittedDetails.y
    readonly property var petBounds: mode === "pet" && styleLoader.item ? styleLoader.item : null
    readonly property real widgetLeft: Math.min(0, petBounds ? petBounds.contentLeft : 0)
    readonly property real widgetTop: Math.min(0, petBounds ? petBounds.contentTop : 0)
    readonly property real contentLeft: Math.min(0, petBounds ? petBounds.contentLeft : 0, detailsVisible ? detailX : 0)
    readonly property real contentTop: Math.min(0, petBounds ? petBounds.contentTop : 0, detailsVisible ? panelY : 0)

    readonly property real logicalWidth: {
        return Math.max(baseWidth, petBounds ? petBounds.contentRight : 0,
                        detailsVisible ? detailX + detailWidth : 0) - contentLeft
    }
    readonly property real logicalHeight: {
        return Math.max(baseHeight, petBounds ? petBounds.contentBottom : 0,
                        detailsVisible ? panelY + detailHeight : 0) - contentTop
    }

    width: Math.ceil(logicalWidth * s)
    height: Math.ceil(logicalHeight * s)
    flags: Qt.FramelessWindowHint | Qt.Tool | (appSettings.alwaysOnTop ? Qt.WindowStaysOnTopHint : 0)

    function setDetailsVisible(show) {
        const oldLeft = contentLeft
        const oldTop = contentTop
        if (show) {
            const origin = scaledRoot.mapToGlobal(0, 0)
            const preferred = {x: origin.x + ((mode === "pill" ? 0 : baseWidth + gap) + detailOffset.x) * s,
                               y: origin.y + (detailY + detailOffset.y) * s}
            const anchor = {x: origin.x + widgetLeft * s, y: origin.y + widgetTop * s,
                            width: (Math.max(baseWidth, petBounds ? petBounds.contentRight : 0) - widgetLeft) * s,
                            height: (Math.max(baseHeight, petBounds ? petBounds.contentBottom : 0) - widgetTop) * s}
            const screenBounds = appSettings.availableScreenGeometry(
                Math.round(anchor.x + anchor.width / 2), Math.round(anchor.y + anchor.height / 2))
            const placed = PopupPlacement.place(anchor, {width: detailWidth * s, height: detailHeight * s}, preferred, screenBounds)
            fittedDetails = Qt.point((placed.x - origin.x) / s, (placed.y - origin.y) / s)
            detailsSide = placed.side
        }
        detailsVisible = show
        // Resizing the transparent window must keep the pet at the same desktop position.
        x += (contentLeft - oldLeft) * s
        y += (contentTop - oldTop) * s
    }

    function defaultPosition() {
        const position = appSettings.defaultWindowPosition(root.width, root.height)
        root.x = position.x
        root.y = position.y
    }

    function openSettings() {
        settingsWindow.screen = root.screen
        settingsWindow.showNormal()
        settingsWindow.x = Math.round(root.screen.virtualX + (root.screen.width - settingsWindow.width) / 2)
        settingsWindow.y = Math.round(root.screen.virtualY + (root.screen.height - settingsWindow.height) / 2)
        settingsWindow.raise()
        settingsWindow.requestActivate()
    }

    Component.onCompleted: {
        trayController.setWidgetVisible(root.visible)
        const position = appSettings.initialWindowPosition(root.width, root.height)
        x = position.x
        y = position.y
    }

    onXChanged: positionSave.restart()
    onVisibleChanged: trayController.setWidgetVisible(root.visible)
    onYChanged: positionSave.restart()
    onClosing: function(close) {
        if (!trayController.quitting) {
            close.accepted = false
            root.hide()
        }
    }

    Connections {
        target: appSettings
        function onPetLayoutChanged() {
            if (root.detailsVisible) root.setDetailsVisible(true)
        }
        function onViewModeChanged() {
            root.setDetailsVisible(false)
            Qt.callLater(function() {
                if (!appSettings.hasSavedPosition)
                    root.defaultPosition()
            })
        }
    }

    Timer {
        id: positionSave
        interval: 450
        repeat: false
        onTriggered: appSettings.savePosition(Math.round(root.x + (root.widgetLeft - root.contentLeft) * root.s),
                                               Math.round(root.y + (root.widgetTop - root.contentTop) * root.s))
    }

    Connections {
        target: trayController
        function onShowRequested() {
            root.show()
            root.raise()
            root.requestActivate()
        }
        function onSettingsRequested() { root.openSettings() }
        function onHideRequested() { root.hide() }
    }

    SettingsWindow {
        id: settingsWindow
        settings: appSettings
        client: codexClient
        rateModel: rateLimitModel
    }

    Item {
        id: scaledRoot
        x: -root.contentLeft * root.s
        y: -root.contentTop * root.s
        width: root.logicalWidth
        height: root.logicalHeight
        scale: root.s
        transformOrigin: Item.TopLeft

        Loader {
            id: styleLoader
            width: root.baseWidth
            height: root.baseHeight
            x: root.mode === "pill" && root.detailsVisible ? 18 : 0
            y: 0
            sourceComponent: root.mode === "compact" ? compactComponent
                            : root.mode === "pill" ? pillComponent
                            : petComponent
        }

        Connections {
            target: styleLoader.item
            ignoreUnknownSignals: true
            function onBodyClicked() { root.setDetailsVisible(!root.detailsVisible) }
            function onSettingsRequested() { root.openSettings() }
        }

        Component { id: compactComponent; CompactView { rateModel: rateLimitModel; settings: appSettings } }
        Component { id: pillComponent; PillView { rateModel: rateLimitModel; settings: appSettings } }
        Component { id: petComponent; PetView { rateModel: rateLimitModel; settings: appSettings; activity: taskActivity } }

        DetailPanel {
            id: details
            rateModel: rateLimitModel
            client: codexClient
            visible: root.detailsVisible
            width: root.detailWidth
            height: root.detailHeight
            x: root.detailX
            y: root.panelY
            pointerSide: root.mode === "pill" ? "top" : root.detailsSide === "left" ? "right" : "left"
            onSettingsRequested: root.openSettings()
        }

        DragHandler {
            target: null
            acceptedButtons: Qt.LeftButton
            onActiveChanged: {
                if (active)
                    root.startSystemMove()
            }
        }
    }
}
