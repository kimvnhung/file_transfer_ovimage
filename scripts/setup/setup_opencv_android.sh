#!/bin/bash
# Setup script to download and configure OpenCV Android SDK

set -e

OPENCV_VERSION="4.10.0"
OPENCV_ANDROID_DIR="$HOME/Android/OpenCV-android-sdk"
DOWNLOAD_URL="https://github.com/opencv/opencv/releases/download/${OPENCV_VERSION}/opencv-${OPENCV_VERSION}-android-sdk.zip"
DOWNLOAD_FILE="/tmp/opencv-android-sdk.zip"

echo "=================================================="
echo "OpenCV Android SDK Setup"
echo "=================================================="
echo "Version: ${OPENCV_VERSION}"
echo "Install Location: ${OPENCV_ANDROID_DIR}"
echo "=================================================="

# Create Android directory if it doesn't exist
mkdir -p "$HOME/Android"

# Check if already installed
if [ -d "${OPENCV_ANDROID_DIR}" ]; then
    echo "OpenCV Android SDK already exists at ${OPENCV_ANDROID_DIR}"
    read -p "Do you want to reinstall? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping installation."
        exit 0
    fi
    rm -rf "${OPENCV_ANDROID_DIR}"
fi

# Download OpenCV Android SDK
echo "Downloading OpenCV Android SDK ${OPENCV_VERSION}..."
wget -O "${DOWNLOAD_FILE}" "${DOWNLOAD_URL}" || {
    echo "Error: Failed to download OpenCV Android SDK"
    echo "Please download manually from: ${DOWNLOAD_URL}"
    echo "And extract to: ${OPENCV_ANDROID_DIR}"
    exit 1
}

# Extract the SDK
echo "Extracting OpenCV Android SDK..."
unzip -q "${DOWNLOAD_FILE}" -d "$HOME/Android/" || {
    echo "Error: Failed to extract OpenCV Android SDK"
    exit 1
}

# Rename the extracted directory
mv "$HOME/Android/OpenCV-android-sdk" "${OPENCV_ANDROID_DIR}" 2>/dev/null || true

# Clean up
rm -f "${DOWNLOAD_FILE}"

echo "=================================================="
echo "OpenCV Android SDK installed successfully!"
echo "=================================================="
echo "SDK Location: ${OPENCV_ANDROID_DIR}"
echo ""
echo "Available ABIs:"
ls -1 "${OPENCV_ANDROID_DIR}/sdk/native/jni/" | grep abi
echo ""
echo "To use with CMake, set:"
echo "  OpenCV_DIR=${OPENCV_ANDROID_DIR}/sdk/native/jni"
echo "=================================================="

# Verify installation
if [ -d "${OPENCV_ANDROID_SDK}/sdk/native/jni/abi-arm64-v8a" ]; then
    echo "✓ ARM64-v8a support confirmed"
else
    echo "⚠ Warning: ARM64-v8a directory not found"
fi

exit 0
