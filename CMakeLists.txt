# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

cmake_minimum_required(VERSION 3.16)
project(file_transfer_ovimage VERSION 1.0.0 LANGUAGES CXX)

# ============================================================================
# Project Configuration
# ============================================================================
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Build Mode Configuration
option(DESKTOP_MODE "Build for desktop with simplified UI" OFF)

if(DESKTOP_MODE)
    add_definitions(-DDESKTOP_MODE)
    message(STATUS "Building in DESKTOP MODE - Simplified UI for testing")
else()
    message(STATUS "Building in MOBILE MODE - Full mobile UI")
endif()

# ============================================================================
# Find Required Packages
# ============================================================================
find_package(Qt6 REQUIRED COMPONENTS 
    Core 
    Gui 
    Multimedia 
    Qml 
    Quick
)

# Tesseract OCR Configuration (Desktop only)
if(NOT ANDROID)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(TESSERACT REQUIRED tesseract)
    pkg_check_modules(LEPTONICA REQUIRED lept)
    add_definitions(-DUSE_TESSERACT)
    message(STATUS "Tesseract OCR enabled for desktop build")
else()
    message(STATUS "Tesseract OCR disabled for Android build")
endif()

# OpenCV Configuration
if(ANDROID)
    # For Android builds, you need to set OpenCV_DIR to the Android SDK path
    # Download OpenCV Android SDK from https://opencv.org/releases/
    # Extract to a location and set the path below
    if(NOT DEFINED OpenCV_DIR)
        set(OpenCV_DIR "$ENV{HOME}/Android/OpenCV-android-sdk/sdk/native/jni" CACHE PATH "OpenCV Android SDK directory")
    endif()
    
    # Set OpenCV Android ABI
    if(ANDROID_ABI STREQUAL "arm64-v8a")
        set(OpenCV_DIR "${OpenCV_DIR}/abi-arm64-v8a")
    elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
        set(OpenCV_DIR "${OpenCV_DIR}/abi-armeabi-v7a")
    elseif(ANDROID_ABI STREQUAL "x86")
        set(OpenCV_DIR "${OpenCV_DIR}/abi-x86")
    elseif(ANDROID_ABI STREQUAL "x86_64")
        set(OpenCV_DIR "${OpenCV_DIR}/abi-x86_64")
    endif()
    
    message(STATUS "Android build detected")
    message(STATUS "OpenCV_DIR: ${OpenCV_DIR}")
    message(STATUS "ANDROID_ABI: ${ANDROID_ABI}")
endif()

find_package(OpenCV REQUIRED)

# ============================================================================
# Include Directories
# ============================================================================
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/app
    ${CMAKE_CURRENT_SOURCE_DIR}/include/opencv_player
)

if(NOT ANDROID)
    include_directories(
        ${TESSERACT_INCLUDE_DIRS}
        ${LEPTONICA_INCLUDE_DIRS}
    )
endif()

# ============================================================================
# Source Files
# ============================================================================
set(APP_SOURCES
    src/app/main.cpp
    src/app/tesseractocr.cpp
)

set(APP_HEADERS
    include/app/tesseractocr.h
)

set(OPENCV_PLAYER_SOURCES
    src/opencv_player/opencv_videoplayer.cpp
    src/opencv_player/opencv_player_viewport.cpp
)

set(OPENCV_PLAYER_HEADERS
    include/opencv_player/opencv_videoplayer.h
    include/opencv_player/opencv_player_viewport.h
)

# ============================================================================
# QML Files Organization
# ============================================================================
set(QML_VIEWS
    qml/views/AppMain.qml
    qml/views/MainView.qml
    qml/views/PermissionDenied.qml
    qml/views/PhotoPreview.qml
    qml/views/VideoPreview.qml
    qml/views/HomePage.qml
    qml/views/OCRPage.qml
    qml/views/DesktopTestView.qml
)

set(QML_CONTROLS
    qml/controls/PhotoCaptureControls.qml
    qml/controls/VideoCaptureControls.qml
    qml/controls/ZoomControl.qml
    qml/controls/FlashControl.qml
)

set(QML_COMPONENTS
    qml/components/CameraButton.qml
    qml/components/CameraListButton.qml
    qml/components/CameraPropertyButton.qml
    qml/components/OCRCameraView.qml
)

set(QML_DIALOGS
    qml/dialogs/Popup.qml
    qml/dialogs/CameraListPopup.qml
    qml/dialogs/CameraPropertyPopup.qml
)

# ============================================================================
# Resource Files
# ============================================================================
set(RESOURCE_FILES
    resources/images/camera_auto_mode.png
    resources/images/camera_camera_setting.png
    resources/images/camera_flash_auto.png
    resources/images/camera_flash_fill.png
    resources/images/camera_flash_off.png
    resources/images/camera_flash_redeye.png
    resources/images/camera_white_balance_cloudy.png
    resources/images/camera_white_balance_flourescent.png
    resources/images/camera_white_balance_incandescent.png
    resources/images/camera_white_balance_sunny.png
    resources/images/toolbutton.png
    resources/images/toolbutton.sci
)

# ============================================================================
# Main Executable
# ============================================================================
qt_add_executable(file_transfer_ovimage
    ${APP_SOURCES}
    ${APP_HEADERS}
)

set_target_properties(file_transfer_ovimage PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in
)

qt_add_ios_ffmpeg_libraries(file_transfer_ovimage)

# ============================================================================
# Qt Policies
# ============================================================================
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

# ============================================================================
# OpenCV Player QML Module
# ============================================================================
qt_add_qml_module(opencv_player
    URI opencv_player
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/qml/opencv_player"
    QML_FILES
        ${QML_VIEWS}
    SOURCES
        ${OPENCV_PLAYER_SOURCES}
        ${OPENCV_PLAYER_HEADERS}
)

# Link OpenCV to the opencv_player module
target_link_libraries(opencv_player 
    PRIVATE 
        ${OpenCV_LIBS}
        Qt::Core
        Qt::Quick
)
target_include_directories(opencv_player 
    PRIVATE 
        ${OpenCV_INCLUDE_DIRS}
        ${CMAKE_CURRENT_SOURCE_DIR}/include/opencv_player
)

# ============================================================================
# Main Application QML Resources
# ============================================================================
qt_add_resources(file_transfer_ovimage "app_resources"
    PREFIX "/"
    FILES
        ${QML_VIEWS}
        ${QML_CONTROLS}
        ${QML_COMPONENTS}
        ${QML_DIALOGS}
        ${RESOURCE_FILES}
)

# ============================================================================
# Link Libraries
# ============================================================================
target_link_libraries(file_transfer_ovimage
    PRIVATE
        Qt::Core
        Qt::Gui
        Qt::Multimedia
        Qt::Qml
        Qt::Quick
        opencv_player
)

if(NOT ANDROID)
    target_link_libraries(file_transfer_ovimage
        PRIVATE
            ${TESSERACT_LIBRARIES}
            ${LEPTONICA_LIBRARIES}
    )
endif()

# ============================================================================
# Installation (Optional)
# ============================================================================
# install(TARGETS file_transfer_ovimage
#     RUNTIME DESTINATION bin
#     BUNDLE DESTINATION .
#     LIBRARY DESTINATION lib
# )

# ============================================================================
# Print Configuration Summary
# ============================================================================
message(STATUS "==============================================")
message(STATUS "File Transfer Over Image - Build Configuration")
message(STATUS "==============================================")
message(STATUS "Qt Version: ${Qt6_VERSION}")
message(STATUS "OpenCV Version: ${OpenCV_VERSION}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Install Prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "==============================================")
