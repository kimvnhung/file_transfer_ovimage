import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Qt.labs.folderlistmodel
import "FileIconHelper.js" as FileHelper

Rectangle {
    id: root
    
    property string currentPath: folderModel.folder.toString()
    signal fileSelected(url fileUrl, string filePath)
    signal helpRequested()
    
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
                
                onClicked: root.helpRequested()
            }
        }
        
        // Search Bar
        SearchBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 35
            placeholderText: "Search files..."
            onTextChanged: function(text) {
                folderModel.nameFilters = text ? ["*" + text + "*"] : ["*"]
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
                            if (parent.down) return "#3498DB"
                            if (parent.hovered) return "#34495E"
                            return "transparent"
                        }
                        radius: 3
                    }
                    
                    contentItem: RowLayout {
                        spacing: 10
                        
                        Label {
                            text: fileIsDir ? "📁" : FileHelper.getFileIcon(fileName)
                            font.pixelSize: 16
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            
                            Label {
                                text: fileName
                                font.pixelSize: 12
                                color: "#ECF0F1"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            
                            Label {
                                visible: !fileIsDir
                                text: FileHelper.formatFileSize(fileSize)
                                font.pixelSize: 9
                                color: "#95A5A6"
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
                            root.fileSelected(fileUrl, fileUrl.toString())
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
