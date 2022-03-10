import QtQuick
import QtQuick.Controls.Basic 6.2
import Qt5Compat.GraphicalEffects

Window {
    width: 480
    height: 800
    visible: true
    color: "#000000"
    title: qsTr("Hello World")
/*
    Timer {
        interval: 2000;
        running: true;
        repeat: true
        onTriggered: console.log("color = " + btnPut.background)
    }
*/

    JellyButton {
        id: btnPut
        x: 127
        y: 92
        text: qsTr("Put")
        upColor: "#B6D7A8"
        downColor: "#D6F7C8"
    }

    JellyButton {
        id: btnGet
        x: 127
        y: 255
        text: qsTr("Get")
        upColor: "#EA9999"
        downColor: "#FFBBBB"
    }

    JellyButton {
        id: btnDrank
        x: 127
        y: 434
        text: qsTr("Drank")
        upColor: "#F9CB9C"
        downColor: "#FFEBBC"
    }

    JellyButton {
        id: btnReturn
        x: 127
        y: 608
        text: qsTr("Return")
        upColor: "#A4C2F4"
        downColor: "#C4E2FF"
    }
}

/*##^##
Designer {
    D{i:0;formeditorZoom:0.5}D{i:1}D{i:4}D{i:5}D{i:6}
}
##^##*/
