#!/bin/bash
# Local CI/CD build script for Android

set -e

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build/ci-android"
REPORTS_DIR="${PROJECT_ROOT}/ci-reports"
ABI="${ANDROID_ABI:-arm64-v8a}"
BUILD_TYPE="${BUILD_TYPE:-Release}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create directories
mkdir -p "${BUILD_DIR}"
mkdir -p "${REPORTS_DIR}"

log_info "========================================"
log_info "Android CI/CD Build"
log_info "========================================"
log_info "Project: file_transfer_ovimage"
log_info "ABI: ${ABI}"
log_info "Build Type: ${BUILD_TYPE}"
log_info "========================================"

# Step 1: Environment Check
log_info "Step 1: Checking environment..."

if [ -z "${ANDROID_NDK}" ]; then
    log_error "ANDROID_NDK not set"
    exit 1
fi

if [ -z "${Qt6_DIR}" ] && [ ! -d "${HOME}/Qt/6.10.0/android_arm64_v8a" ]; then
    log_error "Qt6 for Android not found"
    exit 1
fi

if [ ! -d "${HOME}/Android/OpenCV-android-sdk" ]; then
    log_warning "OpenCV Android SDK not found, downloading..."
    bash "${PROJECT_ROOT}/setup_opencv_android.sh"
fi

log_success "Environment check passed"

# Step 2: Clean previous build
log_info "Step 2: Cleaning previous build..."
rm -rf "${BUILD_DIR}/*"
log_success "Clean completed"

# Step 3: Configure CMake
log_info "Step 3: Configuring CMake..."

cd "${BUILD_DIR}"

QT6_PATH="${Qt6_DIR:-${HOME}/Qt/6.10.0/android_arm64_v8a/lib/cmake/Qt6}"
OPENCV_PATH="${HOME}/Android/OpenCV-android-sdk/sdk/native/jni/abi-${ABI}"

cmake "${PROJECT_ROOT}" \
    -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK}/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="${ABI}" \
    -DANDROID_PLATFORM=android-23 \
    -DANDROID_NDK="${ANDROID_NDK}" \
    -DANDROID_STL=c++_shared \
    -DQt6_DIR="${QT6_PATH}" \
    -DOpenCV_DIR="${OPENCV_PATH}" \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    2>&1 | tee "${REPORTS_DIR}/cmake-configure.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log_error "CMake configuration failed"
    exit 1
fi

log_success "CMake configuration completed"

# Step 4: Build
log_info "Step 4: Building project..."

cmake --build . -j$(nproc) 2>&1 | tee "${REPORTS_DIR}/build.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log_error "Build failed"
    exit 1
fi

log_success "Build completed"

# Step 5: Find APK
log_info "Step 5: Locating APK..."

APK_PATH=$(find "${BUILD_DIR}" -name "*.apk" | head -n 1)

if [ -z "${APK_PATH}" ]; then
    log_error "APK not found"
    exit 1
fi

log_success "APK found: ${APK_PATH}"

# Copy APK to reports directory
cp "${APK_PATH}" "${REPORTS_DIR}/app-${ABI}-${BUILD_TYPE}.apk"
log_info "APK copied to: ${REPORTS_DIR}/app-${ABI}-${BUILD_TYPE}.apk"

# Step 6: APK Info
log_info "Step 6: APK Information..."

if command -v aapt &> /dev/null; then
    aapt dump badging "${APK_PATH}" > "${REPORTS_DIR}/apk-info.txt"
    
    echo ""
    log_info "APK Details:"
    echo "  Package: $(grep "package:" "${REPORTS_DIR}/apk-info.txt" | sed "s/.*name='\([^']*\)'.*/\1/")"
    echo "  Version: $(grep "package:" "${REPORTS_DIR}/apk-info.txt" | sed "s/.*versionName='\([^']*\)'.*/\1/")"
    echo "  Size: $(du -h "${APK_PATH}" | cut -f1)"
fi

# Step 7: Static Analysis (optional)
log_info "Step 7: Running static analysis..."

if command -v cppcheck &> /dev/null; then
    cppcheck --enable=all --inconclusive --xml --xml-version=2 \
        "${PROJECT_ROOT}/src" "${PROJECT_ROOT}/include" \
        2> "${REPORTS_DIR}/cppcheck-report.xml" || true
    log_success "Static analysis completed"
else
    log_warning "cppcheck not installed, skipping"
fi

# Step 8: Generate build report
log_info "Step 8: Generating build report..."

cat > "${REPORTS_DIR}/build-report.txt" << EOF
========================================
Android CI/CD Build Report
========================================
Date: $(date)
Project: file_transfer_ovimage
ABI: ${ABI}
Build Type: ${BUILD_TYPE}
========================================

Build Status: SUCCESS
APK Location: ${REPORTS_DIR}/app-${ABI}-${BUILD_TYPE}.apk
APK Size: $(du -h "${APK_PATH}" | cut -f1)

Build Logs:
- CMake Configure: ${REPORTS_DIR}/cmake-configure.log
- Build Log: ${REPORTS_DIR}/build.log
- Static Analysis: ${REPORTS_DIR}/cppcheck-report.xml
- APK Info: ${REPORTS_DIR}/apk-info.txt

========================================
EOF

cat "${REPORTS_DIR}/build-report.txt"

log_success "========================================"
log_success "Build completed successfully!"
log_success "========================================"
log_info "APK: ${REPORTS_DIR}/app-${ABI}-${BUILD_TYPE}.apk"
log_info "Reports: ${REPORTS_DIR}/"
log_success "========================================"

exit 0
