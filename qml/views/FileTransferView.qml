import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore

Rectangle {
    color: "#ECF0F1"
    
    // Encode properties
    property string encodeSecretFilePath: ""
    property string encodeOutputImagePath: ""
    property bool encodeCompleted: false
    
    // Decode properties
    property string decodeEncodedImagePath: ""
    property string decodeOutputFilePath: ""
    
    // Extract properties
    property string extractLargerImagePath: ""
    property string extractOutputImagePath: ""
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "#2C3E50"
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 5
                
                Label {
                    text: "🔒 LSB Steganography"
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Label {
                    text: "Hide files in images using Least Significant Bit encoding"
                    font.pixelSize: 11
                    color: "#BDC3C7"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
        
        // Tab Bar
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            
            TabButton {
                text: "📤 Encode File"
                font.pixelSize: 14
            }
            
            TabButton {
                text: "📥 Decode File"
                font.pixelSize: 14
            }
            
            TabButton {
                text: "✂️ Extract Image"
                font.pixelSize: 14
            }
        }
        
        // Stack Layout for tab content
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex
            
            // =====================================================================
            // ENCODE TAB
            // =====================================================================
            Item {
                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 15
                        anchors.margins: 20
                        
                        Label {
                            text: "Select a file to hide - a carrier image will be auto-generated"
                            font.pixelSize: 12
                            color: "#7F8C8D"
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 10
                        }
                        
                        // Step 1: Select Secret File
                        GroupBox {
                            title: "1️⃣ Select File to Hide"
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10
                                
                                Button {
                                    text: encodeSecretFilePath ? "✓ File Selected" : "📄 Choose File to Hide"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    font.pixelSize: 13
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#2980B9" : parent.hovered ? "#3498DB" : "#5DADE2"
                                        radius: 5
                                    }
                                    
                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    onClicked: encodeSecretFileDialog.open()
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 80
                                    color: encodeSecretFilePath ? "#E8F8F5" : "#F8F9F9"
                                    radius: 5
                                    border.color: encodeSecretFilePath ? "#27AE60" : "#BDC3C7"
                                    border.width: 2
                                    
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        spacing: 5
                                        
                                        Label {
                                            text: encodeSecretFilePath ? "📄 " + encodeSecretFilePath.split('/').pop() : "No file selected"
                                            font.pixelSize: 12
                                            font.bold: encodeSecretFilePath !== ""
                                            color: encodeSecretFilePath ? "#27AE60" : "#95A5A6"
                                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                            Layout.fillWidth: true
                                        }
                                        
                                        Label {
                                            text: encodeSecretFilePath ? getFileSize(encodeSecretFilePath) : ""
                                            font.pixelSize: 11
                                            color: "#7F8C8D"
                                            visible: encodeSecretFilePath !== ""
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Step 2: Choose Output Location
                        GroupBox {
                            title: "2️⃣ Choose Output Location"
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10
                                
                                Button {
                                    text: encodeOutputImagePath ? "✓ Location Set" : "💾 Choose Where to Save Encoded Image"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    font.pixelSize: 13
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#1E8449" : parent.hovered ? "#27AE60" : "#52BE80"
                                        radius: 5
                                    }
                                    
                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    onClicked: encodeOutputDialog.open()
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 60
                                    color: encodeOutputImagePath ? "#E8F8F5" : "#F8F9F9"
                                    radius: 5
                                    border.color: encodeOutputImagePath ? "#27AE60" : "#BDC3C7"
                                    border.width: 2
                                    
                                    Label {
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        text: encodeOutputImagePath ? "💾 " + encodeOutputImagePath : "No output location selected"
                                        font.pixelSize: 12
                                        font.bold: encodeOutputImagePath !== ""
                                        color: encodeOutputImagePath ? "#27AE60" : "#95A5A6"
                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                        
                        // Progress Bar
                        ProgressBar {
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            from: 0
                            to: 100
                            value: steganography.progress
                            visible: steganography.isProcessing && tabBar.currentIndex === 0
                        }
                        
                        Label {
                            text: "Processing: " + steganography.progress + "%"
                            font.pixelSize: 12
                            color: "#3498DB"
                            Layout.alignment: Qt.AlignHCenter
                            visible: steganography.isProcessing && tabBar.currentIndex === 0
                        }
                        
                        // Encode Button
                        Button {
                            text: steganography.isProcessing ? "⏳ Encoding..." : "🔒 Encode and Generate Image"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 55
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            enabled: !steganography.isProcessing && encodeSecretFilePath && encodeOutputImagePath
                            font.pixelSize: 16
                            font.bold: true
                            
                            background: Rectangle {
                                color: parent.enabled ? 
                                       (parent.pressed ? "#1F618D" : parent.hovered ? "#2874A6" : "#2ECC71") : "#95A5A6"
                                radius: 8
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onClicked: performAutoEncode()
                        }
                        
                        // Generate Wrapper Image Button (for testing)
                        Button {
                            text: "🖼️ Generate Test Wrapper Image"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            Layout.topMargin: 10
                            enabled: !steganography.isProcessing
                            font.pixelSize: 14
                            
                            background: Rectangle {
                                color: parent.enabled ? 
                                       (parent.pressed ? "#6C3483" : parent.hovered ? "#7D3C98" : "#8E44AD") : "#95A5A6"
                                radius: 8
                                border.color: parent.enabled ? "#7D3C98" : "#7F8C8D"
                                border.width: 1
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onClicked: generateWrapperImageDialog.open()
                        }
                        
                        // Encode Status Message
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 70
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            color: encodeStatusMessage.isError ? "#E74C3C" : "#2ECC71"
                            radius: 8
                            visible: encodeStatusMessage.text !== ""
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 10
                                
                                Label {
                                    text: encodeStatusMessage.isError ? "❌" : "✅"
                                    font.pixelSize: 24
                                }
                                
                                Label {
                                    id: encodeStatusMessage
                                    property bool isError: false
                                    text: ""
                                    color: "white"
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                        
                        // Preview encoded image
                        GroupBox {
                            title: "📸 Generated Image Preview"
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            visible: encodeCompleted && !encodeStatusMessage.isError
                            
                            Rectangle {
                                width: parent.width
                                height: 300
                                color: "#34495E"
                                radius: 5
                                
                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    source: encodeCompleted ? encodeOutputImagePath : ""
                                    fillMode: Image.PreserveAspectFit
                                    cache: false
                                }
                            }
                        }
                        
                        Item { Layout.fillHeight: true }
                    }
                }
            }
            
            // =====================================================================
            // DECODE TAB
            // =====================================================================
            Item {
                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 15
                        anchors.margins: 20
                        
                        Label {
                            text: "Select an encoded image to extract the hidden file"
                            font.pixelSize: 12
                            color: "#7F8C8D"
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 10
                        }
                        
                        // Step 1: Select Encoded Image
                        GroupBox {
                            title: "1️⃣ Select Encoded Image"
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10
                                
                                Button {
                                    text: decodeEncodedImagePath ? "✓ Image Selected" : "📁 Choose Encoded Image"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    font.pixelSize: 13
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#7D3C98" : parent.hovered ? "#8E44AD" : "#9B59B6"
                                        radius: 5
                                    }
                                    
                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    onClicked: decodeImageDialog.open()
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 80
                                    color: decodeEncodedImagePath ? "#F4ECF7" : "#F8F9F9"
                                    radius: 5
                                    border.color: decodeEncodedImagePath ? "#8E44AD" : "#BDC3C7"
                                    border.width: 2
                                    
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        spacing: 5
                                        
                                        Label {
                                            text: decodeEncodedImagePath ? "📁 " + decodeEncodedImagePath.split('/').pop() : "No image selected"
                                            font.pixelSize: 12
                                            font.bold: decodeEncodedImagePath !== ""
                                            color: decodeEncodedImagePath ? "#8E44AD" : "#95A5A6"
                                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                            Layout.fillWidth: true
                                        }
                                        
                                        Label {
                                            text: decodeHiddenFileInfo.text
                                            font.pixelSize: 11
                                            color: "#27AE60"
                                            visible: decodeHiddenFileInfo.text !== ""
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                                
                                // Image preview
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 200
                                    color: "#34495E"
                                    radius: 5
                                    visible: decodeEncodedImagePath !== ""
                                    
                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        source: decodeEncodedImagePath || ""
                                        fillMode: Image.PreserveAspectFit
                                    }
                                }
                            }
                        }
                        
                        // Hidden file info display
                        Label {
                            id: decodeHiddenFileInfo
                            text: ""
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                        }
                        
                        // Step 2: Choose Output Location for Decoded File
                        GroupBox {
                            title: "2️⃣ Choose Where to Save Decoded File"
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10
                                
                                Button {
                                    text: decodeOutputFilePath ? "✓ Location Set" : "💾 Choose Save Location"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    font.pixelSize: 13
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#D68910" : parent.hovered ? "#F39C12" : "#F5B041"
                                        radius: 5
                                    }
                                    
                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    onClicked: decodeOutputDialog.open()
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 60
                                    color: decodeOutputFilePath ? "#FEF5E7" : "#F8F9F9"
                                    radius: 5
                                    border.color: decodeOutputFilePath ? "#F39C12" : "#BDC3C7"
                                    border.width: 2
                                    
                                    Label {
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        text: decodeOutputFilePath ? "💾 " + decodeOutputFilePath : "No output location selected"
                                        font.pixelSize: 12
                                        font.bold: decodeOutputFilePath !== ""
                                        color: decodeOutputFilePath ? "#D68910" : "#95A5A6"
                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                        
                        // Progress Bar
                        ProgressBar {
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            from: 0
                            to: 100
                            value: steganography.progress
                            visible: steganography.isProcessing && tabBar.currentIndex === 1
                        }
                        
                        Label {
                            text: "Processing: " + steganography.progress + "%"
                            font.pixelSize: 12
                            color: "#3498DB"
                            Layout.alignment: Qt.AlignHCenter
                            visible: steganography.isProcessing && tabBar.currentIndex === 1
                        }
                        
                        // Decode Button
                        Button {
                            text: steganography.isProcessing ? "⏳ Decoding..." : "🔓 Decode and Extract File"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 55
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            enabled: !steganography.isProcessing && decodeEncodedImagePath && decodeOutputFilePath
                            font.pixelSize: 16
                            font.bold: true
                            
                            background: Rectangle {
                                color: parent.enabled ? 
                                       (parent.pressed ? "#7D3C98" : parent.hovered ? "#8E44AD" : "#9B59B6") : "#95A5A6"
                                radius: 8
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onClicked: performDecode()
                        }
                        
                        // Decode Status Message
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 70
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            color: decodeStatusMessage.isError ? "#E74C3C" : "#2ECC71"
                            radius: 8
                            visible: decodeStatusMessage.text !== ""
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 10
                                
                                Label {
                                    text: decodeStatusMessage.isError ? "❌" : "✅"
                                    font.pixelSize: 24
                                }
                                
                                Label {
                                    id: decodeStatusMessage
                                    property bool isError: false
                                    text: ""
                                    color: "white"
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                        
                        Item { Layout.fillHeight: true }
                    }
                }
            }
            
            // =====================================================================
            // EXTRACT TAB
            // =====================================================================
            Item {
                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 15
                        anchors.margins: 20
                        
                        Label {
                            text: "Extract an encoded image that's embedded in a larger image"
                            font.pixelSize: 12
                            color: "#7F8C8D"
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 10
                        }
                        
                        // Step 1: Select Larger Image
                        GroupBox {
                            title: "1️⃣ Select Larger Image"
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10
                                
                                Button {
                                    text: extractLargerImagePath ? "✓ Image Selected" : "📁 Choose Larger Image"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    font.pixelSize: 13
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#D35400" : parent.hovered ? "#E67E22" : "#F39C12"
                                        radius: 5
                                    }
                                    
                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    onClicked: extractLargerImageDialog.open()
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 80
                                    color: extractLargerImagePath ? "#FEF5E7" : "#F8F9F9"
                                    radius: 5
                                    border.color: extractLargerImagePath ? "#F39C12" : "#BDC3C7"
                                    border.width: 2
                                    
                                    Label {
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        text: extractLargerImagePath ? "📁 " + extractLargerImagePath.split('/').pop() : "No image selected"
                                        font.pixelSize: 12
                                        font.bold: extractLargerImagePath !== ""
                                        color: extractLargerImagePath ? "#D68910" : "#95A5A6"
                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                                
                                // Image preview
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 250
                                    color: "#34495E"
                                    radius: 5
                                    visible: extractLargerImagePath !== ""
                                    
                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        source: extractLargerImagePath || ""
                                        fillMode: Image.PreserveAspectFit
                                    }
                                }
                            }
                        }
                        
                        // Step 2: Choose Output Location
                        GroupBox {
                            title: "2️⃣ Choose Output Location for Extracted Image"
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10
                                
                                Button {
                                    text: extractOutputImagePath ? "✓ Location Set" : "💾 Choose Save Location"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    font.pixelSize: 13
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#6C3483" : parent.hovered ? "#7D3C98" : "#8E44AD"
                                        radius: 5
                                    }
                                    
                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    onClicked: extractOutputDialog.open()
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 60
                                    color: extractOutputImagePath ? "#F4ECF7" : "#F8F9F9"
                                    radius: 5
                                    border.color: extractOutputImagePath ? "#8E44AD" : "#BDC3C7"
                                    border.width: 2
                                    
                                    Label {
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        text: extractOutputImagePath ? "💾 " + extractOutputImagePath : "No output location selected"
                                        font.pixelSize: 12
                                        font.bold: extractOutputImagePath !== ""
                                        color: extractOutputImagePath ? "#6C3483" : "#95A5A6"
                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                        
                        // Progress Bar
                        ProgressBar {
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            from: 0
                            to: 100
                            value: steganography.progress
                            visible: steganography.isProcessing && tabBar.currentIndex === 2
                        }
                        
                        Label {
                            text: "Processing: " + steganography.progress + "%"
                            font.pixelSize: 12
                            color: "#3498DB"
                            Layout.alignment: Qt.AlignHCenter
                            visible: steganography.isProcessing && tabBar.currentIndex === 2
                        }
                        
                        // Extract Button
                        Button {
                            text: steganography.isProcessing ? "⏳ Extracting..." : "✂️ Extract Encoded Image"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 55
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            enabled: !steganography.isProcessing && extractLargerImagePath && extractOutputImagePath
                            font.pixelSize: 16
                            font.bold: true
                            
                            background: Rectangle {
                                color: parent.enabled ? 
                                       (parent.pressed ? "#D35400" : parent.hovered ? "#E67E22" : "#F39C12") : "#95A5A6"
                                radius: 8
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onClicked: performExtract()
                        }
                        
                        // Extract Status Message
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 70
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            color: extractStatusMessage.isError ? "#E74C3C" : "#2ECC71"
                            radius: 8
                            visible: extractStatusMessage.text !== ""
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 10
                                
                                Label {
                                    text: extractStatusMessage.isError ? "❌" : "✅"
                                    font.pixelSize: 24
                                }
                                
                                Label {
                                    id: extractStatusMessage
                                    property bool isError: false
                                    text: ""
                                    color: "white"
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                        
                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
    
    // =========================================================================
    // FILE DIALOGS
    // =========================================================================
    
    // Encode dialogs
    FileDialog {
        id: encodeSecretFileDialog
        title: "Select File to Hide"
        nameFilters: ["All files (*)"]
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            encodeSecretFilePath = selectedFile.toString()
            close()
        }
        onRejected: {
            close()
        }
    }
    
    FileDialog {
        id: encodeOutputDialog
        title: "Save Encoded Image As"
        fileMode: FileDialog.SaveFile
        nameFilters: ["PNG Image (*.png)"]
        defaultSuffix: "png"
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            encodeOutputImagePath = selectedFile.toString()
            close()
        }
        onRejected: {
            close()
        }
    }
    
    FileDialog {
        id: generateWrapperImageDialog
        title: "Save Test Wrapper Image As"
        fileMode: FileDialog.SaveFile
        nameFilters: ["PNG Image (*.png)"]
        defaultSuffix: "png"
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            generateWrapperImage(selectedFile.toString())
            close()
        }
        onRejected: {
            close()
        }
    }
    
    // Decode dialogs
    FileDialog {
        id: decodeImageDialog
        title: "Select Encoded Image"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.bmp)"]
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            decodeEncodedImagePath = selectedFile.toString()
            // Check if image has hidden data
            if (steganography.hasHiddenData(decodeEncodedImagePath)) {
                decodeHiddenFileInfo.text = "🔍 " + steganography.getHiddenFileInfo(decodeEncodedImagePath)
            } else {
                decodeHiddenFileInfo.text = "⚠️ No hidden data detected in this image"
            }
            close()
        }
        onRejected: {
            close()
        }
    }
    
    FileDialog {
        id: decodeOutputDialog
        title: "Save Decoded File As"
        fileMode: FileDialog.SaveFile
        nameFilters: ["All files (*)"]
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            decodeOutputFilePath = selectedFile.toString()
            close()
        }
        onRejected: {
            close()
        }
    }
    
    // Extract dialogs
    FileDialog {
        id: extractLargerImageDialog
        title: "Select Larger Image"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.bmp)"]
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            extractLargerImagePath = selectedFile.toString()
            close()
        }
        onRejected: {
            close()
        }
    }
    
    FileDialog {
        id: extractOutputDialog
        title: "Save Extracted Image As"
        fileMode: FileDialog.SaveFile
        nameFilters: ["PNG Image (*.png)"]
        defaultSuffix: "png"
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            extractOutputImagePath = selectedFile.toString()
            close()
        }
        onRejected: {
            close()
        }
    }
    
    // =========================================================================
    // TIMERS
    // =========================================================================
    
    Timer {
        id: encodeStatusTimer
        interval: 8000
        onTriggered: encodeStatusMessage.text = ""
    }
    
    Timer {
        id: decodeStatusTimer
        interval: 8000
        onTriggered: decodeStatusMessage.text = ""
    }
    
    Timer {
        id: extractStatusTimer
        interval: 8000
        onTriggered: extractStatusMessage.text = ""
    }
    
    // =========================================================================
    // FUNCTIONS
    // =========================================================================
    
    // Timer to defer encoding to allow UI to update
    Timer {
        id: encodeTimer
        interval: 50
        repeat: false
        onTriggered: {
            var success = steganography.encodeFileInImage(
                "", // Empty string signals auto-generation
                encodeSecretFilePath,
                encodeOutputImagePath
            );
            
            if (!success) {
                encodeStatusMessage.text = steganography.lastError;
                encodeStatusMessage.isError = true;
                encodeStatusTimer.restart();
            }
        }
    }
    
    // Timer to defer decoding to allow UI to update
    Timer {
        id: decodeTimer
        interval: 50
        repeat: false
        onTriggered: {
            var success = steganography.decodeFileFromImage(
                decodeEncodedImagePath,
                decodeOutputFilePath
            );
            
            if (!success) {
                decodeStatusMessage.text = steganography.lastError;
                decodeStatusMessage.isError = true;
                decodeStatusTimer.restart();
            }
        }
    }
    
    function formatBytes(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
    }
    
    function getFileSize(filePath) {
        // This is a placeholder - Qt doesn't easily expose file size in QML
        // The actual file size will be shown after successful operations
        return "Ready to encode"
    }
    
    function performAutoEncode() {
        if (!encodeSecretFilePath || !encodeOutputImagePath) {
            encodeStatusMessage.text = "Please select a file and output location";
            encodeStatusMessage.isError = true;
            encodeStatusTimer.restart();
            return;
        }
        
        encodeCompleted = false;
        encodeStatusMessage.text = ""
        
        // Use timer to defer encoding, allowing UI to update first
        encodeTimer.start();
    }
    
    function performDecode() {
        if (!decodeEncodedImagePath || !decodeOutputFilePath) {
            decodeStatusMessage.text = "Please select an encoded image and output location";
            decodeStatusMessage.isError = true;
            decodeStatusTimer.restart();
            return;
        }
        
        decodeStatusMessage.text = ""
        
        // Check if image actually has hidden data
        if (!steganography.hasHiddenData(decodeEncodedImagePath)) {
            decodeStatusMessage.text = "This image does not contain any hidden data";
            decodeStatusMessage.isError = true;
            decodeStatusTimer.restart();
            return;
        }
        
        // Use timer to defer decoding, allowing UI to update first
        decodeTimer.start();
    }
    
    function performExtract() {
        if (!extractLargerImagePath || !extractOutputImagePath) {
            extractStatusMessage.text = "Please select a larger image and output location";
            extractStatusMessage.isError = true;
            extractStatusTimer.restart();
            return;
        }
        
        extractStatusMessage.text = ""
        
        // Call the extract function
        var success = steganography.extractEncodedImage(
            extractLargerImagePath,
            extractOutputImagePath
        );
        
        if (success) {
            extractStatusMessage.text = "Encoded image extracted successfully!\nSaved to: " + extractOutputImagePath.split('/').pop();
            extractStatusMessage.isError = false;
            extractStatusTimer.restart();
        } else {
            extractStatusMessage.text = "Extraction failed: " + steganography.lastError;
            extractStatusMessage.isError = true;
            extractStatusTimer.restart();
        }
    }
    
    function generateWrapperImage(outputPath) {
        // Generate a test wrapper image with gradient background
        // Size: 800x600 pixels, similar to what's used in the test suite
        
        var canvas = Qt.createQmlObject('
            import QtQuick 2.15
            Item {
                id: canvasItem
                width: 800
                height: 600
                
                Canvas {
                    id: canvas
                    anchors.fill: parent
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        
                        // Create gradient background
                        var gradient = ctx.createLinearGradient(0, 0, 0, height);
                        gradient.addColorStop(0, "#3498DB");      // Blue
                        gradient.addColorStop(0.5, "#5DADE2");    // Medium blue
                        gradient.addColorStop(1, "#AED6F1");      // Light blue
                        
                        ctx.fillStyle = gradient;
                        ctx.fillRect(0, 0, width, height);
                        
                        // Add some decorative elements
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.3)";
                        ctx.lineWidth = 2;
                        
                        // Draw diagonal lines
                        for (var i = -height; i < width; i += 50) {
                            ctx.beginPath();
                            ctx.moveTo(i, 0);
                            ctx.lineTo(i + height, height);
                            ctx.stroke();
                        }
                        
                        // Add text overlay
                        ctx.fillStyle = "rgba(255, 255, 255, 0.8)";
                        ctx.font = "48px Arial";
                        ctx.textAlign = "center";
                        ctx.textBaseline = "middle";
                        ctx.fillText("Test Wrapper Image", width/2, height/2);
                        
                        ctx.font = "24px Arial";
                        ctx.fillText("800 x 600 pixels", width/2, height/2 + 50);
                        
                        // Save to file
                        canvas.save(outputPath.toString().replace("file://", ""));
                    }
                    
                    Component.onCompleted: {
                        requestPaint();
                    }
                }
            }
        ', parent, "dynamicCanvas");
        
        // Show success message
        encodeStatusMessage.text = "Test wrapper image generated successfully!\nSaved to: " + outputPath.split('/').pop() + "\nSize: 800x600 pixels\n\nYou can now:\n1. Encode a file (it will create a small encoded image)\n2. Use image editing software to embed the encoded image into this wrapper\n3. Test the Extract function to recover the encoded image";
        encodeStatusMessage.isError = false;
        encodeStatusTimer.restart();
        
        // Clean up
        canvasItem.destroy(1000);
    }
    
    // =========================================================================
    // SIGNAL HANDLERS
    // =========================================================================
    
    Connections {
        target: steganography
        
        function onEncodeComplete(outputPath, fileSize) {
            encodeCompleted = true;
            encodeStatusMessage.text = "File successfully hidden in image!\n" +
                                      "Output: " + outputPath.split('/').pop() + "\n" +
                                      "Hidden file size: " + formatBytes(fileSize);
            encodeStatusMessage.isError = false;
            encodeStatusTimer.restart();
        }
        
        function onEncodeFailed(error) {
            encodeStatusMessage.text = "Encoding failed: " + error;
            encodeStatusMessage.isError = true;
            encodeStatusTimer.restart();
        }
        
        function onDecodeComplete(outputPath, fileSize) {
            decodeStatusMessage.text = "File successfully extracted!\n" +
                                      "Saved to: " + outputPath.split('/').pop() + "\n" +
                                      "File size: " + formatBytes(fileSize);
            decodeStatusMessage.isError = false;
            decodeStatusTimer.restart();
        }
        
        function onDecodeFailed(error) {
            decodeStatusMessage.text = "Decoding failed: " + error;
            decodeStatusMessage.isError = true;
            decodeStatusTimer.restart();
        }
    }
}
