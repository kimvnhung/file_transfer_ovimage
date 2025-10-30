// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import opencv_player

Item {
    id: videoPreview
    property alias source : openCV_Player.videoUrl
    signal closed

    // Extraction properties
    property bool extractionMode: false
    property int framesDetected: 0
    property int framesExtracted: 0
    property string lastDetectionTime: ""
    
    SteganographyV2 {
        id: steganographyV2
    }

    OpenCV_VideoPlayer {
        id: openCV_Player
        viewPort: openCV_ViewPort
        
        //switch back to viewfinder after playback finished
        onVideoFinished: {
            openCV_Player.setPlaybackState(OpenCV_VideoPlayer.StoppedState)
            videoPreview.closed()
        }
        
        onVideoUrlChanged: {
            if (videoPreview.visible && videoUrl.toString() !== "") {
                openCV_Player.setPlaybackState(OpenCV_VideoPlayer.PlayingState)
            }
        }
        
        // Real-time frame processing
        onFrameReady: function(frame) {
            if (extractionMode && frame.width > 0 && frame.height > 0) {
                // Check if this frame contains an encoded image
                if (steganographyV2.isValidFrameImage(frame)) {
                    framesDetected++
                    lastDetectionTime = Qt.formatTime(new Date(), "hh:mm:ss")
                    
                    // Show detection overlay
                    detectionOverlay.visible = true
                    detectionOverlay.opacity = 1.0
                    flashAnimation.start()
                    
                    // Save the detected frame
                    var outputDir = StandardPaths.writableLocation(StandardPaths.DownloadLocation).toString().replace("file://", "")
                    var timestamp = Date.now()
                    var outputPath = outputDir + "/detected_frame_" + timestamp + ".png"
                    
                    if (frame.save(outputPath, "PNG")) {
                        framesExtracted++
                        console.log("Saved detected frame to:", outputPath)
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Video viewport
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Item {
                id: videoRatioBox
                anchors.centerIn: parent
                property real orgVidRatio: openCV_Player.inputResulation.width > 0 ? 
                                          openCV_Player.inputResulation.width / openCV_Player.inputResulation.height : 16/9
                property real parentRatio: parent.width / parent.height

                width: orgVidRatio >= parentRatio ? parent.width : parent.height * orgVidRatio
                height: orgVidRatio >= parentRatio ? parent.width / orgVidRatio : parent.height

                OpenCV_Player_ViewPort {
                    id: openCV_ViewPort
                    anchors.fill: parent
                }
                
                // Detection overlay
                Rectangle {
                    id: detectionOverlay
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "#2ECC71"
                    border.width: 8
                    radius: 10
                    visible: false
                    
                    Text {
                        anchors.centerIn: parent
                        text: "✓ VALID FRAME DETECTED!"
                        color: "#2ECC71"
                        font.pixelSize: 24
                        font.bold: true
                        style: Text.Outline
                        styleColor: "black"
                    }
                    
                    SequentialAnimation {
                        id: flashAnimation
                        loops: 3
                        PropertyAnimation {
                            target: detectionOverlay
                            property: "opacity"
                            from: 1.0
                            to: 0.3
                            duration: 200
                        }
                        PropertyAnimation {
                            target: detectionOverlay
                            property: "opacity"
                            from: 0.3
                            to: 1.0
                            duration: 200
                        }
                        onStopped: {
                            detectionOverlay.visible = false
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (openCV_Player.playbackState === OpenCV_VideoPlayer.PlayingState) {
                        openCV_Player.setPlaybackState(OpenCV_VideoPlayer.PausedState)
                    } else if (openCV_Player.playbackState === OpenCV_VideoPlayer.PausedState) {
                        openCV_Player.setPlaybackState(OpenCV_VideoPlayer.PlayingState)
                    }
                }
                onDoubleClicked: {
                    videoPreview.closed()
                }
            }
        }

        // Playback controls
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: Qt.rgba(0.08, 0.08, 0.08, 0.9)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                // Progress bar
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10

                    Rectangle {
                        anchors.fill: parent
                        color: "lightGray"
                        radius: 5

                        Rectangle {
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                            }
                            color: "#757575"
                            radius: 5
                            width: openCV_Player.frameNumber > 0 && openCV_Player.videoFrameCount > 0 ?
                                       parent.width * openCV_Player.frameNumber / openCV_Player.videoFrameCount : 0
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (openCV_Player.videoFrameCount > 0) {
                                    var frameNum = Math.floor(openCV_Player.videoFrameCount * mouse.x / width)
                                    openCV_Player.setFrameNumber(frameNum)
                                }
                            }
                        }
                    }
                }

                // Control buttons and info
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "Frame: " + openCV_Player.frameNumber + " / " + openCV_Player.videoFrameCount
                        color: "white"
                        font.pixelSize: 12
                    }
                    
                    // Extraction status
                    Text {
                        visible: extractionMode
                        text: "✓ Detected: " + framesDetected + " | Saved: " + framesExtracted
                        color: "#2ECC71"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }
                    
                    // Extraction mode toggle
                    Rectangle {
                        width: 100
                        height: 30
                        radius: 5
                        color: extractionMode ? "#2ECC71" : "#333333"
                        border.color: extractionMode ? "#27AE60" : "#555555"
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: extractionMode ? "🔍 Detecting..." : "🔍 Detect"
                            color: "white"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                extractionMode = !extractionMode
                                if (extractionMode) {
                                    framesDetected = 0
                                    framesExtracted = 0
                                }
                            }
                        }
                    }

                    // Previous frame button
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 5
                        color: prevMouseArea.pressed ? "#555555" : "#333333"

                        Text {
                            anchors.centerIn: parent
                            text: "◄"
                            color: "white"
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: prevMouseArea
                            anchors.fill: parent
                            onClicked: {
                                openCV_Player.setFrameNumber(openCV_Player.frameNumber - 1)
                            }
                        }
                    }

                    // Play/Pause button
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 5
                        color: playMouseArea.pressed ? "#555555" : "#333333"

                        Text {
                            anchors.centerIn: parent
                            text: openCV_Player.playbackState === OpenCV_VideoPlayer.PlayingState ? "❚❚" : "►"
                            color: "white"
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: playMouseArea
                            anchors.fill: parent
                            onClicked: {
                                if (openCV_Player.playbackState === OpenCV_VideoPlayer.PlayingState) {
                                    openCV_Player.setPlaybackState(OpenCV_VideoPlayer.PausedState)
                                } else {
                                    openCV_Player.setPlaybackState(OpenCV_VideoPlayer.PlayingState)
                                }
                            }
                        }
                    }

                    // Next frame button
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 5
                        color: nextMouseArea.pressed ? "#555555" : "#333333"

                        Text {
                            anchors.centerIn: parent
                            text: "►"
                            color: "white"
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: nextMouseArea
                            anchors.fill: parent
                            onClicked: {
                                openCV_Player.setFrameNumber(openCV_Player.frameNumber + 1)
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Close button
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 5
                        color: closeMouseArea.pressed ? "#555555" : "#333333"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: "white"
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: closeMouseArea
                            anchors.fill: parent
                            onClicked: {
                                videoPreview.closed()
                            }
                        }
                    }
                }
            }
        }
    }
}

