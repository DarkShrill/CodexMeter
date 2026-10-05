import QtQuick
import QtTest
import "../qml/components"

TestCase {
    name: "GokuAnimations"
    when: windowShown
    width: 240; height: 240; visible: true
    Component {
        id: factory
        GokuMascot { resourceRoot: Qt.resolvedUrl("../assets/goku/frames/") }
    }
    function test_allFramesAndPlayback() {
        const pet = createTemporaryObject(factory, this)
        const states = ["idle", "running-right", "running-left", "waving",
                        "completed", "failed", "waiting", "working", "review"]
        const counts = [6, 8, 8, 4, 5, 8, 6, 6, 6]
        let total = 0
        for (let i = 0; i < states.length; ++i) {
            pet.state = states[i]
            tryCompare(pet, "framesReady", true)
            compare(pet.frameCount, counts[i])
            total += pet.frameCount
            tryCompare(pet, "cycleDone", true, 2500)
            compare(pet.frameIndex, counts[i] - 1)
            wait(150)
            compare(pet.frameIndex, counts[i] - 1)
        }
        compare(total, 57)
        pet.playing = false
        pet.state = "thinking"
        wait(250)
        compare(pet.frameIndex, 0)
        pet.playing = true
        tryCompare(pet, "cycleDone", true, 2500)
    }
}
