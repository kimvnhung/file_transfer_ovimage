import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    visible: true
    width: 1000
    height: 700
    title: "File Transfer Over Image - Desktop Mode"

    // Main container with tabs
    TabBar {
        id: tabBar
        width: parent.width
        
        TabButton {
            text: "📦 File Transfer"
            font.pixelSize: 14
        }
        
        TabButton {
            text: "ℹ️ About"
            font.pixelSize: 14
        }
    }

    StackLayout {
        width: parent.width
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        currentIndex: tabBar.currentIndex
        
        // Tab 1: File Transfer (Steganography)
        Loader {
            source: "qrc:/qml/views/FileTransferView.qml"
        }
        
        // Tab 2: About/System Info
        Loader {
            source: "qrc:/qml/views/AboutView.qml"
        }
    }
}
