#!/bin/bash

# Local Self-Healing Build Script
# Wraps the build process with automatic error detection and fixing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${CYAN}[SELF-HEAL]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Configuration
MAX_ATTEMPTS=3
ABI="${ANDROID_ABI:-arm64-v8a}"
BUILD_DIR="$PROJECT_ROOT/build/android-$ABI"
LOGS_DIR="$PROJECT_ROOT/ci-reports/self-heal"

# Create logs directory
mkdir -p "$LOGS_DIR"

echo ""
echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║                                                           ║${NC}"
echo -e "${MAGENTA}║          🤖 SELF-HEALING BUILD SYSTEM 🤖                  ║${NC}"
echo -e "${MAGENTA}║                                                           ║${NC}"
echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

log_info "Project: file_transfer_ovimage"
log_info "ABI: $ABI"
log_info "Max attempts: $MAX_ATTEMPTS"
log_info "Build directory: $BUILD_DIR"
echo ""

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    MISSING=()
    
    if ! command -v cmake &> /dev/null; then
        MISSING+=("cmake")
    fi
    
    if [ -z "$ANDROID_SDK_ROOT" ] && [ -z "$ANDROID_HOME" ]; then
        MISSING+=("Android SDK (set ANDROID_SDK_ROOT)")
    fi
    
    if [ ! -d "$HOME/Qt/6.10.0/android_arm64_v8a" ]; then
        MISSING+=("Qt 6.10.0 for Android")
    fi
    
    if [ ! -d "$HOME/Android/OpenCV-android-sdk" ]; then
        log_warning "OpenCV Android SDK not found - will attempt download"
    fi
    
    if [ ${#MISSING[@]} -gt 0 ]; then
        log_error "Missing prerequisites:"
        for item in "${MISSING[@]}"; do
            echo "  - $item"
        done
        return 1
    fi
    
    log_success "All prerequisites met"
    return 0
}

# Clean build directory
clean_build() {
    log "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    log_success "Build directory cleaned"
}

# Configure CMake
configure_cmake() {
    local ATTEMPT=$1
    log "Configuring CMake (attempt $ATTEMPT)..."
    
    cd "$BUILD_DIR"
    
    ANDROID_SDK="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
    NDK_VERSION="27.2.12479018"
    
    cmake ../.. \
        -DCMAKE_TOOLCHAIN_FILE="$ANDROID_SDK/ndk/$NDK_VERSION/build/cmake/android.toolchain.cmake" \
        -DANDROID_ABI="$ABI" \
        -DANDROID_PLATFORM=android-23 \
        -DANDROID_NDK="$ANDROID_SDK/ndk/$NDK_VERSION" \
        -DANDROID_STL=c++_shared \
        -DQt6_DIR="$HOME/Qt/6.10.0/android_arm64_v8a/lib/cmake/Qt6" \
        -DOpenCV_DIR="$HOME/Android/OpenCV-android-sdk/sdk/native/jni/abi-$ABI" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
        2>&1 | tee "$LOGS_DIR/cmake-log-$ATTEMPT.txt"
    
    CMAKE_RESULT=${PIPESTATUS[0]}
    cd "$PROJECT_ROOT"
    
    return $CMAKE_RESULT
}

# Build project
build_project() {
    local ATTEMPT=$1
    log "Building project (attempt $ATTEMPT)..."
    
    cd "$BUILD_DIR"
    
    cmake --build . -j$(nproc) 2>&1 | tee "$LOGS_DIR/build-log-$ATTEMPT.txt"
    
    BUILD_RESULT=${PIPESTATUS[0]}
    cd "$PROJECT_ROOT"
    
    return $BUILD_RESULT
}

# Main build loop with auto-fix
main() {
    if ! check_prerequisites; then
        log_error "Prerequisites check failed"
        exit 1
    fi
    
    echo ""
    log_info "Starting self-healing build process..."
    echo ""
    
    BUILD_SUCCESS=false
    ATTEMPT=0
    
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        ATTEMPT=$((ATTEMPT + 1))
        
        echo ""
        echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║                  ATTEMPT $ATTEMPT of $MAX_ATTEMPTS                            ║${NC}"
        echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        # Clean on retry
        if [ $ATTEMPT -gt 1 ]; then
            clean_build
        else
            mkdir -p "$BUILD_DIR"
        fi
        
        # Configure
        if ! configure_cmake $ATTEMPT; then
            log_error "CMake configuration failed"
            
            log_info "Running auto-fix analyzer..."
            if bash "$PROJECT_ROOT/.github/scripts/analyze-and-fix.sh" "$LOGS_DIR/cmake-log-$ATTEMPT.txt"; then
                log_success "Auto-fixes applied, will retry..."
                continue
            else
                log_warning "No fixes could be applied"
                if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
                    break
                fi
                continue
            fi
        fi
        
        log_success "CMake configuration successful"
        
        # Build
        if ! build_project $ATTEMPT; then
            log_error "Build failed"
            
            log_info "Running auto-fix analyzer..."
            if bash "$PROJECT_ROOT/.github/scripts/analyze-and-fix.sh" "$LOGS_DIR/build-log-$ATTEMPT.txt"; then
                log_success "Auto-fixes applied, will retry..."
                continue
            else
                log_warning "No fixes could be applied"
                if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
                    break
                fi
                continue
            fi
        fi
        
        log_success "Build successful!"
        BUILD_SUCCESS=true
        break
    done
    
    echo ""
    echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║                     FINAL RESULT                          ║${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$BUILD_SUCCESS" = true ]; then
        log_success "Build completed successfully on attempt $ATTEMPT!"
        echo ""
        log_info "APK location: $BUILD_DIR/android-build/"
        log_info "Logs saved to: $LOGS_DIR/"
        echo ""
        
        # Find and display APK info
        if [ -d "$BUILD_DIR/android-build" ]; then
            APKS=$(find "$BUILD_DIR/android-build" -name "*.apk" 2>/dev/null)
            if [ -n "$APKS" ]; then
                echo -e "${GREEN}Generated APKs:${NC}"
                echo "$APKS" | while read -r apk; do
                    SIZE=$(du -h "$apk" | cut -f1)
                    echo "  📦 $(basename "$apk") ($SIZE)"
                done
            fi
        fi
        
        echo ""
        log_info "Next steps:"
        echo "  1. Install: adb install -r $BUILD_DIR/android-build/*.apk"
        echo "  2. Run tests: ./ci-helper.sh test"
        echo ""
        
        exit 0
    else
        log_error "Build failed after $ATTEMPT attempts"
        echo ""
        log_info "Review the logs:"
        echo "  - CMake log: $LOGS_DIR/cmake-log-$ATTEMPT.txt"
        echo "  - Build log: $LOGS_DIR/build-log-$ATTEMPT.txt"
        echo "  - Fix log: $LOGS_DIR/fix-log-*.txt"
        echo ""
        log_info "Common issues:"
        echo "  - Check Qt and OpenCV installation paths"
        echo "  - Verify Android NDK version"
        echo "  - Review QML import statements"
        echo "  - Check for missing C++ includes"
        echo ""
        
        exit 1
    fi
}

# Handle Ctrl+C
trap 'echo ""; log_warning "Build interrupted by user"; exit 130' INT

# Run main
main
