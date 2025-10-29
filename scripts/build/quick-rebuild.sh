#!/bin/bash

# Simple Android Rebuild Script
# Rebuilds using existing Qt Creator build directory

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
    echo -e "${BLUE}[REBUILD]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[REBUILD]${NC} $1"
}

log_error() {
    echo -e "${RED}[REBUILD]${NC} $1"
}

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}║          🔄 QUICK REBUILD SYSTEM 🔄                       ║${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Find existing build directory
find_build_dir() {
    log "Looking for existing Qt Creator build directory..."
    
    BUILD_DIRS=(
        "$PROJECT_ROOT/build/Android_Qt_6_10_0_Clang_arm64_v8a-Debug"
        "$PROJECT_ROOT/build/Android_Qt_*_Clang_*-Debug"
    )
    
    for pattern in "${BUILD_DIRS[@]}"; do
        for dir in $pattern; do
            if [ -d "$dir" ] && [ -f "$dir/CMakeCache.txt" ]; then
                BUILD_DIR="$dir"
                log_success "Found build directory: $BUILD_DIR"
                return 0
            fi
        done
    done
    
    log_error "No Qt Creator build directory found"
    log "Please build the project once in Qt Creator first"
    return 1
}

# Rebuild using cmake
rebuild_project() {
    log "Rebuilding project in: $BUILD_DIR"
    
    cd "$BUILD_DIR"
    
    # Clean previous build
    log "Cleaning previous build..."
    find . -name "*.o" -delete 2>/dev/null || true
    find . -name "*.so" -delete 2>/dev/null || true
    
    # Rebuild
    log "Running cmake build..."
    if cmake --build . --parallel $(nproc) 2>&1 | tee build.log; then
        log_success "Build successful"
    else
        log_error "Build failed - check build.log"
        return 1
    fi
    
    # Find the APK
    APK=$(find . -name "*-debug.apk" -type f 2>/dev/null | head -1)
    
    if [ -n "$APK" ] && [ -f "$APK" ]; then
        log_success "APK found: $APK"
        
        # Copy to project root for convenience
        cp "$APK" "$PROJECT_ROOT/app-debug.apk"
        log_success "APK copied to: $PROJECT_ROOT/app-debug.apk"
        
        # Show APK info
        APK_SIZE=$(du -h "$APK" | cut -f1)
        log "APK size: $APK_SIZE"
        
        return 0
    else
        log_error "APK not found after build"
        return 1
    fi
}

# Install to device (optional)
install_to_device() {
    if command -v adb &> /dev/null; then
        DEVICE=$(adb devices | grep -w "device" | head -1 | awk '{print $1}')
        
        if [ -n "$DEVICE" ]; then
            echo ""
            log "Device connected: $DEVICE"
            read -p "Install APK to device? (y/n) " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "Installing APK..."
                adb install -r "$PROJECT_ROOT/app-debug.apk"
                log_success "APK installed on device"
            fi
        fi
    fi
}

# Main
main() {
    if ! find_build_dir; then
        exit 1
    fi
    
    echo ""
    
    if ! rebuild_project; then
        exit 1
    fi
    
    install_to_device
    
    echo ""
    log_success "✅ Rebuild completed!"
    echo ""
}

main
