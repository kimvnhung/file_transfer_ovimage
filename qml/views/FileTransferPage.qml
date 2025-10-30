import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Page {
    id: fileTransferPage
    title: "File Transfer"

    property bool isEncodeMode: true  // true = encode, false = decode

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.margins: 5

            ToolButton {
                text: "◄ Back"
                onClicked: stackView.pop()
            }

            Label {
                text: isEncodeMode ? "Encode File in Image" : "Decode File from Image"
                font.bold: true
                font.pixelSize: 18
                Layout.fillWidth: true
            }

            ToolButton {
                text: isEncodeMode ? "🔄 Decode" : "🔄 Encode"
                onClicked: isEncodeMode = !isEncodeMode
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.height
        clip: true

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 20
            anchors.margins: 20

            // Mode indicator
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: isEncodeMode ? "#3498DB" : "#2ECC71"
                radius: 10

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Label {
                        text: isEncodeMode ? "📤 ENCODE MODE" : "📥 DECODE MODE"
                        font.pixelSize: 20
                        font.bold: true
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: isEncodeMode ? 
                              "Hide file data inside an image" : 
                              "Extract hidden file from image"
                        font.pixelSize: 12
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Encode Mode UI
            ColumnLayout {
                Layout.fillWidth: true
                visible: isEncodeMode
                spacing: 15

                // Carrier Image Selection
                GroupBox {
                    Layout.fillWidth: true
                    title: "1. Select Carrier Image"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Button {
                            text: carrierImagePath ? "✓ Image Selected" : "📁 Choose Image"
                            Layout.fillWidth: true
                            onClicked: carrierImageDialog.open()
                        }

                        Label {
                            text: carrierImagePath ? 
                                  "Image: " + carrierImagePath.split('/').pop() : 
                                  "No image selected"
                            font.pixelSize: 11
                            color: carrierImagePath ? "#27AE60" : "#7F8C8D"
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            Layout.fillWidth: true
                        }

                        Label {
                            text: steganography.maxCapacity > 0 ? 
                                  "Capacity: " + formatBytes(steganography.maxCapacity) : ""
                            font.pixelSize: 11
                            color: "#3498DB"
                            visible: steganography.maxCapacity > 0
                        }

                        Image {
                            source: carrierImagePath || ""
                            Layout.fillWidth: true
                            Layout.preferredHeight: 150
                            fillMode: Image.PreserveAspectFit
                            visible: carrierImagePath !== ""
                        }
                    }
                }

                // File to Hide Selection
                GroupBox {
                    Layout.fillWidth: true
                    title: "2. Select File to Hide"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Button {
                            text: secretFilePath ? "✓ File Selected" : "📄 Choose File"
                            Layout.fillWidth: true
                            onClicked: secretFileDialog.open()
                        }

                        Label {
                            text: secretFilePath ? 
                                  "File: " + secretFilePath.split('/').pop() : 
                                  "No file selected"
                            font.pixelSize: 11
                            color: secretFilePath ? "#27AE60" : "#7F8C8D"
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            Layout.fillWidth: true
                        }

                        Label {
                            text: secretFileSize > 0 ? 
                                  "Size: " + formatBytes(secretFileSize) : ""
                            font.pixelSize: 11
                            color: "#3498DB"
                            visible: secretFileSize > 0
                        }
                    }
                }

                // Output Path
                GroupBox {
                    Layout.fillWidth: true
                    title: "3. Output Location"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Button {
                            text: outputPath ? "✓ Location Set" : "💾 Choose Output"
                            Layout.fillWidth: true
                            onClicked: outputFileDialog.open()
                        }

                        Label {
                            text: outputPath ? 
                                  "Output: " + outputPath : 
                                  "No output location selected"
                            font.pixelSize: 11
                            color: outputPath ? "#27AE60" : "#7F8C8D"
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            Layout.fillWidth: true
                        }
                    }
                }

                // Encode Button
                Button {
                    text: steganography.isProcessing ? "⏳ Processing..." : "🔒 Encode File"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    enabled: !steganography.isProcessing && 
                            carrierImagePath && secretFilePath && outputPath
                    font.pixelSize: 16

                    background: Rectangle {
                        color: parent.enabled ? 
                               (parent.pressed ? "#2980B9" : "#3498DB") : 
                               "#95A5A6"
                        radius: 10
                    }

                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: performEncode()
                }
            }

            // Decode Mode UI
            ColumnLayout {
                Layout.fillWidth: true
                visible: !isEncodeMode
                spacing: 15

                // Stego Image Selection
                GroupBox {
                    Layout.fillWidth: true
                    title: "1. Select Image with Hidden Data"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Button {
                            text: stegoImagePath ? "✓ Image Selected" : "📁 Choose Image"
                            Layout.fillWidth: true
                            onClicked: stegoImageDialog.open()
                        }

                        Label {
                            text: stegoImagePath ? 
                                  "Image: " + stegoImagePath.split('/').pop() : 
                                  "No image selected"
                            font.pixelSize: 11
                            color: stegoImagePath ? "#27AE60" : "#7F8C8D"
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            Layout.fillWidth: true
                        }

                        Image {
                            source: stegoImagePath || ""
                            Layout.fillWidth: true
                            Layout.preferredHeight: 150
                            fillMode: Image.PreserveAspectFit
                            visible: stegoImagePath !== ""
                        }

                        Button {
                            text: "🔍 Check for Hidden Data"
                            Layout.fillWidth: true
                            enabled: stegoImagePath !== ""
                            onClicked: checkHiddenData()
                        }

                        Label {
                            id: hiddenDataInfo
                            text: ""
                            font.pixelSize: 11
                            color: "#27AE60"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            visible: text !== ""
                        }
                    }
                }

                // Output Directory
                GroupBox {
                    Layout.fillWidth: true
                    title: "2. Output Directory"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Button {
                            text: decodeOutputPath ? "✓ Directory Set" : "📂 Choose Directory"
                            Layout.fillWidth: true
                            onClicked: decodeOutputDialog.open()
                        }

                        Label {
                            text: decodeOutputPath ? 
                                  "Output: " + decodeOutputPath : 
                                  "No output directory selected"
                            font.pixelSize: 11
                            color: decodeOutputPath ? "#27AE60" : "#7F8C8D"
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            Layout.fillWidth: true
                        }
                    }
                }

                // Decode Button
                Button {
                    text: steganography.isProcessing ? "⏳ Processing..." : "🔓 Decode File"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    enabled: !steganography.isProcessing && 
                            stegoImagePath && decodeOutputPath
                    font.pixelSize: 16

                    background: Rectangle {
                        color: parent.enabled ? 
                               (parent.pressed ? "#27AE60" : "#2ECC71") : 
                               "#95A5A6"
                        radius: 10
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
            }

            // Progress Bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "#ECF0F1"
                radius: 10
                visible: steganography.isProcessing

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5

                    Label {
                        text: "Processing... " + steganography.progress + "%"
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignHCenter
                    }

                    ProgressBar {
                        from: 0
                        to: 100
                        value: steganography.progress
                        Layout.fillWidth: true
                    }
                }
            }

            // Status Message
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: statusMessage.isError ? "#E74C3C" : "#2ECC71"
                radius: 10
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

                MouseArea {
                    anchors.fill: parent
                    onClicked: statusMessage.text = ""
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // File Dialogs
    FileDialog {
        id: carrierImageDialog
        title: "Select Carrier Image"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.bmp)"]
        onAccepted: {
            carrierImagePath = selectedFile.toString()
            steganography.calculateCapacity(carrierImagePath)
        }
    }

    FileDialog {
        id: secretFileDialog
        title: "Select File to Hide"
        nameFilters: ["All files (*)"]
        onAccepted: {
            secretFilePath = selectedFile.toString()
            // Get file size
            var xhr = new XMLHttpRequest();
            xhr.open("HEAD", secretFilePath, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    secretFileSize = parseInt(xhr.getResponseHeader("Content-Length") || 0);
                }
            };
            xhr.send();
        }
    }

    FileDialog {
        id: outputFileDialog
        title: "Choose Output Location"
        fileMode: FileDialog.SaveFile
        nameFilters: ["PNG Image (*.png)"]
        defaultSuffix: "png"
        onAccepted: outputPath = selectedFile.toString()
    }

    FileDialog {
        id: stegoImageDialog
        title: "Select Image with Hidden Data"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.bmp)"]
        onAccepted: stegoImagePath = selectedFile.toString()
    }

    FileDialog {
        id: decodeOutputDialog
        title: "Choose Output Directory"
        fileMode: FileDialog.SaveFile
        onAccepted: decodeOutputPath = selectedFile.toString()
    }

    // Properties
    property string carrierImagePath: ""
    property string secretFilePath: ""
    property string outputPath: ""
    property string stegoImagePath: ""
    property string decodeOutputPath: ""
    property real secretFileSize: 0

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
            showError("Please select all required files");
            return;
        }

        var success = steganography.encodeFileInImage(
            carrierImagePath,
            secretFilePath,
            outputPath
        );

        if (!success) {
            showError(steganography.lastError);
        }
    }

    function performDecode() {
        if (!stegoImagePath || !decodeOutputPath) {
            showError("Please select image and output directory");
            return;
        }

        var success = steganography.decodeFileFromImage(
            stegoImagePath,
            decodeOutputPath
        );

        if (!success) {
            showError(steganography.lastError);
        }
    }

    function checkHiddenData() {
        if (!stegoImagePath) return;

        var info = steganography.getHiddenFileInfo(stegoImagePath);
        hiddenDataInfo.text = info;
    }

    function showError(message) {
        statusMessage.text = "❌ " + message;
        statusMessage.isError = true;
        statusTimer.restart();
    }

    function showSuccess(message) {
        statusMessage.text = "✅ " + message;
        statusMessage.isError = false;
        statusTimer.restart();
    }

    Timer {
        id: statusTimer
        interval: 5000
        onTriggered: statusMessage.text = ""
    }

    // Connections
    Connections {
        target: steganography

        function onEncodeComplete(outputPath, fileSize) {
            showSuccess("File encoded successfully!\nOutput: " + outputPath.split('/').pop());
        }

        function onDecodeComplete(outputPath, fileSize) {
            showSuccess("File decoded successfully!\nSaved: " + outputPath.split('/').pop() + 
                       " (" + formatBytes(fileSize) + ")");
        }

        function onEncodeFailed(error) {
            showError("Encoding failed: " + error);
        }

        function onDecodeFailed(error) {
            showError("Decoding failed: " + error);
        }
    }
}
