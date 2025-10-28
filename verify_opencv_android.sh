#!/bin/bash
# Verify OpenCV Android SDK setup for file_transfer_ovimage project

echo "=================================================="
echo "OpenCV Android SDK Verification"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_mark="${GREEN}✓${NC}"
cross_mark="${RED}✗${NC}"
warning_mark="${YELLOW}⚠${NC}"

errors=0

# Check 1: OpenCV SDK directory
echo -n "Checking OpenCV SDK directory... "
if [ -d "/home/hungkv/Android/OpenCV-android-sdk" ]; then
    echo -e "$check_mark"
else
    echo -e "$cross_mark"
    echo "  → Run: ./setup_opencv_android.sh"
    errors=$((errors + 1))
fi

# Check 2: ARM64-v8a configuration
echo -n "Checking ARM64-v8a CMake config... "
if [ -f "/home/hungkv/Android/OpenCV-android-sdk/sdk/native/jni/abi-arm64-v8a/OpenCVConfig.cmake" ]; then
    echo -e "$check_mark"
else
    echo -e "$cross_mark"
    errors=$((errors + 1))
fi

# Check 3: ARM64-v8a library
echo -n "Checking ARM64-v8a library... "
if [ -f "/home/hungkv/Android/OpenCV-android-sdk/sdk/native/libs/arm64-v8a/libopencv_java4.so" ]; then
    lib_size=$(du -h "/home/hungkv/Android/OpenCV-android-sdk/sdk/native/libs/arm64-v8a/libopencv_java4.so" | cut -f1)
    echo -e "$check_mark (${lib_size})"
else
    echo -e "$cross_mark"
    errors=$((errors + 1))
fi

# Check 4: OpenCV version
echo -n "Checking OpenCV version... "
if [ -f "/home/hungkv/Android/OpenCV-android-sdk/sdk/native/jni/abi-arm64-v8a/OpenCVConfig-version.cmake" ]; then
    version=$(grep "set(OpenCV_VERSION" "/home/hungkv/Android/OpenCV-android-sdk/sdk/native/jni/abi-arm64-v8a/OpenCVConfig-version.cmake" | grep -oP '\d+\.\d+\.\d+')
    echo -e "$check_mark v${version}"
else
    echo -e "$cross_mark"
    errors=$((errors + 1))
fi

# Check 5: Android NDK
echo -n "Checking Android NDK... "
if [ -d "/home/hungkv/Android/Sdk/ndk" ]; then
    ndk_version=$(ls /home/hungkv/Android/Sdk/ndk/ | head -1)
    echo -e "$check_mark ${ndk_version}"
else
    echo -e "$cross_mark"
    echo "  → Install Android NDK via Qt Creator or Android Studio"
    errors=$((errors + 1))
fi

# Check 6: Qt Android installation
echo -n "Checking Qt for Android... "
if [ -d "/home/hungkv/Qt/6.10.0/android_arm64_v8a" ]; then
    echo -e "$check_mark Qt 6.10.0"
else
    echo -e "$cross_mark"
    echo "  → Install Qt for Android via Qt Maintenance Tool"
    errors=$((errors + 1))
fi

# Check 7: CMakeLists.txt Android support
echo -n "Checking CMakeLists.txt Android config... "
if grep -q "if(ANDROID)" "/home/hungkv/projects/file_transfer_ovimage/CMakeLists.txt"; then
    echo -e "$check_mark"
else
    echo -e "$cross_mark"
    echo "  → CMakeLists.txt needs Android OpenCV configuration"
    errors=$((errors + 1))
fi

# Check 8: All supported ABIs
echo ""
echo "Supported Android ABIs:"
for abi in "arm64-v8a" "armeabi-v7a" "x86" "x86_64"; do
    echo -n "  - $abi: "
    if [ -d "/home/hungkv/Android/OpenCV-android-sdk/sdk/native/jni/abi-${abi}" ]; then
        echo -e "$check_mark"
    else
        echo -e "$cross_mark"
    fi
done

echo ""
echo "=================================================="
if [ $errors -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Ready to build for Android!"
    echo ""
    echo "Next steps in Qt Creator:"
    echo "  1. Projects → Android arm64-v8a kit"
    echo "  2. Build Settings → CMake → Initial Configuration"
    echo "  3. Add: OpenCV_DIR:PATH=/home/hungkv/Android/OpenCV-android-sdk/sdk/native/jni/abi-arm64-v8a"
    echo "  4. Right-click project → Run CMake"
    echo "  5. Build (Ctrl+B)"
else
    echo -e "${RED}✗ Found $errors error(s)${NC}"
    echo ""
    echo "Please fix the issues above before building."
fi
echo "=================================================="

exit $errors
