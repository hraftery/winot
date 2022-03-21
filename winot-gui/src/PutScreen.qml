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

    function getInstructionsText() {
        var step1 = "1. Scan or id the new wine bottle.<br />"
        var step2 = "2. Click Submit to add to CellarTracker.<br />"
        var step3 = "3. Complete the entry using bin #<br />"
        var step4 = "4. Place the bottle in the illuminated slot."
        var highlightOn  = "<b><font color=\"#A6C798\">"
        var highlightOff = "</font></b>"
        switch(step) {
            case 0: return highlightOn + step1 + highlightOff + step2 + step3 + step4
            case 1: return step1 + highlightOn + step2 + highlightOff + step3 + step4
            case 2: return step1 + step2 + highlightOn + step3 + highlightOff + step4
            case 3: return step1 + step2 + step3 + highlightOn + step4 + highlightOff
        }
        //return "1. Scan or id the new wine bottle.\n2. Click Submit to add to CellarTracker.\n3. Complete the entry using bin #\n4. Place the bottle in the illuminated slot."
    }

    HomeButton {
    }

    Text {
        x: 45
        y: 70
        color: "#ffffff"
        lineHeight: 1.4
        text: getInstructionsText()
        font.pixelSize: 22
        font.family: "Arial"
    }

    Text {
        id: lblBin
        x: step == 2 ? 392 : 369
        y: 140
        color: step == 2 ? "#A6C798" : "#ffffff"
        text: "5." //TODO: obviously needs to be hooked up to next available slot
        font.pixelSize: 22
        font.family: "Arial"
        font.bold: true
    }

/* The ⮕ character doesn't render on RPi and fixing Unicode issues on Linux is a well-established rabbit hole.
 * So will kill two birds with one stone and switch to a more modern/professional method by changing the font
 * of the current step instead.
    Text {
        id: lblStepMarker
        x: 18
        y: 66 + step * 35
        color: "#A6C798"
        text: "⮕"
        font.pixelSize: 26
    }
*/

    TextField {
        id: txtIdentifier
        x: 77
        y: 233
        width: 189
        height: 32
        color: "#000000"
        placeholderText: "wine identifier..."
        text: ""
        font.pixelSize: 20
        font.family: "Arial"

        onTextChanged: step = 1
    }

    CommonButton {
        id: btnSubmit
        x: 290
        y: 229
        width: 110
        height: 40
        text: qsTr("Submit")
        enabled: txtIdentifier.text

        onClicked: {
            step = 2
            webView.visible = true
            webView.url = "https://www.cellartracker.com/pickproducer.asp?szSearch="+txtIdentifier.text+"&PickWine=on"
        }
    }

    //TODO: store login cookie. Some guidance:
    // - find the relevant cookies
    //   - see Cookies for the site (careful, multiple URLs - check www. or the one that has the most)
    //   - the relevant cookies are probably *not* those listed here: https://support.stackpath.com/hc/en-us/articles/360037692692-Learn-About-WAF-Cookies
    //   - may just be "username" and "passwordHash" (from memory - names might be different)
    // - then create and apply a CookieJar. Four useful, if insufficient, references to piece together:
    //   - https://stackoverflow.com/a/5407338/3697870
    //   - https://forum.qt.io/topic/8305/qwebview-cookies/5
    //   - https://doc.qt.io/qt-5/qnetworkaccessmanager.html#setCookieJar
    //   - https://stackoverflow.com/questions/31191545/stay-logged-in-cookies-with-qt-webview
    WebView {
        id: webView
        x: 5
        y: 279
        width: onTarget ? 517 : 470 //not sure why this is necessary, but it is.
        height: onTarget ? 470 : 517

        visible: false

        //Anything to get us the mobile version of the site.
        httpUserAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1"

        onUrlChanged: {
            console.log(url)
            if(url.toString().includes("added=1")) //the url changes to this when the user submits a new wine
                step = 3
        }
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
