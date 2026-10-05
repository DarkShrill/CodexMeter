import QtQuick
import QtQuick.Controls

ComboBox {
    id: root
    implicitHeight: 38
    leftPadding: 12
    rightPadding: 36
    font.family: "Poppins"
    font.pixelSize: 13
    contentItem: Text {
        text: root.displayText
        font: root.font
        color: root.enabled ? "#3D454D" : "#A8ADB3"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 7
        color: root.enabled ? "#FAFAFB" : "#ECEDEF"
        border.color: root.activeFocus ? "#0091FF" : "#D9DCDF"
    }
    indicator: Canvas {
        x: root.width - width - 14
        y: (root.height - height) / 2
        width: 10; height: 6
        opacity: root.enabled ? 1 : 0.4
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = "#626971"
            ctx.lineWidth = 1.5
            ctx.beginPath()
            ctx.moveTo(1, 1); ctx.lineTo(5, 5); ctx.lineTo(9, 1)
            ctx.stroke()
        }
    }
    delegate: ItemDelegate {
        required property int index
        width: root.width - 2
        height: 38
        highlighted: root.highlightedIndex === index
        contentItem: Text {
            text: root.textAt(parent.index)
            font: root.font
            color: "#3D454D"
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle { radius: 5; color: parent.highlighted ? "#E5EEEE" : "transparent" }
    }
    popup: Popup {
        y: root.height + 4
        width: root.width
        padding: 1
        implicitHeight: Math.min(contentItem.implicitHeight + 2, 300)
        background: Rectangle { color: "#FAFAFB"; radius: 7; border.color: "#D9DCDF" }
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }
}
