#!/bin/bash

# Android Build Script - Build APK without Qt Creator
# Uses cmake, ninja, and Android SDK/NDK directly

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[BUILD]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[BUILD]${NC} $1"
}

log_error() {
    echo -e "${RED}[BUILD]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[BUILD]${NC} $1"
}

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}║          📱 ANDROID APK BUILD SYSTEM 📱                   ║${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Configuration
QT_VERSION="${QT_VERSION:-6.10.0}"
ANDROID_ABI="${ANDROID_ABI:-arm64-v8a}"
BUILD_TYPE="${BUILD_TYPE:-Debug}"
BUILD_DIR="$PROJECT_ROOT/build/Android_Qt_${QT_VERSION}_Clang_${ANDROID_ABI}-${BUILD_TYPE}"

# Detect Qt installation
detect_qt() {
    log "Detecting Qt installation..."
    
    # Common Qt paths
    QT_PATHS=(
        "$HOME/Qt/${QT_VERSION}/android_${ANDROID_ABI}"
        "/opt/Qt/${QT_VERSION}/android_${ANDROID_ABI}"
        "/usr/local/Qt/${QT_VERSION}/android_${ANDROID_ABI}"
    )
    
    for path in "${QT_PATHS[@]}"; do
        if [ -d "$path" ]; then
            QT_ANDROID_PATH="$path"
            log_success "Found Qt: $QT_ANDROID_PATH"
            return 0
        fi
    done
    
    log_error "Qt ${QT_VERSION} for Android not found"
    log "Please install Qt or set QT_ANDROID_PATH environment variable"
    return 1
}

# Detect Android SDK
detect_android_sdk() {
    log "Detecting Android SDK..."
    
    if [ -n "$ANDROID_SDK_ROOT" ]; then
        log_success "Using ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
        return 0
    fi
    
    # Try common paths
    ANDROID_SDK_PATHS=(
        "$HOME/Android/Sdk"
        "$HOME/android-sdk"
        "/opt/android-sdk"
    )
    
    for path in "${ANDROID_SDK_PATHS[@]}"; do
        if [ -d "$path" ]; then
            export ANDROID_SDK_ROOT="$path"
            log_success "Found Android SDK: $ANDROID_SDK_ROOT"
            return 0
        fi
    done
    
    log_error "Android SDK not found"
    log "Please install Android SDK or set ANDROID_SDK_ROOT"
    return 1
}

# Detect Android NDK
detect_android_ndk() {
    log "Detecting Android NDK..."
    
    if [ -n "$ANDROID_NDK_ROOT" ]; then
        log_success "Using ANDROID_NDK_ROOT: $ANDROID_NDK_ROOT"
        return 0
    fi
    
    # Try to find NDK in SDK
    if [ -d "$ANDROID_SDK_ROOT/ndk" ]; then
        # Get latest NDK version
        NDK_VERSION=$(ls -1 "$ANDROID_SDK_ROOT/ndk" | sort -V | tail -1)
        if [ -n "$NDK_VERSION" ]; then
            export ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/$NDK_VERSION"
            log_success "Found Android NDK: $ANDROID_NDK_ROOT"
            return 0
        fi
    fi
    
    log_error "Android NDK not found"
    log "Please install Android NDK via SDK Manager"
    return 1
}

# Configure with cmake
configure_build() {
    log "Configuring build..."
    
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Set Qt cmake path
    export CMAKE_PREFIX_PATH="$QT_ANDROID_PATH"
    
    # Configure cmake
    cmake "$PROJECT_ROOT" \
        -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DANDROID_ABI="$ANDROID_ABI" \
        -DANDROID_PLATFORM=android-28 \
        -DANDROID_STL=c++_shared \
        -DCMAKE_FIND_ROOT_PATH="$QT_ANDROID_PATH" \
        -DQT_HOST_PATH="$HOME/Qt/${QT_VERSION}/gcc_64" \
        -DQT_ANDROID_BUILD_ALL_ABIS=OFF \
        -DQT_ANDROID_ABIS="$ANDROID_ABI" \
        -G Ninja
    
    if [ $? -eq 0 ]; then
        log_success "Configuration successful"
        return 0
    else
        log_error "Configuration failed"
        return 1
    fi
}

# Build the project
build_project() {
    log "Building project..."
    
    cd "$BUILD_DIR"
    
    cmake --build . --parallel $(nproc)
    
    if [ $? -eq 0 ]; then
        log_success "Build successful"
        return 0
    else
        log_error "Build failed"
        return 1
    fi
}

# Create APK
create_apk() {
    log "Creating APK..."
    
    cd "$BUILD_DIR"
    
    # Run androiddeployqt
    "$QT_ANDROID_PATH/bin/androiddeployqt" \
        --input android-file_transfer_ovimage-deployment-settings.json \
        --output android-build-file_transfer_ovimage \
        --android-platform android-28 \
        --gradle
    
    if [ $? -eq 0 ]; then
        # Find the generated APK
        APK=$(find "$BUILD_DIR/android-build-file_transfer_ovimage" -name "*.apk" -type f | head -1)
        
        if [ -f "$APK" ]; then
            log_success "APK created: $APK"
            
            # Copy to convenient location
            cp "$APK" "$PROJECT_ROOT/file_transfer_ovimage-${BUILD_TYPE}.apk"
            log_success "APK copied to: $PROJECT_ROOT/file_transfer_ovimage-${BUILD_TYPE}.apk"
            return 0
        else
            log_error "APK file not found"
            return 1
        fi
    else
        log_error "APK creation failed"
        return 1
    fi
}

# Main execution
main() {
    log "Starting Android build process..."
    log "Qt Version: $QT_VERSION"
    log "Android ABI: $ANDROID_ABI"
    log "Build Type: $BUILD_TYPE"
    echo ""
    
    # Check prerequisites
    if ! detect_qt; then
        exit 1
    fi
    
    if ! detect_android_sdk; then
        exit 1
    fi
    
    if ! detect_android_ndk; then
        exit 1
    fi
    
    echo ""
    
    # Build steps
    if ! configure_build; then
        exit 1
    fi
    
    echo ""
    
    if ! build_project; then
        exit 1
    fi
    
    echo ""
    
    if ! create_apk; then
        exit 1
    fi
    
    echo ""
    log_success "✅ Android build completed successfully!"
    echo ""
}

main
