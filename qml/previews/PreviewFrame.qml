import QtQuick

Rectangle {
    id: root
    width: 1100
    height: 800
    property string title: "QML Component Preview"

    property alias mock: mockData
    default property alias previewContent: stage.data

    FontLoader { source: "../../assets/fonts/Poppins-Regular.ttf" }
    FontLoader { source: "../../assets/fonts/Poppins-Medium.ttf" }
    FontLoader { source: "../../assets/fonts/Poppins-SemiBold.ttf" }
    FontLoader { source: "../../assets/fonts/Poppins-Bold.ttf" }
    PreviewData { id: mockData }

    gradient: Gradient {
        GradientStop { position: 0.0; color: "#F3F8FE" }
        GradientStop { position: 1.0; color: "#DCE9F7" }
    }

    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20
        text: root.title
        color: "#172033"
        font.family: "Poppins"
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    Item {
        id: stage
        anchors.fill: parent
        anchors.leftMargin: 36
        anchors.rightMargin: 36
        anchors.topMargin: 58
        anchors.bottomMargin: 36
    }
}
