#!/bin/bash
# Unified Setup Script - Choose Desktop or Android development environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║           ${GREEN}File Transfer Over Image${CYAN}                      ║${NC}"
    echo -e "${CYAN}║           ${YELLOW}Development Environment Setup${CYAN}                 ║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_menu() {
    echo -e "${BLUE}Select environment to set up:${NC}"
    echo ""
    echo "  1) Desktop Development (Linux/macOS)"
    echo "     - Qt6, OpenCV, Tesseract OCR"
    echo "     - Build tools (CMake, Ninja)"
    echo "     - Desktop application development"
    echo ""
    echo "  2) Android Development"
    echo "     - Android SDK/NDK"
    echo "     - Qt for Android"
    echo "     - OpenCV for Android"
    echo "     - APK building"
    echo ""
    echo "  3) Both (Desktop + Android)"
    echo "     - Complete development environment"
    echo ""
    echo "  4) Show system information"
    echo ""
    echo "  5) Exit"
    echo ""
}

show_system_info() {
    echo -e "${BLUE}System Information:${NC}"
    echo ""
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo ""
    
    echo -e "${BLUE}Installed Components:${NC}"
    echo ""
    
    # CMake
    if command -v cmake >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} CMake: $(cmake --version | head -n1)"
    else
        echo -e "${RED}✗${NC} CMake: Not installed"
    fi
    
    # Ninja
    if command -v ninja >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Ninja: $(ninja --version)"
    else
        echo -e "${RED}✗${NC} Ninja: Not installed"
    fi
    
    # Qt - check Qt 6.10 first
    if [ -x "$HOME/Qt/6.10.0/gcc_64/bin/qmake" ]; then
        echo -e "${GREEN}✓${NC} Qt: $($HOME/Qt/6.10.0/gcc_64/bin/qmake --version | grep 'Qt version') (Custom Installation)"
    elif command -v qmake6 >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Qt: $(qmake6 --version | grep 'Qt version')"
    elif command -v qmake >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Qt: $(qmake --version | grep 'Qt version')"
    else
        echo -e "${RED}✗${NC} Qt: Not installed"
    fi
    
    # OpenCV
    if pkg-config --exists opencv4 2>/dev/null; then
        echo -e "${GREEN}✓${NC} OpenCV: $(pkg-config --modversion opencv4)"
    elif pkg-config --exists opencv 2>/dev/null; then
        echo -e "${GREEN}✓${NC} OpenCV: $(pkg-config --modversion opencv)"
    else
        echo -e "${RED}✗${NC} OpenCV: Not installed"
    fi
    
    # Tesseract
    if command -v tesseract >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Tesseract: $(tesseract --version 2>&1 | head -n1)"
    else
        echo -e "${RED}✗${NC} Tesseract: Not installed"
    fi
    
    # Java
    if command -v java >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Java: $(java -version 2>&1 | head -n1)"
    else
        echo -e "${RED}✗${NC} Java: Not installed"
    fi
    
    # Android SDK
    if [ -n "$ANDROID_SDK_ROOT" ] && [ -d "$ANDROID_SDK_ROOT" ]; then
        echo -e "${GREEN}✓${NC} Android SDK: $ANDROID_SDK_ROOT"
    else
        echo -e "${RED}✗${NC} Android SDK: Not found"
    fi
    
    # ADB
    if command -v adb >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} ADB: $(adb --version | head -n1)"
    else
        echo -e "${RED}✗${NC} ADB: Not installed"
    fi
    
    echo ""
}

run_desktop_setup() {
    echo -e "${YELLOW}Starting Desktop environment setup...${NC}"
    echo ""
    bash "$SCRIPT_DIR/setup-desktop.sh"
}

run_android_setup() {
    echo -e "${YELLOW}Starting Android environment setup...${NC}"
    echo ""
    bash "$SCRIPT_DIR/setup-android.sh"
}

main() {
    print_banner
    
    if [ $# -eq 1 ]; then
        case "$1" in
            desktop|Desktop|DESKTOP|1)
                run_desktop_setup
                exit 0
                ;;
            android|Android|ANDROID|2)
                run_android_setup
                exit 0
                ;;
            both|Both|BOTH|all|All|ALL|3)
                run_desktop_setup
                echo ""
                echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""
                run_android_setup
                exit 0
                ;;
            info|Info|INFO|4)
                show_system_info
                exit 0
                ;;
            help|--help|-h)
                echo "Usage: $0 [option]"
                echo ""
                echo "Options:"
                echo "  desktop    Setup desktop development environment"
                echo "  android    Setup Android development environment"
                echo "  both       Setup both environments"
                echo "  info       Show system information"
                echo "  help       Show this help message"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option: $1${NC}"
                echo "Use '$0 help' for usage information"
                exit 1
                ;;
        esac
    fi
    
    # Interactive mode
    while true; do
        show_menu
        read -p "Enter your choice [1-5]: " choice
        echo ""
        
        case $choice in
            1)
                run_desktop_setup
                break
                ;;
            2)
                run_android_setup
                break
                ;;
            3)
                run_desktop_setup
                echo ""
                echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""
                run_android_setup
                break
                ;;
            4)
                show_system_info
                read -p "Press Enter to continue..."
                echo ""
                ;;
            5)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please select 1-5.${NC}"
                echo ""
                sleep 1
                ;;
        esac
    done
}

main "$@"
