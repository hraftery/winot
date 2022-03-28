import QtQuick
import QtQuick.Controls
import Winot.Gui


Window {
    property bool onTarget: true //set to true if we're running on the Pi, false for desktop.

    RackIllumination {
        id: rackIllumination
    }

    id: root
    width: onTarget ? 800 : 480
    height: onTarget ? 480 : 800
    visible: true
    color: "#000000"
    title: qsTr("Winot")

    Component {
        id: homeScreen
        HomeScreen {
            onSigPut: {
                stack.push(putScreen)
                stack.currentItem.reset() //would prefer to call reset before pushing, but don't have access to currentItem then!
            }
            onSigGet: {
                stack.push(getScreen)
                stack.currentItem.reset()
            }
            onSigDrank: {
                stack.push(drankScreen)
                stack.currentItem.reset()
            }
            onSigReturn: {
                stack.push(returnScreen)
                stack.currentItem.reset()
            }
        }
    }

    Component {
        id: putScreen
        PutScreen {
            onSigHome: stack.pop()
        }
    }

    Component {
        id: getScreen
        GetScreen {
            onSigHome: stack.pop()
        }
    }

    Component {
        id: drankScreen
        DrankScreen {
            onSigHome: stack.pop()
        }
    }

    Component {
        id: returnScreen
        ReturnScreen {
            onSigHome: stack.pop()
        }
    }

    StackView {
        id: stack
        initialItem: homeScreen
        anchors.fill: parent
        onCurrentItemChanged: {
            currentItem.forceActiveFocus()
            if(currentItem.objectName == "HomeScreen") {
                rackIllumination.allOff()
            }
        }
    }

    Binding {
        target: stack
        property: "transform"
        when: onTarget
        value: Rotation { //For calcs, see https://docs.google.com/spreadsheets/d/1Vril53xEtRFOpUpF5h6KM9TFz6D7Ar1aQKYEL28-_Lo/edit?usp=sharing
            //rotate "right"
            //origin.x: root.height/2
            //origin.y: root.height/2 //not a typo, works out right.
            //angle: -90

            //rotate "left"
            origin.x: root.width/2
            origin.y: root.width/2
            angle: 90
        }
    }
}

/*##^##
Designer {
    D{i:0;formeditorZoom:0.5}D{i:1}D{i:4}D{i:5}D{i:6}
}
##^##*/
