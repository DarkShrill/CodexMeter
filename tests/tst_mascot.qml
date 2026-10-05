import QtQuick
import QtTest
import "../qml/components"

TestCase {
    id: test
    name: "MascotAnimation"
    when: windowShown
    width: 200; height: 200
    visible: true
    Component {
        id: factory
        Mascot {
            resourceRoot: Qt.resolvedUrl("../assets/mascot/")
            occasionalAnimations: []
        }
    }
    function test_animation() {
        let pet = createTemporaryObject(factory, test)
        verify(pet !== null)
        tryCompare(pet, "framesReady", true)
        tryVerify(function() { return pet.frameIndex > 0 })
        pet.playing = false
        let frame = pet.frameIndex
        wait(300)
        compare(pet.frameIndex, frame)
        for (let state of ["thinking", "happy", "warning", "critical", "idle"]) {
            pet.state = state
            compare(pet.frameIndex, 0)
            tryCompare(pet, "framesReady", true)
            compare(pet.width, 80)
            compare(pet.height, 80)
        }
        pet.playing = true
        verify(pet.playOnce("blink"))
        compare(pet.frameCount, 4)
        tryCompare(pet, "temporaryAnimation", "", 1500)
        compare(pet.animationName, "idle")
        verify(!pet.playOnce("missing"))
    }
}
