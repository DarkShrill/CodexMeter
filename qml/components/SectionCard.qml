import QtQuick



Rectangle {

    id: root

    property string title: ""

    property string iconText: ""

    default property alias contentData: content.data



    implicitHeight: 200

    radius: 10

    color: "#FAFAFB"

    border.color: "#E1E3E6"

    border.width: 1



    Text {

        id: icon

        anchors.left: parent.left

        anchors.leftMargin: 26

        anchors.top: parent.top

        anchors.topMargin: 22

        text: root.iconText

        color: "#5A6B88"

        font.family: "Segoe UI Symbol"

        font.pixelSize: 28

    }



    Text {

        id: heading

        anchors.left: icon.right

        anchors.leftMargin: 14

        anchors.verticalCenter: icon.verticalCenter

        text: root.title

        color: "#11182B"

        font.family: "Poppins"

        font.pixelSize: 18

        font.weight: Font.Bold

    }



    Item {

        id: content

        anchors.left: parent.left

        anchors.right: parent.right

        anchors.top: icon.bottom

        anchors.topMargin: 18

        anchors.bottom: parent.bottom

        anchors.leftMargin: 24

        anchors.rightMargin: 24

        anchors.bottomMargin: 22

    }

}

