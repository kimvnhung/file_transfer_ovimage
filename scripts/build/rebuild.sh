#!/bin/bash

# Rebuild Helper - Guides to rebuild on Windows
# Since Qt is installed on Windows, not WSL

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}║          🔄 REBUILD HELPER 🔄                             ║${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Qt is installed on Windows, not in WSL.${NC}"
echo "To rebuild the APK with your QML fixes:"
echo ""
echo -e "${GREEN}Option 1: Use Qt Creator (Easiest)${NC}"
echo "  1. Open Qt Creator on Windows"
echo "  2. Click Build → Rebuild Project"
echo "  3. APK will be created automatically"
echo ""
echo -e "${GREEN}Option 2: Use PowerShell Script${NC}"
echo "  1. Open PowerShell on Windows"
echo "  2. Navigate to project: cd $(wslpath -w "$PROJECT_ROOT")"
echo "  3. Run: .\\scripts\\build\\build-windows.ps1"
echo ""
echo -e "${GREEN}Option 3: Manual in WSL (if build exists)${NC}"

# Check if build directory exists
BUILD_DIR="$PROJECT_ROOT/build/Android_Qt_6_10_0_Clang_arm64_v8a-Debug"
if [ -d "$BUILD_DIR" ] && [ -f "$BUILD_DIR/build.ninja" ]; then
    echo "  Build directory exists, you can try:"
    echo "  cd $BUILD_DIR"
    echo "  ninja"
    echo ""
    
    # Check if ninja is available
    if command -v ninja &> /dev/null; then
        echo -e "${YELLOW}Attempting to rebuild with ninja...${NC}"
        echo ""
        cd "$BUILD_DIR"
        ninja
        
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✅ Build successful!${NC}"
            
            # Find APK
            APK=$(find . -name "*-debug.apk" -type f 2>/dev/null | head -1)
            if [ -f "$APK" ]; then
                cp "$APK" "$PROJECT_ROOT/app-debug.apk"
                echo -e "${GREEN}APK copied to: $PROJECT_ROOT/app-debug.apk${NC}"
                echo ""
                
                # Offer to install
                if command -v adb &> /dev/null; then
                    DEVICE=$(adb devices | grep -w "device" | head -1 | awk '{print $1}')
                    if [ -n "$DEVICE" ]; then
                        echo "Device connected: $DEVICE"
                        read -p "Install APK now? (y/n) " -n 1 -r
                        echo
                        if [[ $REPLY =~ ^[Yy]$ ]]; then
                            adb install -r "$PROJECT_ROOT/app-debug.apk"
                            echo -e "${GREEN}✅ APK installed!${NC}"
                        fi
                    fi
                fi
            fi
        else
            echo -e "${YELLOW}Ninja build failed. Please use Qt Creator or PowerShell script.${NC}"
        fi
    else
        echo "  (ninja not found in WSL)"
    fi
else
    echo "  Build directory not found. Use Qt Creator or PowerShell first."
fi

echo ""
