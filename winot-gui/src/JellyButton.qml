import QtQuick
import QtQuick.Controls.Basic 6.2
import Qt5Compat.GraphicalEffects

Button {
    property color upColor
    property color downColor

    id: btn
    width: 226
    height: 88
    font.pixelSize: 40
    font.family: "Arial"
    font.bold: true

    background: Rectangle {
                implicitWidth: 240
                implicitHeight: 100
                color: parent.down ? downColor : upColor
//                    border.color: "#26282a"
//                    border.width: 1
                radius: 4

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 1
                    verticalOffset: 1
                    color: upColor //btnPut.visualFocus ? "#330066ff" : "#aaaaaa"
//                        samples: 5
                    spread: 0.5
                    radius: 40
                }
            }
}
