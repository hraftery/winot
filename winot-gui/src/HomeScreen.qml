import QtQuick 6.2
import QtQuick.Controls.Basic 6.2
import Qt5Compat.GraphicalEffects

Item {
    id: root

    signal sigPut
    signal sigGet
    signal sigDrank
    signal sigReturn

    JellyButton {
        id: btnPut
        x: 127
        y: 92
        text: qsTr("Put")
        upColor: "#B6D7A8"
        downColor: "#D6F7C8"
        onClicked: sigPut()
    }

    JellyButton {
        id: btnGet
        x: 127
        y: 255
        text: qsTr("Get")
        upColor: "#EA9999"
        downColor: "#FFBBBB"
        onClicked: sigGet()
    }

    JellyButton {
        id: btnDrank
        x: 127
        y: 434
        text: qsTr("Drank")
        upColor: "#F9CB9C"
        downColor: "#FFEBBC"
        onClicked: sigDrank()
    }

    JellyButton {
        id: btnReturn
        x: 127
        y: 608
        text: qsTr("Return")
        upColor: "#A4C2F4"
        downColor: "#C4E2FF"
        onClicked: sigReturn()
    }
}
