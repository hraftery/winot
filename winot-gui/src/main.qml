import QtQuick
import QtQuick.Controls
import Winot.Gui


Window {
    property bool onTarget: true //set to true if we're running on the Pi, false for desktop.

    RackIllumination {
        id: rackIllumination
    }

/*
    // Frustratingly, XMLHttpRequest sends a highly unnecessary HTTP/2 upgrade request, which
    // uvicorn doesn't and needn't support. Can't change it, so replaced with RackIllumination.
    readonly property int rackGreen    : 1
    readonly property int rackRed      : 2
    readonly property int rackYellow   : 3
    readonly property int rackPurple   : 4
    function rack_set_slot_to_colour(slot, colour) {
        var colour_code, offset1, length1, offset2, length2
        switch(colour)
        {
            case rackGreen:    colour_code = parseInt("0xB6D7A8"); break;
            case rackRed:      colour_code = parseInt("0xEA9999"); break;
            case rackYellow:   colour_code = parseInt("0xF9CB9C"); break;
            case rackPurple:   colour_code = parseInt("0xA4C2F4"); break;
            default:            console.log("Unsupported colour."); return;
        }
        switch(slot)
        {
            case 1: offset1 = 0; length1 = 8; offset2 =75; length2 = 7; break;
            case 2: offset1 = 8; length1 = 7; offset2 =67; length2 = 8; break;
            case 3: offset1 =15; length1 = 8; offset2 =60; length2 = 7; break;
            case 4: offset1 =23; length1 = 7; offset2 =52; length2 = 8; break;
            case 5: offset1 =30; length1 = 8; offset2 =45; length2 = 7; break;
            default: console.log("Unsupported slot."); return;
        }

        var xhr1 = new XMLHttpRequest
        xhr1.onreadystatechange = function() {
           if (xhr1.readyState === XMLHttpRequest.DONE) {
               console.log("xhr1 done")
           }
        }
        xhr1.open("PUT", "http://192.168.0.120/pixels?offset=" + offset1)
        xhr1.setRequestHeader('Connection', null);
        xhr1.setRequestHeader('Connection', 'Keep-Alive');
        xhr1.setRequestHeader('Upgrade', null);
        xhr1.setRequestHeader('HTTP2-Settings', null);
        //xhr1.setRequestHeader('Content-Type', 'application/json');
        //xhr1.send("[" + (colour_code+",").repeat(length1-1) + colour_code+"]")
        xhr1.send(JSON.stringify(Array(colour_code).fill(length1)))
        console.log("sent \"" + "[" + (colour_code+",").repeat(length1-1) + colour_code+"]" + "\" to " + "http://192.168.0.120/pixels?offset=" + offset1)
        var xhr2 = new XMLHttpRequest
        xhr2.onreadystatechange = function() {
           if (xhr2.readyState === XMLHttpRequest.DONE) {
               console.log("xhr2 done")
           }
        }
        xhr2.open("PUT", "http://192.168.0.120/pixels?offset=" + offset2)
        //xhr2.send("[" + (colour_code+",").repeat(length2-1) + colour_code+"]")
        xhr2.send(Array(colour_code).fill(length2))
        console.log("sent \"" + "[" + (colour_code+",").repeat(length2-1) + colour_code+"]" + "\" to " + "http://192.168.0.120/pixels?offset=" + offset2)
    }
*/

    id: root
    width: onTarget ? 800 : 480
    height: onTarget ? 480 : 800
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
                rackIllumination.setSlotToColour(1, RackIllumination.Colour.Green)
                stack.push(putScreen)
                stack.currentItem.reset() //would prefer to call reset before pushing, but don't have access to currentItem then!
            }
            onSigGet: {
                rackIllumination.setSlotToColour(2, RackIllumination.Colour.Red)
                stack.push(getScreen)
                stack.currentItem.reset()
            }
            onSigDrank: {
                rackIllumination.setSlotToColour(3, RackIllumination.Colour.Yellow)
                stack.push(drankScreen)
                stack.currentItem.reset()
            }
            onSigReturn: {
                rackIllumination.setSlotToColour(5, RackIllumination.Colour.Purple)
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
