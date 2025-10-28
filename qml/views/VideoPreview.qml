// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import opencv_player

Item {
    id: videoPreview
    property alias source : openCV_Player.videoUrl
    signal closed

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

                    Item { Layout.fillWidth: true }

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

