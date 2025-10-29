#!/bin/bash

# Demo: Self-Healing CI System
# This script demonstrates the self-healing capabilities

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║                                                           ║${NC}"
echo -e "${MAGENTA}║     🤖 SELF-HEALING CI SYSTEM DEMONSTRATION 🤖            ║${NC}"
echo -e "${MAGENTA}║                                                           ║${NC}"
echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}This demo shows how the self-healing system works:${NC}"
echo ""
echo "1. ✅ Detects missing QML imports"
echo "2. ✅ Fixes QML type registration issues"
echo "3. ✅ Downloads OpenCV SDK if missing"
echo "4. ✅ Adds missing C++ includes"
echo "5. ✅ Retries builds automatically"
echo ""

# Demo 1: Show QML import detection
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}DEMO 1: QML Import Error Detection${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

cat > /tmp/demo-qml-error.log << 'EOF'
qml/views/MainView.qml:25:5: error: PhotoCaptureControls is not a type
qml/components/CameraButton.qml:10:1: error: CameraPropertyPopup is not a type
Build failed with 2 errors
EOF

echo -e "${RED}Simulated build log (with QML errors):${NC}"
cat /tmp/demo-qml-error.log
echo ""

echo -e "${GREEN}Running analyzer...${NC}"
echo ""

# Show what the analyzer would detect
echo -e "${CYAN}Detected issues:${NC}"
echo "  • Missing import '../controls' in MainView.qml"
echo "  • Missing import '../dialogs' in CameraButton.qml"
echo ""

echo -e "${GREEN}Auto-fixes that would be applied:${NC}"
echo "  ✓ Add 'import \"../controls\"' to qml/views/MainView.qml"
echo "  ✓ Add 'import \"../dialogs\"' to qml/components/CameraButton.qml"
echo ""

read -p "Press Enter to continue to next demo..."
echo ""

# Demo 2: Show QML_ELEMENT detection
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}DEMO 2: Missing QML_ELEMENT Detection${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

cat > /tmp/demo-qml-element-error.log << 'EOF'
qml/views/VideoPreview.qml:15: error: module "opencv_player" is not installed
error: Type OpenCV_VideoPlayer unavailable
Build failed with type registration errors
EOF

echo -e "${RED}Simulated build log (with type registration errors):${NC}"
cat /tmp/demo-qml-element-error.log
echo ""

echo -e "${GREEN}Running analyzer...${NC}"
echo ""

echo -e "${CYAN}Detected issues:${NC}"
echo "  • Missing QML_ELEMENT macro in C++ headers"
echo "  • Missing QQmlEngine include"
echo ""

echo -e "${GREEN}Auto-fixes that would be applied:${NC}"
echo "  ✓ Add '#include <QQmlEngine>' to opencv_videoplayer.h"
echo "  ✓ Add 'QML_ELEMENT' macro after Q_OBJECT"
echo "  ✓ Add '#include <QQmlEngine>' to opencv_player_viewport.h"
echo "  ✓ Add 'QML_ELEMENT' macro after Q_OBJECT"
echo ""

read -p "Press Enter to continue to next demo..."
echo ""

# Demo 3: Show OpenCV detection
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}DEMO 3: OpenCV SDK Missing Detection${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

cat > /tmp/demo-opencv-error.log << 'EOF'
CMake Error at CMakeLists.txt:45 (find_package):
  Could not find a package configuration file provided by "OpenCV" with any
  of the following names:
    OpenCVConfig.cmake
    opencv-config.cmake
EOF

echo -e "${RED}Simulated CMake log (OpenCV not found):${NC}"
cat /tmp/demo-opencv-error.log
echo ""

echo -e "${GREEN}Running analyzer...${NC}"
echo ""

echo -e "${CYAN}Detected issues:${NC}"
echo "  • OpenCV Android SDK not found at ~/Android/OpenCV-android-sdk"
echo ""

echo -e "${GREEN}Auto-fixes that would be applied:${NC}"
echo "  ✓ Download OpenCV 4.10.0 Android SDK from GitHub"
echo "  ✓ Extract to ~/Android/OpenCV-android-sdk"
echo "  ✓ Configure all ABIs (arm64-v8a, armeabi-v7a, x86, x86_64)"
echo ""

read -p "Press Enter to continue to summary..."
echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}SELF-HEALING BUILD WORKFLOW${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${CYAN}Step-by-step process:${NC}"
echo ""
echo "1️⃣  Build Attempt 1"
echo "    └─ Build fails with errors"
echo ""
echo "2️⃣  Error Analysis"
echo "    ├─ Extract errors from log"
echo "    ├─ Pattern matching"
echo "    └─ Identify root causes"
echo ""
echo "3️⃣  Auto-Fix Application"
echo "    ├─ Add missing imports"
echo "    ├─ Fix type registration"
echo "    ├─ Download dependencies"
echo "    └─ Add missing includes"
echo ""
echo "4️⃣  Build Attempt 2"
echo "    ├─ Clean build directory"
echo "    ├─ Reconfigure CMake"
echo "    └─ Rebuild with fixes"
echo ""
echo "5️⃣  Success or Retry"
echo "    ├─ If success: Generate APK"
echo "    ├─ If fails: Analyze again"
echo "    └─ Max 3 attempts"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Demo completed!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Try it yourself:${NC}"
echo ""
echo "  # Local self-healing build:"
echo -e "  ${CYAN}./self-heal-build.sh${NC}"
echo ""
echo "  # Or use GitHub Actions:"
echo -e "  ${CYAN}git push origin dev_with_ai_agent${NC}"
echo ""
echo "  # Check logs:"
echo -e "  ${CYAN}cat ci-reports/self-heal/fix-log-*.txt${NC}"
echo ""

echo -e "${BLUE}For full documentation, see:${NC}"
echo "  📖 SELF_HEALING_CI.md"
echo "  📖 CI_CD_GUIDE.md"
echo ""

# Cleanup
rm -f /tmp/demo-*.log

echo -e "${MAGENTA}Thank you for watching the demo! 🚀${NC}"
echo ""
