import QtQuick
import QtTest
import "../qml/components"

TestCase {
    name: "KiraContinuousPlayback"
    when: windowShown
    width: 240; height: 240; visible: true
    Component {
        id: factory
        PipMascot {
            resourceRoot: Qt.resolvedUrl("../assets/kira/frames/")
            loopAnimation: true
            occasionalAnimations: ["waving"]
            occasionalMinMs: 1000
            occasionalMaxMs: 1000
        }
    }
    SignalSpy { id: finished; signalName: "animationFinished" }
    function test_loopSaluteAndPause() {
        const pet = createTemporaryObject(factory, this)
        finished.target = pet
        finished.clear()
        tryCompare(pet, "framesReady", true)
        tryCompare(pet, "temporaryAnimation", "waving", 2000)
        tryCompare(pet, "temporaryAnimation", "", 2500)
        verify(!pet.cycleDone)
        pet.state = "working"
        finished.clear()
        tryVerify(function() { return finished.count >= 2 }, 4000)
        verify(!pet.cycleDone)
        pet.playing = false
        const frame = pet.frameIndex
        wait(300)
        compare(pet.frameIndex, frame)
        pet.playing = true
        tryVerify(function() { return pet.frameIndex > 0 })
        pet.loopAnimation = false
        tryCompare(pet, "cycleDone", true, 2500)
        pet.loopAnimation = true
        compare(pet.cycleDone, false)
        tryVerify(function() { return pet.frameIndex > 0 })
    }
}
