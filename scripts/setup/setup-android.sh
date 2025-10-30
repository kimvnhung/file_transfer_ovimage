#!/bin/bash
# Android Development Environment Setup Script
# Sets up Qt for Android, Android SDK/NDK, and other dependencies for mobile builds

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default versions
ANDROID_SDK_VERSION="33"
ANDROID_NDK_VERSION="25.1.8937393"
ANDROID_BUILD_TOOLS_VERSION="33.0.2"
QT_VERSION="6.10.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

print_header() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║         Android Development Environment Setup             ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    
    log_info "Detected OS: $OS"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Java JDK
install_java() {
    log_info "Checking Java JDK installation..."
    
    if command_exists java && command_exists javac; then
        local java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
        log_success "Java already installed: $java_version"
        return 0
    fi
    
    log_info "Installing Java JDK..."
    
    if [[ "$OS" == "linux" ]]; then
        if command_exists apt; then
            sudo apt update
            sudo apt install -y openjdk-17-jdk
        elif command_exists dnf; then
            sudo dnf install -y java-17-openjdk-devel
        elif command_exists pacman; then
            sudo pacman -S --noconfirm jdk17-openjdk
        fi
    elif [[ "$OS" == "macos" ]]; then
        brew install openjdk@17
        echo 'export PATH="/usr/local/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
        echo 'export PATH="/usr/local/opt/openjdk@17/bin:$PATH"' >> ~/.bashrc
    fi
    
    log_success "Java JDK installed"
}

# Install Android SDK
install_android_sdk() {
    log_info "Checking Android SDK installation..."
    
    # Check if ANDROID_SDK_ROOT is set and valid
    if [ -n "$ANDROID_SDK_ROOT" ] && [ -d "$ANDROID_SDK_ROOT" ]; then
        log_success "Android SDK already installed: $ANDROID_SDK_ROOT"
        return 0
    fi
    
    # Check common locations
    local sdk_locations=(
        "$HOME/Android/Sdk"
        "$HOME/Library/Android/sdk"
        "/opt/android-sdk"
    )
    
    for location in "${sdk_locations[@]}"; do
        if [ -d "$location" ]; then
            export ANDROID_SDK_ROOT="$location"
            log_success "Found Android SDK at: $location"
            return 0
        fi
    done
    
    log_info "Android SDK not found. Installing..."
    
    local install_dir="$HOME/Android/Sdk"
    mkdir -p "$install_dir"
    
    # Download command line tools
    local cmdline_tools_url
    if [[ "$OS" == "linux" ]]; then
        cmdline_tools_url="https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"
    elif [[ "$OS" == "macos" ]]; then
        cmdline_tools_url="https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip"
    fi
    
    log_info "Downloading Android command line tools..."
    local temp_zip="/tmp/cmdline-tools.zip"
    curl -L -o "$temp_zip" "$cmdline_tools_url"
    
    # Extract to proper location
    local cmdline_tools_dir="$install_dir/cmdline-tools"
    mkdir -p "$cmdline_tools_dir"
    unzip -q "$temp_zip" -d "$cmdline_tools_dir"
    mv "$cmdline_tools_dir/cmdline-tools" "$cmdline_tools_dir/latest"
    rm "$temp_zip"
    
    export ANDROID_SDK_ROOT="$install_dir"
    export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
    
    log_success "Android SDK installed"
}

# Install SDK components
install_sdk_components() {
    log_info "Installing Android SDK components..."
    
    local sdkmanager="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
    
    if [ ! -f "$sdkmanager" ]; then
        log_error "sdkmanager not found. Please check Android SDK installation."
        return 1
    fi
    
    # Accept licenses
    yes | "$sdkmanager" --licenses >/dev/null 2>&1
    
    log_info "Installing platform tools..."
    "$sdkmanager" "platform-tools"
    
    log_info "Installing SDK platform $ANDROID_SDK_VERSION..."
    "$sdkmanager" "platforms;android-$ANDROID_SDK_VERSION"
    
    log_info "Installing build tools..."
    "$sdkmanager" "build-tools;$ANDROID_BUILD_TOOLS_VERSION"
    
    log_info "Installing NDK..."
    "$sdkmanager" "ndk;$ANDROID_NDK_VERSION"
    
    log_info "Installing CMake..."
    "$sdkmanager" "cmake;3.22.1"
    
    log_success "SDK components installed"
}

