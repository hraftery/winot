import QtQuick
import QtQuick.Controls.Basic 6.2
import Qt5Compat.GraphicalEffects
import QtQml

Button {
    id: btn
    font.pixelSize: 22
    font.family: "Arial"
    font.bold: true

    background: Rectangle {
        color: btn.enabled ? (btn.down ? "#55AAFF" : "#77CCFF") : "#808080"
        border.color: btn.enabled ? "#3388DD" : "black"
        border.width: 1
        radius: 8

        layer.enabled: btn.enabled
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 0
            color: "#3388DD"
//            samples: 5
            spread: 0.5
            radius: 20
        }
    }
}
