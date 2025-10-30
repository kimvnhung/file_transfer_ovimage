import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 800
    height: 600
    title: "Desktop Test Mode - File Transfer Over Image"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2C3E50" }
            GradientStop { position: 1.0; color: "#34495E" }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 30
            width: Math.min(parent.width * 0.6, 500)

            // Hello World Message
            Text {
                text: "Hello World"
                font.pixelSize: 64
                font.bold: true
                color: "white"
                Layout.alignment: Qt.AlignHCenter
            }

            // Build Info
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
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
                        text: "• Simplified UI for testing"
                        font.pixelSize: 12
                        color: "#95A5A6"
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
                }
            }

            // System Info
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: "#2C3E50"
                radius: 10
                border.color: "#3498DB"
                border.width: 2

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 8

                    Label {
                        text: "System Information"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#3498DB"
                    }

                    Label {
                        text: "Qt Version: " + Qt.version
                        font.pixelSize: 11
                        color: "#ECF0F1"
                    }

                    Label {
                        text: "Screen: " + Screen.width + "x" + Screen.height
                        font.pixelSize: 11
                        color: "#ECF0F1"
                    }
                }
            }

            // Action Button
            Button {
                text: "Test Message"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 200
                Layout.preferredHeight: 50
                font.pixelSize: 16

                background: Rectangle {
                    color: parent.pressed ? "#2980B9" : parent.hovered ? "#3498DB" : "#1ABC9C"
                    radius: 25
                }

                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    messageText.text = "Button clicked at " + new Date().toLocaleTimeString()
                }
            }

            // Status Message
            Label {
                id: messageText
                text: "Ready for testing..."
                font.pixelSize: 14
                color: "#95A5A6"
                Layout.alignment: Qt.AlignHCenter
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
}
