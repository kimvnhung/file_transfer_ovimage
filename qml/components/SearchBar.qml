import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    
    property alias searchText: searchField.text
    property alias placeholderText: searchField.placeholderText
    signal textChanged(string text)
    
    color: "#2C3E50"
    radius: 5
    border.color: searchField.activeFocus ? "#3498DB" : "#465A6B"
    border.width: 2
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 5
        
        Label {
            text: "🔍"
            font.pixelSize: 14
            color: "#BDC3C7"
        }
        
        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "Search..."
            font.pixelSize: 12
            color: "white"
            placeholderTextColor: "#7F8C8D"
            
            background: Rectangle {
                color: "transparent"
            }
            
            onTextChanged: root.textChanged(text)
        }
        
        Button {
            visible: searchField.text !== ""
            text: "✕"
            Layout.preferredWidth: 25
            Layout.preferredHeight: 25
            font.pixelSize: 12
            
            background: Rectangle {
                color: parent.hovered ? "#E74C3C" : "transparent"
                radius: 3
            }
            
            contentItem: Text {
                text: parent.text
                color: parent.hovered ? "white" : "#95A5A6"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: searchField.text = ""
        }
    }
}
