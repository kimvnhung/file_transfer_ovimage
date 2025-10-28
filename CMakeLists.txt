# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

cmake_minimum_required(VERSION 3.16)
project(file_transfer_ovimage LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Multimedia Qml Quick)
find_package(OpenCV REQUIRED)

qt_add_executable(file_transfer_ovimage
    qmlcamera.cpp
)

set_target_properties(file_transfer_ovimage PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in
)

qt_add_ios_ffmpeg_libraries(file_transfer_ovimage)

set(OPENCV_PLAYER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/opencv_player")
file(GLOB_RECURSE OPENCV_PLAYER_QML_FILES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "${OPENCV_PLAYER_DIR}/*.qml")
file(GLOB_RECURSE OPENCV_PLAYER_SRC_FILES "${OPENCV_PLAYER_DIR}/*.cpp")
file(GLOB_RECURSE OPENCV_PLAYER_HEADER_FILES "${OPENCV_PLAYER_DIR}/*.h")

qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

qt_add_qml_module(opencv_player
    URI opencv_player
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/qml/opencv_player"
    QML_FILES
        ${OPENCV_PLAYER_QML_FILES}
    SOURCES
        ${OPENCV_PLAYER_SRC_FILES}
        ${OPENCV_PLAYER_HEADER_FILES}
)

target_link_libraries(file_transfer_ovimage
    PUBLIC
        Qt::Core
        Qt::Gui
        Qt::Multimedia
        Qt::Qml
        Qt::Quick
        opencv_player
)

# Link OpenCV to the opencv_player module
target_link_libraries(opencv_player PRIVATE ${OpenCV_LIBS})
target_include_directories(opencv_player PRIVATE ${OpenCV_INCLUDE_DIRS})

# Resources:
set(file_transfer_ovimage_resource_files
    "CameraButton.qml"
    "CameraListButton.qml"
    "CameraListPopup.qml"
    "CameraPropertyButton.qml"
    "CameraPropertyPopup.qml"
    "FlashControl.qml"
    "PhotoCaptureControls.qml"
    "PhotoPreview.qml"
    "Popup.qml"
    "VideoCaptureControls.qml"
    "VideoPreview.qml"
    "ZoomControl.qml"
    "declarative-camera.qml"
    "images/camera_auto_mode.png"
    "images/camera_camera_setting.png"
    "images/camera_flash_auto.png"
    "images/camera_flash_fill.png"
    "images/camera_flash_off.png"
    "images/camera_flash_redeye.png"
    "images/camera_white_balance_cloudy.png"
    "images/camera_white_balance_flourescent.png"
    "images/camera_white_balance_incandescent.png"
    "images/camera_white_balance_sunny.png"
    "images/toolbutton.png"
    "images/toolbutton.sci"
)

qt_add_resources(file_transfer_ovimage "file_transfer_ovimage"
    PREFIX
        "/"
    FILES
        ${file_transfer_ovimage_resource_files}
)

# install(TARGETS file_transfer_ovimage
#     RUNTIME DESTINATION "${INSTALL_EXAMPLEDIR}"
#     BUNDLE DESTINATION "${INSTALL_EXAMPLEDIR}"
#     LIBRARY DESTINATION "${INSTALL_EXAMPLEDIR}"
# )
