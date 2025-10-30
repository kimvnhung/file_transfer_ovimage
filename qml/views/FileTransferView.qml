import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import Qt.labs.folderlistmodel
import opencv_player 1.0

Rectangle {
    id: root
    color: "#ECF0F1"
    
    // Properties
    property string currentFilePath: ""
    property bool isEncoding: false
    property int encodingProgress: 0
    property string encodedImagePath: ""
    property var encodedFrames: []  // Array of all generated frame paths
    property int currentFrameIndex: 0
    
    // Slideshow timer for multiple frames
    Timer {
        id: slideshowTimer
        interval: 500  // 500ms between frames
        repeat: true
        running: encodedFrames.length > 1
        onTriggered: {
            currentFrameIndex = (currentFrameIndex + 1) % encodedFrames.length
            encodedImagePath = encodedFrames[currentFrameIndex]
        }
    }
    
    // Steganography backend
    SteganographyV2 {
        id: steganographyV2
        
        onProgressChanged: {
            encodingProgress = progress
        }
        
        onEncodeComplete: function(outputPath, fileSize) {
            console.log("Encode complete:", outputPath, "Size:", fileSize)
            isEncoding = false
            encodingProgress = 100
            
            // Parse frame paths (comma-separated)
            var framePaths = outputPath.split(", ")
            encodedFrames = framePaths
            currentFrameIndex = 0
            encodedImagePath = framePaths[0]
            
            console.log("Generated", framePaths.length, "frame(s)")
        }
        
        onEncodeFailed: function(error) {
            console.error("Encode failed:", error)
            isEncoding = false
            encodingProgress = 0
            encodedFrames = []
            // Show error dialog
            errorDialog.errorMessage = error
            errorDialog.open()
        }
        
        onFrameGenerated: function(frameNum, totalFrames) {
            console.log("Generated frame", frameNum, "of", totalFrames)
        }
    }
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        // =====================================================================
        // LEFT PANEL - File Browser
        // =====================================================================
        Rectangle {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            color: "#34495E"
            border.color: "#2C3E50"
            border.width: 1
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                
                // Header with Help Button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Label {
                        text: "📁 File Browser"
                        font.pixelSize: 16
                        font.bold: true
                        color: "white"
                        Layout.fillWidth: true
                    }
                    
                    // Help/About Button
                    Button {
                        text: "?"
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        font.pixelSize: 16
                        font.bold: true
                        
                        background: Rectangle {
                            color: parent.pressed ? "#E67E22" : parent.hovered ? "#F39C12" : "#F1C40F"
                            radius: 15
                            border.color: "#D68910"
                            border.width: 2
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: "#2C3E50"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: aboutDialog.open()
                    }
                }
                
                // Search Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
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
                            placeholderText: "Search files..."
                            font.pixelSize: 12
                            color: "white"
                            placeholderTextColor: "#7F8C8D"
                            
                            background: Rectangle {
                                color: "transparent"
                            }
                            
                            onTextChanged: {
                                folderModel.nameFilters = text ? ["*" + text + "*"] : ["*"]
                            }
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
                
                // Current Path Display
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: "#2C3E50"
                    radius: 3
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 5
                        
                        Button {
                            text: "🏠"
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 20
                            font.pixelSize: 12
                            
                            background: Rectangle {
                                color: parent.hovered ? "#3498DB" : "transparent"
                                radius: 3
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onClicked: folderModel.folder = StandardPaths.writableLocation(StandardPaths.HomeLocation)
                        }
                        
                        Label {
                            text: {
                                var path = folderModel.folder.toString().replace("file://", "")
                                var home = StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "")
                                return path.replace(home, "~")
                            }
                            font.pixelSize: 10
                            color: "#BDC3C7"
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                        
                        Button {
                            text: "⬆️"
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 20
                            font.pixelSize: 12
                            enabled: folderModel.folder.toString() !== "file:///"
                            
                            background: Rectangle {
                                color: parent.enabled ? (parent.hovered ? "#3498DB" : "transparent") : "transparent"
                                radius: 3
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? "white" : "#4A5F7A"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onClicked: {
                                var currentPath = folderModel.folder.toString()
                                var parentPath = currentPath.substring(0, currentPath.lastIndexOf('/'))
                                if (parentPath && parentPath !== "file:") {
                                    folderModel.folder = parentPath
                                }
                            }
                        }
                    }
                }
                
                // File List
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#2C3E50"
                    radius: 5
                    
                    ListView {
                        id: fileListView
                        anchors.fill: parent
                        anchors.margins: 5
                        clip: true
                        
                        model: FolderListModel {
                            id: folderModel
                            folder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
                            showDirs: true
                            showFiles: true
                            showDotAndDotDot: false
                            showHidden: false
                            nameFilters: ["*"]
                        }
                        
                        delegate: ItemDelegate {
                            width: fileListView.width
                            height: 40
                            
                            required property string fileName
                            required property url fileUrl
                            required property bool fileIsDir
                            required property int fileSize
                            
                            background: Rectangle {
                                color: {
                                    if (currentFilePath === fileUrl.toString()) return "#3498DB"
                                    if (parent.hovered) return "#34495E"
                                    return "transparent"
                                }
                                radius: 3
                            }
                            
                            contentItem: RowLayout {
                                spacing: 10
                                
                                Label {
                                    text: fileIsDir ? "📁" : getFileIcon(fileName)
                                    font.pixelSize: 16
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Label {
                                        text: fileName
                                        font.pixelSize: 12
                                        color: currentFilePath === fileUrl.toString() ? "white" : "#ECF0F1"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    
                                    Label {
                                        visible: !fileIsDir
                                        text: formatFileSize(fileSize)
                                        font.pixelSize: 9
                                        color: currentFilePath === fileUrl.toString() ? "#E8F8F5" : "#95A5A6"
                                    }
                                }
                                
                                Label {
                                    visible: fileIsDir
                                    text: "▶"
                                    font.pixelSize: 10
                                    color: "#7F8C8D"
                                }
                            }
                            
                            onClicked: {
                                if (fileIsDir) {
                                    folderModel.folder = fileUrl
                                } else {
                                    currentFilePath = fileUrl.toString()
                                    startEncoding(fileUrl)
                                }
                            }
                        }
                        
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }
                    }
                }
                
                // Status Info
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: "#2C3E50"
                    radius: 3
                    
                    Label {
                        anchors.centerIn: parent
                        text: folderModel.count + " items"
                        font.pixelSize: 10
                        color: "#95A5A6"
                    }
                }
            }
        }
        
        // =====================================================================
        // RIGHT PANEL - Encoding Area
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#ECF0F1"
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20
                
                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    color: "#2C3E50"
                    radius: 8
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        
                        Label {
                            text: "🔒 LSB Steganography Encoder"
                            font.pixelSize: 24
                            font.bold: true
                            color: "white"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Label {
                            text: "Fixed 1000×1000 format with border headers"
                            font.pixelSize: 11
                            color: "#BDC3C7"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                // Content Area
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    // Empty State
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 20
                        visible: !isEncoding && encodedImagePath === "" && currentFilePath === ""
                        
                        Label {
                            text: "📂"
                            font.pixelSize: 80
                            color: "#BDC3C7"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Label {
                            text: "Select a file from the left panel to start encoding"
                            font.pixelSize: 16
                            color: "#7F8C8D"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Label {
                            text: "Supported: All file types\nAuto-generated carrier images"
                            font.pixelSize: 12
                            color: "#95A5A6"
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                    
                    // Encoding Progress
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 20
                        visible: isEncoding
                        width: parent.width * 0.6
                        
                        Label {
                            text: "🔐 Encoding in progress..."
                            font.pixelSize: 20
                            font.bold: true
                            color: "#2C3E50"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Label {
                            text: currentFilePath ? currentFilePath.toString().split('/').pop() : ""
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
                            value: encodingProgress
                            
                            background: Rectangle {
                                color: "#E0E0E0"
                                radius: 5
                            }
                            
                            contentItem: Item {
                                Rectangle {
                                    width: parent.width * (encodingProgress / 100)
                                    height: parent.height
                                    color: "#3498DB"
                                    radius: 5
                                    
                                    // Animated gradient
                                    SequentialAnimation on color {
                                        running: isEncoding
                                        loops: Animation.Infinite
                                        ColorAnimation { to: "#5DADE2"; duration: 1000 }
                                        ColorAnimation { to: "#3498DB"; duration: 1000 }
                                    }
                                }
                            }
                        }
                        
                        Label {
                            text: encodingProgress + "%"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#3498DB"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        BusyIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            running: isEncoding
                        }
                    }
                    
                    // Encoding Complete
                    ScrollView {
                        anchors.fill: parent
                        visible: !isEncoding && encodedImagePath !== ""
                        contentWidth: availableWidth
                        
                        ColumnLayout {
                            width: parent.width
                            spacing: 20
                            
                            // Success Message
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 80
                                color: "#D5F4E6"
                                radius: 8
                                border.color: "#27AE60"
                                border.width: 2
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 15
                                    spacing: 15
                                    
                                    Label {
                                        text: "✅"
                                        font.pixelSize: 40
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 5
                                        
                                        Label {
                                            text: "Encoding Complete!"
                                            font.pixelSize: 18
                                            font.bold: true
                                            color: "#27AE60"
                                        }
                                        
                                        Label {
                                            text: "Your file has been successfully encoded in the image"
                                            font.pixelSize: 12
                                            color: "#229954"
                                        }
                                    }
                                }
                            }
                            
                            // File Info
                            GroupBox {
                                title: "📄 Encoded File Information"
                                Layout.fillWidth: true
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 10
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        
                                        Label {
                                            text: "Original File:"
                                            font.bold: true
                                            color: "#2C3E50"
                                            Layout.preferredWidth: 120
                                        }
                                        
                                        Label {
                                            text: currentFilePath ? currentFilePath.toString().split('/').pop() : ""
                                            color: "#34495E"
                                            Layout.fillWidth: true
                                            wrapMode: Text.WrapAnywhere
                                        }
                                    }
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        
                                        Label {
                                            text: "Encoded Image:"
                                            font.bold: true
                                            color: "#2C3E50"
                                            Layout.preferredWidth: 120
                                        }
                                        
                                        Label {
                                            text: encodedImagePath ? encodedImagePath.split('/').pop() : ""
                                            color: "#3498DB"
                                            Layout.fillWidth: true
                                            wrapMode: Text.WrapAnywhere
                                        }
                                    }
                                    
                                    // Frame counter for multi-frame files
                                    RowLayout {
                                        Layout.fillWidth: true
                                        visible: encodedFrames.length > 1
                                        
                                        Label {
                                            text: "Frames:"
                                            font.bold: true
                                            color: "#2C3E50"
                                            Layout.preferredWidth: 120
                                        }
                                        
                                        Label {
                                            text: "Frame " + (currentFrameIndex + 1) + " / " + encodedFrames.length + " (slideshow active)"
                                            color: "#E74C3C"
                                            font.bold: true
                                        }
                                    }
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        
                                        Label {
                                            text: "Format:"
                                            font.bold: true
                                            color: "#2C3E50"
                                            Layout.preferredWidth: 120
                                        }
                                        
                                        Label {
                                            text: "1000×1000 PNG with border headers"
                                            color: "#34495E"
                                        }
                                    }
                                }
                            }
                            
                            // Preview (if available)
                            GroupBox {
                                title: "🖼️ Encoded Image Preview"
                                Layout.fillWidth: true
                                visible: encodedImagePath !== ""
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 10
                                    
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 300
                                        color: "#F8F9F9"
                                        border.color: "#BDC3C7"
                                        border.width: 1
                                        radius: 5
                                        
                                        Image {
                                            anchors.centerIn: parent
                                            source: encodedImagePath ? "file://" + encodedImagePath : ""
                                            fillMode: Image.PreserveAspectFit
                                            width: Math.min(parent.width - 20, 280)
                                            height: Math.min(parent.height - 20, 280)
                                            smooth: true
                                        }
                                    }
                                    
                                    Label {
                                        text: "This image contains your hidden file using LSB steganography"
                                        font.pixelSize: 10
                                        color: "#7F8C8D"
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                            
                            // Action Buttons
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                
                                Button {
                                    text: "📂 Open Output Folder"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    font.pixelSize: 13
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#2471A3" : parent.hovered ? "#2E86C1" : "#3498DB"
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
                                        var folder = encodedImagePath.substring(0, encodedImagePath.lastIndexOf('/'))
                                        Qt.openUrlExternally("file://" + folder)
                                    }
                                }
                                
                                Button {
                                    text: "🔄 Encode Another File"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    font.pixelSize: 13
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#1E8449" : parent.hovered ? "#229954" : "#27AE60"
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
                                        encodedImagePath = ""
                                        encodedFrames = []
                                        currentFrameIndex = 0
                                        currentFilePath = ""
                                        encodingProgress = 0
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // =====================================================================
    // Dialogs
    // =====================================================================
    
    // About Dialog
    Dialog {
        id: aboutDialog
        title: "About LSB Steganography"
        modal: true
        anchors.centerIn: parent
        width: 500
        
        ColumnLayout {
            spacing: 15
            width: parent.width
            
            Label {
                text: "🔒 LSB Steganography Tool"
                font.pixelSize: 20
                font.bold: true
                color: "#2C3E50"
            }
            
            Label {
                text: "Version 2.0 - Fixed 1000×1000 Format"
                font.pixelSize: 12
                color: "#7F8C8D"
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#BDC3C7"
            }
            
            Label {
                text: "Features:"
                font.bold: true
                color: "#34495E"
            }
            
            Label {
                text: "• Fixed 1000×1000 pixel format\n• Border-based headers (metadata in 2-pixel border)\n• Multi-frame support for large files (>744 KB)\n• Position-independent extraction\n• Fast detection via magic bytes\n• MD5 checksum validation"
                font.pixelSize: 11
                color: "#555555"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#BDC3C7"
            }
            
            Label {
                text: "How to use:"
                font.bold: true
                color: "#34495E"
            }
            
            Label {
                text: "1. Browse files in the left panel\n2. Click on any file to encode it\n3. Wait for the encoding process to complete\n4. View the result and open the output folder"
                font.pixelSize: 11
                color: "#555555"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#BDC3C7"
            }
            
            Label {
                text: "© 2025 - Steganography Research Project"
                font.pixelSize: 10
                color: "#95A5A6"
                Layout.alignment: Qt.AlignHCenter
            }
            
            Button {
                text: "Close"
                Layout.alignment: Qt.AlignHCenter
                onClicked: aboutDialog.close()
            }
        }
    }
    
    // =====================================================================
    // JavaScript Functions
    // =====================================================================
    
    function getFileIcon(fileName) {
        var ext = fileName.split('.').pop().toLowerCase()
        
        // Images
        if (["jpg", "jpeg", "png", "gif", "bmp", "svg"].includes(ext)) return "🖼️"
        
        // Documents
        if (["pdf", "doc", "docx", "txt", "rtf", "odt"].includes(ext)) return "📄"
        
        // Archives
        if (["zip", "rar", "7z", "tar", "gz"].includes(ext)) return "📦"
        
        // Videos
        if (["mp4", "avi", "mkv", "mov", "wmv"].includes(ext)) return "🎥"
        
        // Audio
        if (["mp3", "wav", "flac", "ogg", "m4a"].includes(ext)) return "🎵"
        
        // Code
        if (["js", "py", "cpp", "h", "java", "cs", "php"].includes(ext)) return "💻"
        
        return "📄"
    }
    
    function formatFileSize(bytes) {
        if (bytes < 1024) return bytes + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MB"
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB"
    }
    
    function startEncoding(filePath) {
        isEncoding = true
        encodingProgress = 0
        encodedImagePath = ""
        encodedFrames = []
        currentFrameIndex = 0
        
        // Get file path and output directory
        var filePathStr = filePath.toString().replace("file://", "")
        var outputDir = StandardPaths.writableLocation(StandardPaths.DownloadLocation).toString().replace("file://", "")
        
        console.log("Encoding file:", filePathStr)
        console.log("Output directory:", outputDir)
        
        // Call the actual SteganographyV2 backend
        var frames = steganographyV2.encodeFileInFrames(
            "file://" + filePathStr,
            "file://" + outputDir,
            ""  // auto-generate base name from filename
        )
        
        // Check if encoding started successfully
        if (frames.length === 0) {
            console.error("Failed to start encoding")
            isEncoding = false
            errorDialog.errorMessage = steganographyV2.lastError || "Failed to encode file"
            errorDialog.open()
        } else {
            console.log("Encoding started, generated", frames.length, "frame(s)")
            // The onEncodeComplete signal will handle completion
        }
    }
    
    // Error Dialog
    Dialog {
        id: errorDialog
        title: "Encoding Error"
        modal: true
        anchors.centerIn: parent
        width: 400
        
        property string errorMessage: ""
        
        ColumnLayout {
            spacing: 15
            width: parent.width
            
            Label {
                text: "❌ Failed to encode file"
                font.pixelSize: 16
                font.bold: true
                color: "#E74C3C"
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "#FADBD8"
                radius: 5
                border.color: "#E74C3C"
                border.width: 1
                
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 10
                    
                    Label {
                        text: errorDialog.errorMessage
                        font.pixelSize: 11
                        color: "#922B21"
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }
            
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                onClicked: errorDialog.close()
            }
        }
    }
}
