#!/bin/bash
# Makefile-style convenience script for CI/CD operations

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${PROJECT_ROOT}"

# Configuration
export ANDROID_NDK="${ANDROID_NDK:-${HOME}/Android/Sdk/ndk/27.2.12479018}"
export Qt6_DIR="${Qt6_DIR:-${HOME}/Qt/6.10.0/android_arm64_v8a/lib/cmake/Qt6}"
export ANDROID_ABI="${ANDROID_ABI:-arm64-v8a}"
export BUILD_TYPE="${BUILD_TYPE:-Release}"

show_help() {
    cat << EOF
Android CI/CD Helper Script
============================

Usage: $0 [command]

Commands:
    build           Build Android APK
    test            Install and test APK on device
    clean           Clean build artifacts
    setup           Setup environment (OpenCV, etc.)
    docker-build    Build using Docker
    docker-test     Test using Docker with device
    logs            View recent test logs
    help            Show this help message

Environment Variables:
    ANDROID_NDK     Path to Android NDK (default: ~/Android/Sdk/ndk/27.2.12479018)
    Qt6_DIR         Path to Qt6 CMake files
    ANDROID_ABI     Target ABI (default: arm64-v8a)
    BUILD_TYPE      Build type (default: Release)
    DEVICE_SERIAL   Device serial for testing

Examples:
    $0 build                    # Build APK
    $0 test                     # Test on connected device
    ANDROID_ABI=x86_64 $0 build # Build for x86_64
    BUILD_TYPE=Debug $0 build   # Build debug version
    $0 docker-build             # Build in Docker container

EOF
}

cmd_build() {
    echo "Building Android APK..."
    bash "${PROJECT_ROOT}/scripts/ci/build-android.sh"
}

cmd_test() {
    echo "Testing Android APK..."
    bash "${PROJECT_ROOT}/scripts/ci/test-android.sh"
}

cmd_clean() {
    echo "Cleaning build artifacts..."
    rm -rf "${PROJECT_ROOT}/build/ci-android"
    rm -rf "${PROJECT_ROOT}/ci-reports"
    echo "Clean completed"
}

cmd_setup() {
    echo "Setting up environment..."
    
    # Setup OpenCV
    if [ ! -d "${HOME}/Android/OpenCV-android-sdk" ]; then
        bash "${PROJECT_ROOT}/scripts/setup/setup_opencv_android.sh"
    else
        echo "OpenCV already installed"
    fi
    
    # Verify environment
    bash "${PROJECT_ROOT}/scripts/setup/verify_opencv_android.sh"
}

cmd_docker_build() {
    echo "Building with Docker..."
    docker-compose build
    docker-compose up
}

cmd_docker_test() {
    echo "Testing with Docker..."
    echo "Note: You need to forward ADB to the container"
    echo "Run: adb kill-server && adb -a nodaemon server"
    docker-compose run --rm android-ci bash -c "adb devices && bash /workspace/scripts/ci/test-android.sh"
}

cmd_logs() {
    echo "Recent CI logs:"
    echo "==============="
    
    if [ -d "${PROJECT_ROOT}/ci-reports" ]; then
        echo ""
        echo "Build Report:"
        echo "-------------"
        cat "${PROJECT_ROOT}/ci-reports/build-report.txt" 2>/dev/null || echo "No build report found"
        
        echo ""
        echo "Test Report:"
        echo "------------"
        cat "${PROJECT_ROOT}/ci-reports/test-report.txt" 2>/dev/null || echo "No test report found"
        
        echo ""
        echo "Recent Errors:"
        echo "--------------"
        head -n 20 "${PROJECT_ROOT}/ci-reports/errors.txt" 2>/dev/null || echo "No errors found"
    else
        echo "No CI reports found. Run build or test first."
    fi
}

# Main command dispatcher
case "${1:-help}" in
    build)
        cmd_build
        ;;
    test)
        cmd_test
        ;;
    clean)
        cmd_clean
        ;;
    setup)
        cmd_setup
        ;;
    docker-build)
        cmd_docker_build
        ;;
    docker-test)
        cmd_docker_test
        ;;
    logs)
        cmd_logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
