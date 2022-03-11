import QtQuick 2.0
import QtQuick.Controls
import QtWebView

/*
Window { //only for Designer
    width: 480
    height: 800
    visible: true
    color: "#483838"
    title: qsTr("PutScreen")
*/
Item {

    signal sigHome
    property int step: 0

    function reset() {
        step = 0
        txtIdentifier.text = ""
        txtIdentifier.focus = true
        webView.visible = false
    }

    HomeButton {
    }

    Text {
        x: 45
        y: 80
        color: "#ffffff"
        lineHeight: 1.4
        text: "1. Scan or id the new wine bottle.\n2. Click Submit to add to CellarTracker.\n3. Complete the entry using bin #\n4. Place the bottle in the illuminated slot."
        font.pixelSize: 22
        font.family: "Arial"
    }

    Text {
        id: lblBin
        x: 369
        y: 150
        color: "#ffffff"
        text: "unknown"
        font.pixelSize: 22
        font.family: "Arial"
        font.bold: true
    }

    Text {
        id: lblStepMarker
        x: 18
        y: 76 + step * 36
        color: "#A6C798"
        text: "⮕"
        font.pixelSize: 26
    }

    TextField {
        id: txtIdentifier
        x: 67
        y: 243
        width: 189
        height: 32
        color: "#000000"
        placeholderText: "wine identifier..."
        text: ""
        font.pixelSize: 20
        font.family: "Arial"

        onTextChanged: step = 1
    }

    Button {
        id: btnSubmit
        x: 280
        y: 235
        width: 129
        height: 48
        text: qsTr("Submit")
        font.pixelSize: 22
        font.family: "Arial"

        onClicked: {
            step = 2
            webView.visible = true
            webView.url = "https://www.cellartracker.com/pickproducer.asp?szSearch=ident&PickWine=on"
        }
    }

    WebView {
        id: webView
        x: 5
        y: 289
        width: 470
        height: 507

        visible: false

        httpUserAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1"
    }

    /*
    ListView {
        id: listView
        anchors.fill: parent;
        model: Qt.fontFamilies()

        delegate: Item {
            height: 40;
            x: 200
            Text {
                color: "white"
                anchors.centerIn: parent
                text: modelData;
            }
        }
    }
*/
}



/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}D{i:1}D{i:2}D{i:3}D{i:4}D{i:5}D{i:6}D{i:7}
}
##^##*/
