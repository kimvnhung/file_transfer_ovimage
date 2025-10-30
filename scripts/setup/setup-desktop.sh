#!/bin/bash
# Desktop Development Environment Setup Script
# Sets up Qt, OpenCV, Tesseract, and other dependencies for desktop builds

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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
    echo "║         Desktop Development Environment Setup             ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            OS_VERSION=$VERSION_ID
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    
    log_info "Detected OS: $OS"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=()
    
    # Check for package manager
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        if ! command_exists apt; then
            missing+=("apt")
        fi
    elif [[ "$OS" == "fedora" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
        if ! command_exists dnf && ! command_exists yum; then
            missing+=("dnf/yum")
        fi
    elif [[ "$OS" == "arch" ]] || [[ "$OS" == "manjaro" ]]; then
        if ! command_exists pacman; then
            missing+=("pacman")
        fi
    elif [[ "$OS" == "macos" ]]; then
        if ! command_exists brew; then
            log_warning "Homebrew not found. Installing..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing prerequisites: ${missing[*]}"
        return 1
    fi
    
    log_success "Prerequisites check passed"
    return 0
}

# Install build tools
install_build_tools() {
    log_info "Installing build tools..."
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        sudo apt update
        sudo apt install -y \
            build-essential \
            cmake \
            ninja-build \
            git \
            pkg-config \
            ccache
            
    elif [[ "$OS" == "fedora" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
        sudo dnf install -y \
            gcc \
            gcc-c++ \
            cmake \
            ninja-build \
            git \
            pkg-config \
            ccache
            
    elif [[ "$OS" == "arch" ]] || [[ "$OS" == "manjaro" ]]; then
        sudo pacman -S --noconfirm \
            base-devel \
            cmake \
            ninja \
            git \
            pkg-config \
            ccache
            
    elif [[ "$OS" == "macos" ]]; then
        brew install \
            cmake \
            ninja \
            git \
            pkg-config \
            ccache
    fi
    
    log_success "Build tools installed"
}

# Install Qt6
install_qt6() {
    log_info "Checking Qt6 installation..."
    
    if command_exists qmake6 || command_exists qmake; then
        local qt_version=$(qmake6 --version 2>/dev/null || qmake --version 2>/dev/null | grep -oP 'Qt version \K[0-9.]+')
        log_success "Qt already installed: $qt_version"
        return 0
    fi
    
    log_info "Installing Qt6..."
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        sudo apt install -y \
            qt6-base-dev \
            qt6-declarative-dev \
            qt6-multimedia-dev \
            qt6-tools-dev \
            qml6-module-qtquick \
            qml6-module-qtquick-controls \
            qml6-module-qtquick-layouts \
            qml6-module-qtmultimedia \
            libgl1-mesa-dev \
            libglu1-mesa-dev
            
    elif [[ "$OS" == "fedora" ]] || [[ "$OS" == "rhel" ]]; then
        sudo dnf install -y \
            qt6-qtbase-devel \
            qt6-qtdeclarative-devel \
            qt6-qtmultimedia-devel \
            qt6-qttools-devel \
            mesa-libGL-devel \
            mesa-libGLU-devel
            
    elif [[ "$OS" == "arch" ]] || [[ "$OS" == "manjaro" ]]; then
        sudo pacman -S --noconfirm \
            qt6-base \
            qt6-declarative \
            qt6-multimedia \
            qt6-tools
            
    elif [[ "$OS" == "macos" ]]; then
        brew install qt@6
        echo 'export PATH="/usr/local/opt/qt@6/bin:$PATH"' >> ~/.zshrc
        echo 'export PATH="/usr/local/opt/qt@6/bin:$PATH"' >> ~/.bashrc
    fi
    
    log_success "Qt6 installed"
}

# Install OpenCV
install_opencv() {
    log_info "Checking OpenCV installation..."
    
    if pkg-config --exists opencv4; then
        local opencv_version=$(pkg-config --modversion opencv4)
        log_success "OpenCV already installed: $opencv_version"
        return 0
    fi
    
    log_info "Installing OpenCV..."
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        sudo apt install -y \
            libopencv-dev \
            libopencv-core-dev \
            libopencv-highgui-dev \
            libopencv-imgproc-dev \
            libopencv-videoio-dev
            
    elif [[ "$OS" == "fedora" ]] || [[ "$OS" == "rhel" ]]; then
        sudo dnf install -y \
            opencv \
            opencv-devel
            
    elif [[ "$OS" == "arch" ]] || [[ "$OS" == "manjaro" ]]; then
        sudo pacman -S --noconfirm opencv
            
    elif [[ "$OS" == "macos" ]]; then
        brew install opencv
    fi
    
    log_success "OpenCV installed"
}

# Install Tesseract OCR
install_tesseract() {
    log_info "Checking Tesseract OCR installation..."
    
    if command_exists tesseract; then
        local tesseract_version=$(tesseract --version 2>&1 | head -n1 | grep -oP 'tesseract \K[0-9.]+')
        log_success "Tesseract already installed: $tesseract_version"
        return 0
    fi
    
    log_info "Installing Tesseract OCR..."
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        sudo apt install -y \
            tesseract-ocr \
            libtesseract-dev \
            libleptonica-dev \
            tesseract-ocr-eng
            
    elif [[ "$OS" == "fedora" ]] || [[ "$OS" == "rhel" ]]; then
        sudo dnf install -y \
            tesseract \
            tesseract-devel \
            leptonica-devel \
            tesseract-langpack-eng
            
    elif [[ "$OS" == "arch" ]] || [[ "$OS" == "manjaro" ]]; then
        sudo pacman -S --noconfirm \
            tesseract \
            tesseract-data-eng
            
    elif [[ "$OS" == "macos" ]]; then
        brew install tesseract
        brew install tesseract-lang
    fi
    
    log_success "Tesseract OCR installed"
}

# Install additional libraries
install_additional_libs() {
    log_info "Installing additional libraries..."
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        sudo apt install -y \
            libx11-dev \
            libxext-dev \
            libxfixes-dev \
            libxi-dev \
            libxrender-dev \
            libxcb1-dev \
            libx11-xcb-dev \
            libxcb-glx0-dev \
            libfontconfig1-dev \
            libfreetype6-dev \
            libssl-dev
            
    elif [[ "$OS" == "fedora" ]] || [[ "$OS" == "rhel" ]]; then
        sudo dnf install -y \
            libX11-devel \
            libXext-devel \
            libXfixes-devel \
            libXi-devel \
            libXrender-devel \
            xcb-util-devel \
            fontconfig-devel \
            freetype-devel \
            openssl-devel
            
    elif [[ "$OS" == "arch" ]] || [[ "$OS" == "manjaro" ]]; then
        sudo pacman -S --noconfirm \
            libx11 \
            libxext \
            libxfixes \
            libxi \
            libxrender \
            libxcb \
            fontconfig \
            freetype2 \
            openssl
            
    elif [[ "$OS" == "macos" ]]; then
        brew install \
            freetype \
            fontconfig \
            openssl
    fi
    
    log_success "Additional libraries installed"
}

# Setup build directory
setup_build_dir() {
    log_info "Setting up build directory..."
    
    # Try to find Qt 6.10 installation
    local qt_path=""
    if [ -d "$HOME/Qt/6.10.0/gcc_64" ]; then
        qt_path="$HOME/Qt/6.10.0/gcc_64"
        log_success "Found Qt 6.10.0 at: $qt_path"
    elif [ -d "$HOME/Qt/6.10.0" ]; then
        qt_path="$HOME/Qt/6.10.0/gcc_64"
    fi
    
    local build_dir="$PROJECT_ROOT/build/Desktop_Qt_6_10_0-Debug"
    
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
    
    # Export Qt path for CMake if found
    if [ -n "$qt_path" ]; then
        export CMAKE_PREFIX_PATH="$qt_path"
        export Qt6_DIR="$qt_path/lib/cmake/Qt6"
        log_info "Set CMAKE_PREFIX_PATH=$qt_path"
    fi
    
    log_success "Build directory ready: $build_dir"
}

# Configure CMake
configure_cmake() {
    log_info "Configuring CMake..."
    
    # Try to find Qt 6.10 installation
    local qt_path=""
    if [ -d "$HOME/Qt/6.10.0/gcc_64" ]; then
        qt_path="$HOME/Qt/6.10.0/gcc_64"
        export CMAKE_PREFIX_PATH="$qt_path"
        export Qt6_DIR="$qt_path/lib/cmake/Qt6"
        log_info "Using Qt 6.10.0 from: $qt_path"
    fi
    
    local build_dir="$PROJECT_ROOT/build/Desktop_Qt_6_10_0-Debug"
    
    cd "$build_dir"
    
    local cmake_args=(
        "$PROJECT_ROOT"
        -GNinja
        -DCMAKE_BUILD_TYPE=Debug
        -DCMAKE_C_COMPILER_LAUNCHER=ccache
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
        -DDESKTOP_MODE=ON
    )
    
    # Add Qt path if found
    if [ -n "$qt_path" ]; then
        cmake_args+=(-DCMAKE_PREFIX_PATH="$qt_path")
    fi
    
    cmake "${cmake_args[@]}"
    
    if [ $? -eq 0 ]; then
        log_success "CMake configuration successful"
    else
        log_error "CMake configuration failed"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    local errors=0
    
    # Check CMake
    if ! command_exists cmake; then
        log_error "CMake not found"
        ((errors++))
    else
        log_success "CMake: $(cmake --version | head -n1)"
    fi
    
    # Check Ninja
    if ! command_exists ninja; then
        log_error "Ninja not found"
        ((errors++))
    else
        log_success "Ninja: $(ninja --version)"
    fi
    
    # Check Qt
    local qt_found=false
    
    # Check for Qt 6.10 in home directory first
    if [ -x "$HOME/Qt/6.10.0/gcc_64/bin/qmake" ]; then
        log_success "Qt 6.10.0: $($HOME/Qt/6.10.0/gcc_64/bin/qmake --version | grep 'Qt version')"
        qt_found=true
    elif command_exists qmake6; then
        log_success "Qt6: $(qmake6 --version | grep 'Qt version')"
        qt_found=true
    elif command_exists qmake; then
        log_success "Qt: $(qmake --version | grep 'Qt version')"
        qt_found=true
    fi
    
    if [ "$qt_found" = false ]; then
        log_error "Qt not found"
        ((errors++))
    fi
    
    # Check OpenCV
    if pkg-config --exists opencv4; then
        log_success "OpenCV: $(pkg-config --modversion opencv4)"
    elif pkg-config --exists opencv; then
        log_success "OpenCV: $(pkg-config --modversion opencv)"
    else
        log_error "OpenCV not found"
        ((errors++))
    fi
    
    # Check Tesseract
    if command_exists tesseract; then
        log_success "Tesseract: $(tesseract --version 2>&1 | head -n1)"
    else
        log_warning "Tesseract not found (optional for desktop)"
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "All components verified successfully!"
        return 0
    else
        log_error "Verification failed with $errors error(s)"
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
    log_info "Desktop development environment is ready!"
    echo ""
    echo "Next steps:"
    echo "  1. Build the project:"
    echo "     cd $PROJECT_ROOT"
    echo "     cmake --build build/Desktop_Qt_6_10_0-Debug --parallel"
    echo ""
    echo "  2. Run the application:"
    echo "     ./build/Desktop_Qt_6_10_0-Debug/file_transfer_ovimage"
    echo ""
    echo "  3. Or use the convenience scripts:"
    echo "     ./build.sh        # Build"
    echo "     ./test.sh         # Test"
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
    
    check_prerequisites || exit 1
    
    install_build_tools
    install_qt6
    install_opencv
    install_tesseract
    install_additional_libs
    
    setup_build_dir
    configure_cmake
    
    verify_installation
    
    print_summary
}

# Run main function
main "$@"
