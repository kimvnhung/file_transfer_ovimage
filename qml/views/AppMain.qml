// Copyright (C) 2024
// Main application view with navigation

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 800
    height: 600
    title: "File Transfer Over Image"

    header: ToolBar {
        visible: stackView.depth > 1
        
        RowLayout {
            anchors.fill: parent
            
            ToolButton {
                text: "←"
                font.pixelSize: 24
                onClicked: stackView.pop()
            }
            
            Label {
                text: stackView.currentItem?.title || ""
                font.pixelSize: 18
                Layout.fillWidth: true
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: menuPage
    }

    Component {
        id: menuPage
        
        Page {
            title: "Main Menu"
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20
                width: Math.min(parent.width * 0.8, 400)
                
                Label {
                    text: "File Transfer Over Image"
                    font.pixelSize: 24
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Button {
                    text: "Camera"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    onClicked: stackView.push(Qt.resolvedUrl("MainView.qml"))
                }
                
                Button {
                    text: "Video Player"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    onClicked: stackView.push(Qt.resolvedUrl("HomePage.qml"))
                }
                
                Button {
                    text: "OCR Text Scanner"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    enabled: tesseractOCR !== undefined
                    onClicked: stackView.push(Qt.resolvedUrl("OCRPage.qml"))
                }
                
                Label {
                    text: tesseractOCR !== undefined ? 
                          "✓ OCR Available" : 
                          "✗ OCR Not Available (Desktop only)"
                    Layout.alignment: Qt.AlignHCenter
                    color: tesseractOCR !== undefined ? "green" : "gray"
                    font.pixelSize: 12
                }
            }
        }
    }
}
