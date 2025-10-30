#!/bin/bash

# Desktop Mode Build Script
# Builds the application with simplified UI for testing

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../.."
BUILD_DIR="$PROJECT_ROOT/build/Desktop_TestMode"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║     🖥️  DESKTOP TEST MODE BUILD                          ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Detect Qt installation
if [ -d "$HOME/Qt/6.10.0/gcc_64" ]; then
    QT_PATH="$HOME/Qt/6.10.0/gcc_64"
elif [ -d "$HOME/Qt/6.9.0/gcc_64" ]; then
    QT_PATH="$HOME/Qt/6.9.0/gcc_64"
elif [ -d "$HOME/Qt/6.8.0/gcc_64" ]; then
    QT_PATH="$HOME/Qt/6.8.0/gcc_64"
else
    echo "[ERROR] Qt installation not found"
    exit 1
fi

CMAKE_COMMAND="$HOME/Qt/Tools/CMake/bin/cmake"
NINJA_COMMAND="$HOME/Qt/Tools/Ninja/ninja"

if [ ! -f "$CMAKE_COMMAND" ]; then
    CMAKE_COMMAND="cmake"
fi

if [ ! -f "$NINJA_COMMAND" ]; then
    NINJA_COMMAND="ninja"
fi

echo "[BUILD] Qt Path: $QT_PATH"
echo "[BUILD] Build Directory: $BUILD_DIR"
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "[BUILD] Configuring with DESKTOP_MODE=ON..."
$CMAKE_COMMAND "$PROJECT_ROOT" \
    -DCMAKE_PREFIX_PATH="$QT_PATH" \
    -DCMAKE_BUILD_TYPE=Debug \
    -G Ninja \
    -DCMAKE_MAKE_PROGRAM="$NINJA_COMMAND" \
    -DDESKTOP_MODE=ON

if [ $? -ne 0 ]; then
    echo "[ERROR] CMake configuration failed"
    exit 1
fi

echo ""
echo "[BUILD] Building project..."
$NINJA_COMMAND

if [ $? -ne 0 ]; then
    echo "[ERROR] Build failed"
    exit 1
fi

echo ""
echo "[SUCCESS] ✅ Desktop Test Mode build completed!"
echo ""
echo "[INFO] Executable: $BUILD_DIR/file_transfer_ovimage"
echo ""
echo "To run: $BUILD_DIR/file_transfer_ovimage"
echo ""

# Ask if user wants to run
read -p "Run the application now? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "[RUN] Launching application..."
    "$BUILD_DIR/file_transfer_ovimage"
fi
