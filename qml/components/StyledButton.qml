import QtQuick
import QtQuick.Controls

Button {
    id: control
    
    // Custom properties
    property color normalColor: "#3498DB"
    property color hoverColor: "#2E86C1"
    property color pressedColor: "#2471A3"
    property color disabledColor: "#95A5A6"
    property color textColor: "white"
    property int buttonRadius: 5
    
    background: Rectangle {
        color: {
            if (!control.enabled) return control.disabledColor
            if (control.pressed) return control.pressedColor
            if (control.hovered) return control.hoverColor
            return control.normalColor
        }
        radius: control.buttonRadius
    }
    
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
