import QtQuick
import QtQuick.Controls

Window {
    width: 480
    height: 800
    visible: true
    color: "#000000"
    title: qsTr("Winot")
/*
    Timer {
        interval: 2000;
        running: true;
        repeat: true
        onTriggered: console.log("color = " + btnPut.background)
    }
*/
/*
    Loader {
        id: screenLoader
        focus: true
        anchors.fill: parent
        sourceComponent: homeScreen
        active: true
    }
*/

    Component {
        id: homeScreen
        HomeScreen {
            onSigPut: {
                stack.push(putScreen)
                stack.currentItem.reset() //would prefer to call reset before pushing, but don't have access to currentItem then!
            }
        }
    }

    Component {
        id: putScreen
        PutScreen {
            onSigHome: stack.pop()
        }
    }

    StackView {
        id: stack
        initialItem: homeScreen
        anchors.fill: parent
        onCurrentItemChanged: {
            currentItem.forceActiveFocus()
        }
    }
}

/*##^##
Designer {
    D{i:0;formeditorZoom:0.5}D{i:1}D{i:4}D{i:5}D{i:6}
}
##^##*/