# Install Qt for Android
install_qt_android() {
    log_info "Checking Qt for Android installation..."
    
    # Check if Qt is installed
    local qt_paths=(
        "$HOME/Qt/$QT_VERSION"
        "/opt/Qt/$QT_VERSION"
        "$HOME/.local/Qt/$QT_VERSION"
    )
    
    local qt_found=false
    for qt_path in "${qt_paths[@]}"; do
        if [ -d "$qt_path/android_arm64_v8a" ]; then
            log_success "Qt for Android found at: $qt_path"
            export Qt6_DIR="$qt_path"
            qt_found=true
            break
        fi
    done
    
    if [ "$qt_found" = false ]; then
        log_warning "Qt for Android not found!"
        echo ""
        echo "Please install Qt for Android manually:"
        echo "  1. Download Qt Online Installer from: https://www.qt.io/download"
        echo "  2. Run the installer and select:"
        echo "     - Qt $QT_VERSION"
        echo "     - Android (ARM 64-bit)"
        echo "     - Qt Creator (optional but recommended)"
        echo "  3. After installation, set Qt6_DIR environment variable"
        echo ""
        log_info "Continuing with remaining setup..."
    fi
}

# Install OpenCV for Android
install_opencv_android() {
    log_info "Checking OpenCV for Android..."
    
    local opencv_dir="$PROJECT_ROOT/external/opencv-android"
    
    if [ -d "$opencv_dir" ]; then
        log_success "OpenCV for Android already installed"
        return 0
    fi
    
    log_info "Downloading OpenCV for Android..."
    
    local opencv_version="4.10.0"
    local opencv_url="https://github.com/opencv/opencv/releases/download/$opencv_version/opencv-$opencv_version-android-sdk.zip"
    local temp_zip="/tmp/opencv-android.zip"
    
    mkdir -p "$PROJECT_ROOT/external"
    
    curl -L -o "$temp_zip" "$opencv_url"
    unzip -q "$temp_zip" -d "$PROJECT_ROOT/external"
    mv "$PROJECT_ROOT/external/OpenCV-android-sdk" "$opencv_dir"
    rm "$temp_zip"
    
    log_success "OpenCV for Android installed"
}

