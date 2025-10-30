import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    
    property string title: "Processing..."
    property string subtitle: ""
    property int progress: 0
    property bool showBusyIndicator: true
    
    anchors.centerIn: parent
    spacing: 20
    width: parent.width * 0.6
    
    Label {
        text: root.title
        font.pixelSize: 20
        font.bold: true
        color: "#2C3E50"
        Layout.alignment: Qt.AlignHCenter
    }
    
    Label {
        visible: root.subtitle !== ""
        text: root.subtitle
        font.pixelSize: 14
        color: "#7F8C8D"
        elide: Text.ElideMiddle
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
    }
    
    ProgressBar {
        Layout.fillWidth: true
        Layout.preferredHeight: 30
        from: 0
        to: 100
        value: root.progress
        
        background: Rectangle {
            color: "#E0E0E0"
            radius: 5
        }
        
        contentItem: Item {
            Rectangle {
                width: parent.width * (root.progress / 100)
                height: parent.height
                color: "#3498DB"
                radius: 5
                
                // Animated gradient
                SequentialAnimation on color {
                    running: true
                    loops: Animation.Infinite
                    ColorAnimation { to: "#5DADE2"; duration: 1000 }
                    ColorAnimation { to: "#3498DB"; duration: 1000 }
                }
            }
        }
    }
    
    Label {
        text: root.progress + "%"
        font.pixelSize: 16
        font.bold: true
        color: "#3498DB"
        Layout.alignment: Qt.AlignHCenter
    }
    
    BusyIndicator {
        visible: root.showBusyIndicator
        Layout.alignment: Qt.AlignHCenter
        running: root.showBusyIndicator
    }
}
