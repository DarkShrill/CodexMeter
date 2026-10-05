import QtQuick
import QtTest
import "../qml/components"
TestCase {
    name: "DarioPreview"
    when: windowShown
    width: 600; height: 600; visible: true
    Component { id: factory; PetAnimationPreview { petExpression: 5; resourceRoot: Qt.resolvedUrl("../assets/pip/") } }
    function test_allAnimationsFinish_data() {
        return [{tag: "Dario", expression: 7, folder: "dario/frames/"}]
    }
    function test_allAnimationsFinish(data) {
        const dialog=createTemporaryObject(factory,this, {petExpression: data.expression, resourceRoot: Qt.resolvedUrl("../assets/" + data.folder)})
        dialog.open()
        tryCompare(dialog,"opened",true)
        compare(dialog.choices.length,9)
        dialog.play(0,true)
        tryCompare(dialog,"testingAll",false,25000)
        compare(dialog.previewIndex,8)
        compare(dialog.statusText,"Tutte le animazioni sono state provate.")
        dialog.play(3,false)
        tryCompare(dialog,"statusText","Animazione terminata.",3000)
        dialog.close()
        tryCompare(dialog,"visible",false)
        compare(dialog.previewPlaying,false)
    }
}
