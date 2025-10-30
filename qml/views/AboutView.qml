import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    color: "#2C3E50"
    
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 30
        width: Math.min(parent.width * 0.6, 500)
        
        // Logo/Title
        Text {
            text: "File Transfer Over Image"
            font.pixelSize: 32
            font.bold: true
            color: "white"
            Layout.alignment: Qt.AlignHCenter
        }

        // Build Info
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            color: "#34495E"
            radius: 10
            border.color: "#ECF0F1"
            border.width: 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                Label {
                    text: "🖥️ Desktop Mode"
                    font.pixelSize: 20
                    font.bold: true
                    color: "#ECF0F1"
                }

                Label {
                    text: "Build Configuration:"
                    font.pixelSize: 14
                    color: "#BDC3C7"
                }
                
                Label {
                    text: "• Qt Version: " + Qt.version
                    font.pixelSize: 12
                    color: "#95A5A6"
                }

                Label {
                    text: "• Steganography: Available ✓"
                    font.pixelSize: 12
                    color: "#2ECC71"
                }

                Label {
                    text: "• OCR: " + (typeof tesseractOCR !== 'undefined' ? "Available ✓" : "Not Available ✗")
                    font.pixelSize: 12
                    color: typeof tesseractOCR !== 'undefined' ? "#2ECC71" : "#E74C3C"
                }

                Label {
                    text: "• Platform: " + Qt.platform.os
                    font.pixelSize: 12
                    color: "#95A5A6"
                }
                
                Label {
                    text: "• Screen: " + Screen.width + "x" + Screen.height
                    font.pixelSize: 12
                    color: "#95A5A6"
                }
            }
        }
        
        // Features
        Label {
            text: "Features:"
            font.pixelSize: 16
            font.bold: true
            color: "#ECF0F1"
            Layout.alignment: Qt.AlignHCenter
        }
        
        Label {
            text: "✓ LSB Steganography (2 bits per channel)\n✓ File Transfer via Images\n✓ Desktop & Mobile Support\n✓ OpenCV Video Player\n✓ Tesseract OCR Integration"
            font.pixelSize: 12
            color: "#BDC3C7"
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
        }

        // Close Button
        Button {
            text: "Quit"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 100
            font.pixelSize: 12

            background: Rectangle {
                color: parent.pressed ? "#C0392B" : parent.hovered ? "#E74C3C" : "#95A5A6"
                radius: 5
            }

            contentItem: Text {
                text: parent.text
                font: parent.font
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: Qt.quit()
        }
    }
}
