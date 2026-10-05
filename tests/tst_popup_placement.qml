import QtQuick
import QtTest
import "../qml/components/PopupPlacement.js" as Placement

TestCase {
    name: "PopupPlacement"
    function test_edges_data() {
        return [
            {tag: "right edge", anchor: {x: 900, y: 200, width: 255, height: 240}, preferred: {x: 1177, y: 208}, screen: {x: 0, y: 0, width: 1200, height: 800}, side: "left"},
            {tag: "left edge", anchor: {x: 20, y: 200, width: 255, height: 240}, preferred: {x: -300, y: 208}, screen: {x: 0, y: 0, width: 1200, height: 800}, side: "right"},
            {tag: "bottom right", anchor: {x: 900, y: 550, width: 255, height: 240}, preferred: {x: 1177, y: 558}, screen: {x: 0, y: 0, width: 1200, height: 800}, side: "left"},
            {tag: "top left", anchor: {x: 20, y: 20, width: 255, height: 240}, preferred: {x: -300, y: -100}, screen: {x: 0, y: 0, width: 1200, height: 800}, side: "right"},
            {tag: "negative monitor", anchor: {x: -300, y: -300, width: 255, height: 240}, preferred: {x: -23, y: -292}, screen: {x: -1200, y: -500, width: 1200, height: 800}, side: "left"}
        ]
    }
    function test_edges(row) {
        for (const size of [{width: 320, height: 180}, {width: 306, height: 348.5}]) {
            const placed = Placement.place(row.anchor, size, row.preferred, row.screen)
            compare(placed.side, row.side)
            verify(placed.x >= row.screen.x)
            verify(placed.y >= row.screen.y)
            verify(placed.x + size.width <= row.screen.x + row.screen.width)
            verify(placed.y + size.height <= row.screen.y + row.screen.height)
        }
    }
    function test_savedPositionFits() {
        const preferred = {x: 460, y: 180}
        const placed = Placement.place({x: 100, y: 100, width: 300, height: 286},
            {width: 320, height: 200}, preferred, {x: 0, y: 0, width: 1200, height: 800})
        compare(placed.x, preferred.x)
        compare(placed.y, preferred.y)
    }
}
