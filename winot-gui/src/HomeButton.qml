import QtQuick
import QtQuick.Controls.Basic 6.2
import Qt5Compat.GraphicalEffects

Item {
    id: root
    x: 10
    y: 10

    width: childrenRect.width
    height: childrenRect.height

    Text {
        text: "❮ " // "‹ « ˂ < 〈 ❬ ❰ ❲ ⟨ ◀ ☜ ☚"
        visible: false
        color: "#3388DD"
        font.pixelSize: 28
        font.family: "Arial"
        font.bold: true
    }

    Text {
        //y: 6
        text: "◀ Home"
        color: "#3388DD"
        font.pixelSize: 22
        font.family: "Arial"
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.parent.sigHome() //bit sneaky - trigger our user's sigHome signal directly
    }
}
