import QtQuick
import QtTest
import "../qml/components"
TestCase {
    name: "FiniteCodexAnimations"
    when: windowShown
    width: 240; height: 240; visible: true
    Component { id: factory; PipMascot { resourceRoot: Qt.resolvedUrl("../assets/pip/") } }
    function test_eachStateStopsAndRestarts() {
        const pet=createTemporaryObject(factory,this)
        tryCompare(pet,"framesReady",true)
        compare(pet.frameCount,16)
        for (const state of ["working","waiting","review","completed","failed","thinking","idle"]) {
            pet.state=state
            tryCompare(pet,"framesReady",true)
            tryCompare(pet,"cycleDone",true,3500)
            const last=pet.frameIndex
            compare(last,pet.frameCount-1)
            wait(350)
            compare(pet.frameIndex,last)
        }
        pet.state="working"
        tryCompare(pet,"cycleDone",true,3500)
        pet.playing=false
        pet.state="waiting"
        wait(400);compare(pet.frameIndex,0)
        pet.playing=true
        tryCompare(pet,"cycleDone",true,3500)
    }
}
