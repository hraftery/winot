import QtQuick
import QtQuick.Controls
import Qt.labs.qmlmodels
import QtWebView

/*
Window { //only for Designer
    width: 480
    height: 800
    visible: true
    color: "#483838"
    title: qsTr("DrankScreen")
*/
Item {
    signal sigHome

    property int currentSelection: -1

    function reset() {
        currentSelection = -1
        //TODO: illuminate next available (or last used?) bin
    }

    HomeButton {
    }
/*
    Text {
        x: 30
        y: 47
        color: "#ffffff"
        text: "Tap a wine to preview."
        font.pixelSize: 22
        font.family: "Arial"
    }
*/
    CommonButton {
        id: btnConfirm
        x: 468-width
        y: 8
        width: 182
        height: 35

        enabled: currentSelection >= 0

        text: qsTr("Confirm Return")

        onClicked: {
            //TODO: Change from "in use" to bin # from CellarTracker
            sigHome()
        }
    }

    TableView {
        id: tableView
        x: 10
        y: 50
        width: 460
        height: 380
        clip: true
        columnSpacing: 1

        model: TableModel {
            TableModelColumn { display: "type" }
            TableModelColumn { display: "vintage" }
            TableModelColumn { display: "name" }

            rows: [
                {
                    iWine: 1715774,
                    type: "White",
                    vintage: "2013",
                    name: "Felton Road Pinot Noir Block 3"
                },
                {
                    iWine: 3006403,
                    type: "White",
                    vintage: "2012",
                    name: "Undurraga Riesling Terroir Hunter (TH)"
                },
                {
                    iWine: 4071420,
                    type: "Red",
                    vintage: "2020",
                    name: "Aldi Durif The Venturer Series"
                }
            ]
        }

        delegate: Label {
            //implicitWidth: 140
            background: Rectangle {
                color: if(row == currentSelection) { "#3388DD" } else { "white" }
            }
            text: model.display
            font.pixelSize: 18
            padding: 4

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    currentSelection = row
                    webView.url = "https://www.cellartracker.com/wine.asp?iWine="+tableView.model.getRow(row).iWine
                }
            }
        }
    }

    WebView {
        id: webView
        x: 5
        y: tableView.y + tableView.contentHeight + 5
        width: onTarget ? 795 - y : 470 //not sure why this is necessary, but it is.
        height: onTarget ? 470 : 795 - y

        visible: currentSelection >= 0

        //Anything to get us the mobile version of the site.
        httpUserAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1"
    }

}



/*##^##
Designer {
    D{i:0;formeditorZoom:0.75}D{i:1}D{i:2}D{i:3}D{i:9}D{i:10}
}
##^##*/