# Setup environment variables
setup_environment() {
    log_info "Setting up environment variables..."
    
    local shell_rc=""
    if [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    fi
    
    # Create environment setup file
    local env_file="$PROJECT_ROOT/android-env.sh"
    
    cat > "$env_file" << EOF
#!/bin/bash
# Android Build Environment Variables
# Source this file before building for Android

export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"
export ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/$ANDROID_NDK_VERSION"
export ANDROID_NDK_HOME="\$ANDROID_NDK_ROOT"
export ANDROID_NDK="\$ANDROID_NDK_ROOT"

export PATH="\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:\$PATH"
export PATH="\$ANDROID_SDK_ROOT/platform-tools:\$PATH"
export PATH="\$ANDROID_SDK_ROOT/build-tools/$ANDROID_BUILD_TOOLS_VERSION:\$PATH"

# Qt for Android (update path as needed)
# export Qt6_DIR="$HOME/Qt/$QT_VERSION"

# OpenCV for Android
export OPENCV_ANDROID="$PROJECT_ROOT/external/opencv-android"

echo "Android environment configured:"
echo "  ANDROID_SDK_ROOT: \$ANDROID_SDK_ROOT"
echo "  ANDROID_NDK_ROOT: \$ANDROID_NDK_ROOT"
echo "  OPENCV_ANDROID: \$OPENCV_ANDROID"
EOF
    
    chmod +x "$env_file"
    
    log_success "Environment setup file created: $env_file"
    echo ""
    log_info "To use Android environment, run:"
    echo "  source $env_file"
    echo ""
    
    # Optionally add to shell rc
    if [ -n "$shell_rc" ]; then
        log_info "Add to $shell_rc for permanent setup? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "" >> "$shell_rc"
            echo "# Android Development Environment" >> "$shell_rc"
            echo "source $env_file" >> "$shell_rc"
            log_success "Added to $shell_rc"
        fi
    fi
}

# Setup build directory
setup_build_dir() {
    log_info "Setting up Android build directory..."
    
    local build_dir="$PROJECT_ROOT/build/Android_Qt_6_10_0_Clang_arm64_v8a-Debug"
    
    if [ -d "$build_dir" ]; then
        log_warning "Build directory exists. Clean it? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf "$build_dir"
            mkdir -p "$build_dir"
            log_info "Build directory cleaned"
        fi
    else
        mkdir -p "$build_dir"
    fi
    
    log_success "Build directory ready: $build_dir"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    local errors=0
    local warnings=0
    
    # Check Java
    if ! command_exists java || ! command_exists javac; then
        log_error "Java JDK not found"
        ((errors++))
    else
        log_success "Java: $(java -version 2>&1 | head -n1)"
    fi
    
    # Check Android SDK
    if [ -z "$ANDROID_SDK_ROOT" ] || [ ! -d "$ANDROID_SDK_ROOT" ]; then
        log_error "Android SDK not found"
        ((errors++))
    else
        log_success "Android SDK: $ANDROID_SDK_ROOT"
    fi
    
    # Check NDK
    local ndk_path="$ANDROID_SDK_ROOT/ndk/$ANDROID_NDK_VERSION"
    if [ ! -d "$ndk_path" ]; then
        log_error "Android NDK not found"
        ((errors++))
    else
        log_success "Android NDK: $ndk_path"
    fi
    
    # Check platform tools
    if ! command_exists adb; then
        log_warning "adb not found in PATH"
        ((warnings++))
    else
        log_success "ADB: $(adb --version | head -n1)"
    fi
    
    # Check Qt for Android
    if [ -z "$Qt6_DIR" ]; then
        log_warning "Qt for Android not configured (Qt6_DIR not set)"
        ((warnings++))
    else
        log_success "Qt6_DIR: $Qt6_DIR"
    fi
    
    # Check OpenCV
    if [ -d "$PROJECT_ROOT/external/opencv-android" ]; then
        log_success "OpenCV for Android: $PROJECT_ROOT/external/opencv-android"
    else
        log_warning "OpenCV for Android not found"
        ((warnings++))
    fi
    
    echo ""
    if [ $errors -eq 0 ]; then
        log_success "Verification complete with $warnings warning(s)"
        return 0
    else
        log_error "Verification failed with $errors error(s) and $warnings warning(s)"
        return 1
    fi
}

# Print summary
print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║                  Setup Complete!                          ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "Android development environment is ready!"
    echo ""
    echo "Next steps:"
    echo "  1. Source the environment file:"
    echo "     source $PROJECT_ROOT/android-env.sh"
    echo ""
    echo "  2. Build for Android:"
    echo "     cd $PROJECT_ROOT"
    echo "     ./build.sh android arm64-v8a"
    echo ""
    echo "  3. Or build manually:"
    echo "     cd build/Android_Qt_6_10_0_Clang_arm64_v8a-Debug"
    echo "     cmake ../.. -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-$ANDROID_SDK_VERSION"
    echo "     cmake --build ."
    echo ""
    echo "  4. Install to device:"
    echo "     adb install -r app.apk"
    echo ""
}

# Main execution
main() {
    print_header
    
    detect_os
    
    if [[ "$OS" == "unknown" ]]; then
        log_error "Unsupported operating system"
        exit 1
    fi
    
    install_java
    install_android_sdk
    install_sdk_components
    install_qt_android
    install_opencv_android
    
    setup_environment
    setup_build_dir
    
    verify_installation
    
    print_summary
}

# Run main function
main "$@"
