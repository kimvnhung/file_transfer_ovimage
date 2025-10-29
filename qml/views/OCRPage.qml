import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Page {
    id: ocrPage
    title: "Text Recognition"
    
    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.margins: 5
            
            ToolButton {
                text: "◄ Back"
                onClicked: stackView.pop()
            }
            
            Label {
                text: "OCR Text Scanner"
                font.bold: true
                font.pixelSize: 18
                Layout.fillWidth: true
            }
            
            ToolButton {
                text: "⚙️"
                onClicked: settingsMenu.open()
                
                Menu {
                    id: settingsMenu
                    
                    MenuItem {
                        text: "Language: " + (languageCombo.currentText || "English")
                        enabled: false
                    }
                    
                    MenuItem {
                        ComboBox {
                            id: languageCombo
                            model: ["English", "Vietnamese", "Chinese", "Japanese", "Korean"]
                            currentIndex: 0
                            
                            onCurrentTextChanged: {
                                var langCode = {
                                    "English": "eng",
                                    "Vietnamese": "vie",
                                    "Chinese": "chi_sim",
                                    "Japanese": "jpn",
                                    "Korean": "kor"
                                }
                                
                                if (typeof tesseractOCR !== 'undefined') {
                                    tesseractOCR.language = langCode[currentText]
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    OCRCameraView {
        id: ocrCamera
        anchors.fill: parent
        
        onTextRecognized: function(text) {
            resultText.text = text
            
            // Auto-copy if enabled
            if (autoCopySwitch.checked) {
                Qt.application.clipboard.text = text
                statusLabel.text = "✓ Text copied to clipboard"
                statusLabel.visible = true
                statusTimer.restart()
            }
        }
        
        onCaptureError: function(error) {
            statusLabel.text = "✗ Error: " + error
            statusLabel.visible = true
            statusLabel.color = "red"
            statusTimer.restart()
        }
    }
    
    // Controls overlay
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: controlsColumn.height + 20
        color: "#E0000000"
        
        Column {
            id: controlsColumn
            anchors.centerIn: parent
            spacing: 10
            width: parent.width - 20
            
            // Capture button
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 200
                height: 50
                text: ocrCamera.isCapturing ? "⏳ Processing..." : "📸 Scan Text"
                font.pixelSize: 18
                font.bold: true
                enabled: !ocrCamera.isCapturing
                
                background: Rectangle {
                    color: parent.pressed ? "#0d8050" : (parent.enabled ? "#10a060" : "#666666")
                    radius: 25
                    border.color: "white"
                    border.width: 2
                }
                
                onClicked: ocrCamera.captureAndRecognize()
            }
            
            // Options
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20
                
                Row {
                    spacing: 5
                    
                    Switch {
                        id: autoCopySwitch
                        checked: true
                    }
                    
                    Label {
                        text: "Auto-copy"
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                Button {
                    text: "🗑️ Clear"
                    onClicked: {
                        ocrCamera.clearText()
                        resultText.text = ""
                    }
                }
            }
            
            // Status label
            Label {
                id: statusLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: "✓ Ready"
                color: "#00ff00"
                font.pixelSize: 14
                visible: false
                
                Timer {
                    id: statusTimer
                    interval: 3000
                    onTriggered: {
                        statusLabel.visible = false
                        statusLabel.color = "#00ff00"
                    }
                }
            }
        }
    }
    
    // Results area (optional, for debugging)
    TextArea {
        id: resultText
        visible: false  // Hidden by default, text shown in OCRCameraView overlay
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 0
        readOnly: true
        wrapMode: TextArea.Wrap
    }
    
    Component.onCompleted: {
        // Initialize Tesseract OCR
        if (typeof tesseractOCR !== 'undefined') {
            if (!tesseractOCR.isInitialized) {
                tesseractOCR.initialize()
            }
        } else {
            console.error("TesseractOCR not available in QML context")
        }
    }
}
