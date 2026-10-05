import QtQuick
import QtTest
import "../qml/components"

TestCase {
    name: "PipIntegration"
    when: windowShown
    width: 240; height: 240
    visible: true
    Component {
        id: factory
        PipMascot {
            resourceRoot: Qt.resolvedUrl("../assets/pip/")
            occasionalAnimations: []
        }
    }
    function test_playbackAndStates() {
        const pet = createTemporaryObject(factory, this)
        verify(pet !== null)
        tryCompare(pet, "framesReady", true)
        tryVerify(function() { return pet.frameIndex > 0 })
        pet.playing = false
        const stopped = pet.frameIndex
        wait(350)
        compare(pet.frameIndex, stopped)
        for (const state of ["working","thinking","happy","warning","critical","idle"]) {
            pet.state = state
            compare(pet.frameIndex, 0)
            tryCompare(pet, "framesReady", true)
            compare(pet.config.durations.length, pet.frameCount)
        }
        compare(pet.frameUrl("working",0), String(Qt.resolvedUrl("../assets/pip/running/00.png")))
        pet.playing = true
        verify(pet.playOnce("waving"))
        tryCompare(pet, "temporaryAnimation", "", 2000)
        compare(pet.animationName, "idle")
    }
}
