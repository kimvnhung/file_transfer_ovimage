import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    color: "#ECF0F1"
    
    property string carrierImagePath: ""
    property string secretFilePath: ""
    property string outputPath: ""
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        // Header
        Label {
            text: "🔒 LSB Steganography - Hide Files in Images"
            font.pixelSize: 24
            font.bold: true
            color: "#2C3E50"
            Layout.alignment: Qt.AlignHCenter
        }
        
        Label {
            text: "Encode files into carrier images for visual transfer to mobile devices"
            font.pixelSize: 12
            color: "#7F8C8D"
            Layout.alignment: Qt.AlignHCenter
        }
        
        // Input Section
        GroupBox {
            title: "1. Select Carrier Image"
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                Button {
                    text: carrierImagePath ? "✓ Image Selected" : "📁 Choose Carrier Image"
                    Layout.fillWidth: true
                    onClicked: carrierImageDialog.open()
                }
                
                Label {
                    text: carrierImagePath ? "📄 " + carrierImagePath.split('/').pop() : "No image selected"
                    font.pixelSize: 11
                    color: carrierImagePath ? "#27AE60" : "#95A5A6"
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
                
                Label {
                    text: steganography.maxCapacity > 0 ? 
                          "💾 Capacity: " + formatBytes(steganography.maxCapacity) : ""
                    font.pixelSize: 11
                    color: "#3498DB"
                    visible: steganography.maxCapacity > 0
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    color: "#BDC3C7"
                    radius: 5
                    visible: carrierImagePath !== ""
                    
                    Image {
                        anchors.fill: parent
                        anchors.margins: 5
                        source: carrierImagePath || ""
                        fillMode: Image.PreserveAspectFit
                    }
                }
            }
        }
        
        GroupBox {
            title: "2. Select Secret File"
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                Button {
                    text: secretFilePath ? "✓ File Selected" : "📄 Choose File to Hide"
                    Layout.fillWidth: true
                    onClicked: secretFileDialog.open()
                }
                
                Label {
                    text: secretFilePath ? "📄 " + secretFilePath.split('/').pop() : "No file selected"
                    font.pixelSize: 11
                    color: secretFilePath ? "#27AE60" : "#95A5A6"
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
            }
        }
        
        GroupBox {
            title: "3. Output Location"
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                Button {
                    text: outputPath ? "✓ Location Set" : "💾 Choose Output Path"
                    Layout.fillWidth: true
                    onClicked: outputFileDialog.open()
                }
                
                Label {
                    text: outputPath ? "📄 " + outputPath : "No output location selected"
                    font.pixelSize: 11
                    color: outputPath ? "#27AE60" : "#95A5A6"
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
            }
        }
        
        // Progress Bar
        ProgressBar {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: steganography.progress
            visible: steganography.isProcessing
        }
        
        Label {
            text: "Processing: " + steganography.progress + "%"
            font.pixelSize: 12
            color: "#3498DB"
            Layout.alignment: Qt.AlignHCenter
            visible: steganography.isProcessing
        }
        
        // Encode Button
        Button {
            text: steganography.isProcessing ? "⏳ Encoding..." : "🔒 Encode File"
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            enabled: !steganography.isProcessing && carrierImagePath && secretFilePath && outputPath
            font.pixelSize: 16
            
            background: Rectangle {
                color: parent.enabled ? 
                       (parent.pressed ? "#2980B9" : parent.hovered ? "#3498DB" : "#2ECC71") : "#95A5A6"
                radius: 5
            }
            
            contentItem: Text {
                text: parent.text
                font: parent.font
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: {
                performEncode()
            }
        }
        
        // Status Message
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: statusMessage.isError ? "#E74C3C" : "#2ECC71"
            radius: 5
            visible: statusMessage.text !== ""
            
            Label {
                id: statusMessage
                anchors.centerIn: parent
                anchors.margins: 10
                property bool isError: false
                text: ""
                color: "white"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                width: parent.width - 20
            }
        }
        
        Item { Layout.fillHeight: true }
    }
    
    // File Dialogs
    FileDialog {
        id: carrierImageDialog
        title: "Select Carrier Image"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.bmp)"]
        currentFolder: "file:///home"
        onAccepted: {
            carrierImagePath = selectedFile.toString()
            steganography.calculateCapacity(carrierImagePath)
        }
    }
    
    FileDialog {
        id: secretFileDialog
        title: "Select File to Hide"
        nameFilters: ["All files (*)"]
        currentFolder: "file:///home"
        onAccepted: {
            secretFilePath = selectedFile.toString()
        }
    }
    
    FileDialog {
        id: outputFileDialog
        title: "Choose Output Location"
        fileMode: FileDialog.SaveFile
        nameFilters: ["PNG Image (*.png)"]
        defaultSuffix: "png"
        currentFolder: "file:///home"
        onAccepted: {
            outputPath = selectedFile.toString()
        }
    }
    
    // Functions
    function formatBytes(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
    }
    
    function performEncode() {
        if (!carrierImagePath || !secretFilePath || !outputPath) {
            statusMessage.text = "Please select all required files";
            statusMessage.isError = true;
            statusTimer.restart();
            return;
        }
        
        var success = steganography.encodeFileInImage(
            carrierImagePath,
            secretFilePath,
            outputPath
        );
        
        if (!success) {
            statusMessage.text = steganography.lastError;
            statusMessage.isError = true;
            statusTimer.restart();
        }
    }
    
    Timer {
        id: statusTimer
        interval: 5000
        onTriggered: statusMessage.text = ""
    }
    
    Connections {
        target: steganography
        
        function onEncodeComplete(outputPath, fileSize) {
            statusMessage.text = "✅ File encoded successfully!\nOutput: " + outputPath.split('/').pop();
            statusMessage.isError = false;
            statusTimer.restart();
        }
        
        function onEncodeFailed(error) {
            statusMessage.text = "❌ Encoding failed: " + error;
            statusMessage.isError = true;
            statusTimer.restart();
        }
    }
}
