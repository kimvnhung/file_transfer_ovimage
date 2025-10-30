import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    
    property string labelText: ""
    property string valueText: ""
    property int labelWidth: 120
    property color labelColor: "#2C3E50"
    property color valueColor: "#34495E"
    
    Layout.fillWidth: true
    
    Label {
        text: root.labelText
        font.bold: true
        color: root.labelColor
        Layout.preferredWidth: root.labelWidth
    }
    
    Label {
        text: root.valueText
        color: root.valueColor
        Layout.fillWidth: true
        wrapMode: Text.WrapAnywhere
    }
}
