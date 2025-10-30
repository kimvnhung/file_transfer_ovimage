# Setup Scripts

Automated environment setup scripts for File Transfer Over Image development.

## Overview

These scripts automate the installation and configuration of all required dependencies for desktop and Android development.

## Scripts

### setup.sh (Main Entry Point)

Unified setup script with interactive menu.

**Usage:**
```bash
# Interactive mode
./scripts/setup/setup.sh

# Direct mode
./scripts/setup/setup.sh desktop    # Desktop environment
./scripts/setup/setup.sh android    # Android environment
./scripts/setup/setup.sh both       # Both environments
./scripts/setup/setup.sh info       # Show system info
```

**Features:**
- Interactive menu for easy selection
- Command-line arguments for automation
- System information display
- Color-coded output

### setup-desktop.sh

Sets up desktop development environment.

**What it installs:**
- Build tools (CMake, Ninja, GCC/Clang, ccache)
- Qt6 (Base, Declarative, Multimedia, Tools)
- OpenCV 4.x with development headers
- Tesseract OCR 5.x with English data
- System libraries (X11, OpenGL, SSL, fonts)

**Supported OS:**
- Ubuntu/Debian (apt)
- Fedora/RHEL/CentOS (dnf/yum)
- Arch/Manjaro (pacman)
- macOS (Homebrew)

**Direct usage:**
```bash
./scripts/setup/setup-desktop.sh
```

**What it does:**
1. Detects operating system
2. Checks prerequisites
3. Installs build tools
4. Installs Qt6
5. Installs OpenCV
6. Installs Tesseract
7. Installs additional libraries
8. Sets up build directory
9. Configures CMake
10. Verifies installation
11. Prints usage instructions

### setup-android.sh

Sets up Android development environment.

**What it installs:**
- Java JDK 17
- Android SDK with command line tools
- Android NDK 25.1.8937393
- Android platform tools (adb, fastboot)
- SDK Platform API 33
- Build tools 33.0.2
- CMake for Android
- OpenCV for Android (ARM64)

**Note:** Qt for Android must be installed manually via Qt Online Installer.

**Supported OS:**
- Linux (any distribution)
- macOS

**Direct usage:**
```bash
./scripts/setup/setup-android.sh
```

**What it does:**
1. Detects operating system
2. Installs Java JDK
3. Downloads and installs Android SDK
4. Installs SDK components (platform, NDK, build tools)
5. Checks for Qt Android installation
6. Downloads OpenCV for Android
7. Creates environment configuration file
8. Sets up build directory
9. Verifies installation
10. Prints usage instructions

## Output Files

### android-env.sh

Environment configuration file created by `setup-android.sh`.

**Location:** Project root directory

**Contents:**
```bash
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/25.1.8937393"
export ANDROID_NDK_HOME="$ANDROID_NDK_ROOT"
export OPENCV_ANDROID="$PROJECT_ROOT/external/opencv-android"
```

**Usage:**
```bash
# Before building for Android
source android-env.sh

# Or add to shell profile
echo "source ~/projects/file_transfer_ovimage/android-env.sh" >> ~/.bashrc
```

## Examples

### First-Time Setup (Desktop)

```bash
# Clone repository
git clone https://github.com/kimvnhung/file_transfer_ovimage.git
cd file_transfer_ovimage

# Run setup
./scripts/setup/setup.sh desktop

# Build
cd build/Desktop_Qt_6_10_0-Debug
cmake --build . --parallel

# Run
./file_transfer_ovimage
```

### First-Time Setup (Android)

```bash
# Clone repository
git clone https://github.com/kimvnhung/file_transfer_ovimage.git
cd file_transfer_ovimage

# Run setup (installs SDK/NDK)
./scripts/setup/setup.sh android

# Manually install Qt for Android from qt.io
# Download and run Qt Online Installer
# Select: Qt 6.10.0 → Android ARM 64-bit

# Set Qt path (adjust version/path as needed)
export Qt6_DIR="$HOME/Qt/6.10.0"

# Source environment
source android-env.sh

# Build
./build.sh android arm64-v8a

# Install to device
adb install -r build/android-build/*.apk
```

### CI/CD Setup

```bash
# Non-interactive installation
DEBIAN_FRONTEND=noninteractive ./scripts/setup/setup-desktop.sh

# With specific Qt path
Qt6_DIR=/opt/qt6 ./scripts/setup/setup-desktop.sh

# Android CI setup
ANDROID_SDK_ROOT=/opt/android-sdk ./scripts/setup/setup-android.sh
```

## Exit Codes

All scripts use standard exit codes:

- `0` - Success
- `1` - General error
- `127` - Command not found

## Logging

Scripts use color-coded logging:

- 🔵 **INFO** (Blue) - Informational messages
- 🟢 **SUCCESS** (Green) - Successful operations
- 🟡 **WARNING** (Yellow) - Non-critical issues
- 🔴 **ERROR** (Red) - Critical errors

## Customization

### Skip Components

To skip optional components, comment out function calls in the script:

```bash
# In setup-desktop.sh
# install_tesseract  # Skip Tesseract installation
```

### Custom Versions

Edit version variables at the top of scripts:

```bash
# In setup-android.sh
ANDROID_SDK_VERSION="34"           # Change API level
ANDROID_NDK_VERSION="26.1.10909125"  # Change NDK version
```

### Custom Paths

Override paths via environment variables:

```bash
ANDROID_SDK_ROOT=/custom/path/sdk ./scripts/setup/setup-android.sh
Qt6_DIR=/custom/path/qt6 ./scripts/setup/setup-desktop.sh
```

## Troubleshooting

### "Permission denied"

Make scripts executable:
```bash
chmod +x scripts/setup/*.sh
```

### Package manager not found

Script auto-detects package manager. If detection fails:
- Ubuntu/Debian: Requires `apt`
- Fedora/RHEL: Requires `dnf` or `yum`
- Arch/Manjaro: Requires `pacman`
- macOS: Requires Homebrew (`brew`)

### Qt not found after installation

Check Qt installation:
```bash
# Linux
dpkg -l | grep qt6
rpm -qa | grep qt6
pacman -Q | grep qt6

# Find Qt CMake config
find /usr -name "Qt6Config.cmake" 2>/dev/null

# Set manually
export Qt6_DIR=/path/to/qt6/lib/cmake
```

### Android SDK installation fails

Manual installation:
```bash
# Download from https://developer.android.com/studio#cmdline-tools
# Extract and run sdkmanager manually
```

### OpenCV for Android download fails

Manual download:
```bash
curl -L -o opencv.zip \
  https://github.com/opencv/opencv/releases/download/4.10.0/opencv-4.10.0-android-sdk.zip
unzip opencv.zip -d external/
mv external/OpenCV-android-sdk external/opencv-android
```

## Platform Notes

### Ubuntu 22.04+
- Qt6 in default repos
- All dependencies available
- Recommended for desktop development

### Ubuntu 20.04
- Qt6 requires PPA
- Older Tesseract version (4.x)
- May need manual Qt installation

### Fedora/RHEL
- Package names differ slightly
- Enable EPEL repo on RHEL
- Use `dnf` instead of `apt`

### Arch Linux
- Rolling release, always latest
- Usually no dependency issues
- Packages may have different names

### macOS
- Requires Homebrew
- May need Xcode Command Line Tools
- Qt installs to `/usr/local/opt/qt@6`

### Windows (WSL)
- Use WSL2 with Ubuntu
- Follow Linux instructions
- GUI apps need X11 server

## See Also

- [Environment Setup Guide](../../docs/ENVIRONMENT_SETUP.md) - Detailed setup documentation
- [Build Modes](../../docs/BUILD_MODES.md) - Desktop vs Mobile builds
- [CI/CD Guide](../../docs/guides/CI_CD_GUIDE.md) - Continuous integration
- [Main README](../../README.md) - Project overview

## Contributing

When modifying setup scripts:

1. Test on multiple distributions
2. Handle errors gracefully
3. Provide clear error messages
4. Update documentation
5. Maintain color-coded output
6. Keep exit codes consistent

## Support

For setup issues:

1. Run `./scripts/setup/setup.sh info` to check system
2. Check [Environment Setup Guide](../../docs/ENVIRONMENT_SETUP.md)
3. Review error messages
4. Check troubleshooting section
5. File issue with:
   - OS and version
   - Error output
   - Output of info command

---

**Maintained by:** File Transfer Over Image Team  
**Last Updated:** 2024-10-30
