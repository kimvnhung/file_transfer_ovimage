# Environment Setup Guide

Complete guide for setting up development environments for File Transfer Over Image project.

## Quick Start

### Automated Setup (Recommended)

```bash
# Interactive mode - choose your environment
./scripts/setup/setup.sh

# Or directly specify:
./scripts/setup/setup.sh desktop    # Desktop only
./scripts/setup/setup.sh android    # Android only
./scripts/setup/setup.sh both       # Both environments
./scripts/setup/setup.sh info       # Show system info
```

## Desktop Development Setup

### Prerequisites

- **Supported OS**: Linux (Ubuntu/Debian/Fedora/Arch) or macOS
- **Disk Space**: ~5 GB for dependencies
- **Internet**: Required for downloading packages

### What Gets Installed

1. **Build Tools**
   - CMake 3.22+
   - Ninja build system
   - GCC/Clang compiler
   - ccache (compilation cache)

2. **Qt Framework**
   - Qt 6.x (Base, Declarative, Multimedia, Tools)
   - QML modules
   - Development headers

3. **OpenCV**
   - OpenCV 4.x
   - Core, HighGUI, ImgProc, VideoIO modules

4. **Tesseract OCR**
   - Tesseract 5.x
   - Leptonica library
   - English language data

5. **System Libraries**
   - X11/Wayland dependencies
   - OpenGL/Mesa
   - Font libraries
   - SSL/TLS

### Manual Desktop Setup

If automated setup fails, install manually:

#### Ubuntu/Debian
```bash
# Build tools
sudo apt update
sudo apt install -y build-essential cmake ninja-build git pkg-config ccache

# Qt6
sudo apt install -y \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-multimedia-dev \
    qt6-tools-dev \
    qml6-module-qtquick \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qtmultimedia

# OpenCV
sudo apt install -y libopencv-dev

# Tesseract
sudo apt install -y tesseract-ocr libtesseract-dev tesseract-ocr-eng

# Additional libraries
sudo apt install -y \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libssl-dev \
    libfontconfig1-dev
```

#### Fedora/RHEL
```bash
sudo dnf install -y \
    gcc gcc-c++ cmake ninja-build git pkg-config ccache \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtmultimedia-devel \
    opencv opencv-devel \
    tesseract tesseract-devel leptonica-devel
```

#### Arch/Manjaro
```bash
sudo pacman -S --noconfirm \
    base-devel cmake ninja git pkg-config ccache \
    qt6-base qt6-declarative qt6-multimedia qt6-tools \
    opencv tesseract tesseract-data-eng
```

#### macOS
```bash
brew install cmake ninja git pkg-config ccache \
    qt@6 opencv tesseract
```

### Build Desktop Version

```bash
# Configure
cd build/Desktop_Qt_6_10_0-Debug
cmake ../.. -GNinja -DCMAKE_BUILD_TYPE=Debug -DDESKTOP_MODE=ON

# Build
cmake --build . --parallel

# Run
./file_transfer_ovimage
```

## Android Development Setup

### Prerequisites

- **Supported OS**: Linux or macOS
- **Disk Space**: ~15 GB (Android SDK/NDK)
- **Internet**: Required for downloads
- **Java**: JDK 17 (automatically installed)

### What Gets Installed

1. **Java JDK**
   - OpenJDK 17

2. **Android SDK**
   - Command line tools
   - Platform Tools (adb, fastboot)
   - SDK Platform (API 33)
   - Build Tools (33.0.2)

3. **Android NDK**
   - NDK 25.1.8937393
   - Clang/LLVM toolchain
   - CMake for Android

4. **Qt for Android**
   - Note: Must be installed manually via Qt installer
   - Required: Qt 6.10.0 for Android (ARM 64-bit)

5. **OpenCV for Android**
   - Downloaded automatically
   - ARM64-v8a binaries

### Manual Android Setup

#### Install Android SDK Manually

```bash
# Download command line tools
# Linux:
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip

# macOS:
curl -O https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip

# Extract
mkdir -p ~/Android/Sdk/cmdline-tools
unzip commandlinetools-*.zip -d ~/Android/Sdk/cmdline-tools
mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest

# Set environment
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"

# Install components
sdkmanager --licenses
sdkmanager "platform-tools" \
           "platforms;android-33" \
           "build-tools;33.0.2" \
           "ndk;25.1.8937393" \
           "cmake;3.22.1"
```

#### Install Qt for Android

1. Download Qt Online Installer: https://www.qt.io/download
2. Run installer
3. Select components:
   - Qt 6.10.0
   - Android ARM 64-bit
   - Qt Creator (optional)
4. Complete installation
5. Set environment:
   ```bash
   export Qt6_DIR="$HOME/Qt/6.10.0"
   ```

#### Install OpenCV for Android

```bash
# Download
curl -L -o opencv-android.zip \
    https://github.com/opencv/opencv/releases/download/4.10.0/opencv-4.10.0-android-sdk.zip

# Extract
mkdir -p external
unzip opencv-android.zip -d external
mv external/OpenCV-android-sdk external/opencv-android

# Set environment
export OPENCV_ANDROID="$(pwd)/external/opencv-android"
```

### Environment Configuration

The setup script creates `android-env.sh` in project root:

```bash
# Source before building
source android-env.sh

# Or add to ~/.bashrc or ~/.zshrc:
echo "source ~/projects/file_transfer_ovimage/android-env.sh" >> ~/.bashrc
```

### Build Android Version

```bash
# Source environment
source android-env.sh

# Build using convenience script
./build.sh android arm64-v8a

# Or build manually
cd build/Android_Qt_6_10_0_Clang_arm64_v8a-Debug
cmake ../.. \
    -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-33 \
    -DMOBILE_MODE=ON

cmake --build .

# Install to device
adb install -r android-build/app.apk
```

## Verification

### Check Installation

```bash
# Show system info
./scripts/setup/setup.sh info

# Or manually check:
cmake --version
ninja --version
qmake6 --version  # or qmake --version
pkg-config --modversion opencv4
tesseract --version
java -version
adb --version
```

### Test Build

```bash
# Desktop
cd build/Desktop_Qt_6_10_0-Debug
cmake ../.. && cmake --build .
./file_transfer_ovimage

# Android (with device connected)
source android-env.sh
./build.sh android arm64-v8a
adb install -r build/android-build/*.apk
```

## Troubleshooting

### Desktop Issues

**Qt not found**
```bash
# Find Qt installation
find /usr -name "Qt6Config.cmake" 2>/dev/null
find $HOME -name "Qt6Config.cmake" 2>/dev/null

# Set Qt6_DIR
export Qt6_DIR=/path/to/qt6
```

**OpenCV not found**
```bash
# Check pkg-config
pkg-config --list-all | grep opencv

# Set OpenCV_DIR if needed
export OpenCV_DIR=/usr/lib/cmake/opencv4
```

**Tesseract errors** (Optional on desktop)
```bash
# Disable Tesseract in CMake
cmake .. -DENABLE_TESSERACT=OFF
```

### Android Issues

**sdkmanager not found**
```bash
# Check SDK path
echo $ANDROID_SDK_ROOT
ls $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager

# Fix path if needed
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
```

**NDK not found**
```bash
# List installed NDKs
ls $ANDROID_SDK_ROOT/ndk/

# Set correct version
export ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/25.1.8937393"
```

**Qt for Android not found**
```bash
# Find Qt installation
find $HOME/Qt -name "Qt6AndroidConfig.cmake" 2>/dev/null

# Set Qt6_DIR
export Qt6_DIR="$HOME/Qt/6.10.0"
```

**ABI mismatch**
```bash
# Build for correct ABI
./build.sh android arm64-v8a  # 64-bit ARM (modern)
./build.sh android armeabi-v7a  # 32-bit ARM (legacy)
```

### Permission Issues

```bash
# Fix script permissions
chmod +x scripts/setup/*.sh
chmod +x build.sh test.sh ci.sh

# Fix SDK permissions (if needed)
chmod -R u+w $ANDROID_SDK_ROOT
```

## Environment Variables Reference

### Desktop Mode
```bash
Qt6_DIR=/path/to/qt6              # Qt installation
OpenCV_DIR=/path/to/opencv        # OpenCV CMake config
TESSERACT_DIR=/path/to/tesseract  # Tesseract (if custom)
```

### Android Mode
```bash
ANDROID_SDK_ROOT=$HOME/Android/Sdk
ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/25.1.8937393
Qt6_DIR=$HOME/Qt/6.10.0
OPENCV_ANDROID=$PWD/external/opencv-android
JAVA_HOME=/usr/lib/jvm/java-17-openjdk  # Usually auto-detected
```

## Platform-Specific Notes

### Ubuntu 20.04/22.04
- Qt6 available in default repos (22.04)
- Qt6 requires PPA on 20.04
- Tesseract 4.x in 20.04, 5.x in 22.04

### Fedora/RHEL
- Use `dnf` instead of `apt`
- Some packages have different names
- Enable EPEL repo on RHEL

### Arch Linux
- Rolling release has latest packages
- Use `pacman` package manager
- Usually no issues with dependencies

### macOS
- Use Homebrew for packages
- May need Xcode Command Line Tools
- Qt6 installs to `/usr/local/opt/qt@6`

### Windows (WSL)
- Use WSL2 with Ubuntu
- Follow Linux instructions
- X11 forwarding for GUI apps

## Advanced Configuration

### Custom Qt Installation

If Qt is installed in non-standard location:

```bash
export Qt6_DIR="/custom/path/to/qt6"
export PATH="$Qt6_DIR/bin:$PATH"
export QML_IMPORT_PATH="$Qt6_DIR/qml"
```

### Multiple Qt Versions

```bash
# Use specific version
export Qt6_DIR="$HOME/Qt/6.10.0/gcc_64"

# Or use qtchooser (if available)
export QT_SELECT=6
```

### Cross-Compilation

For Android on different architectures:

```bash
# ARM 64-bit (modern devices)
./build.sh android arm64-v8a

# ARM 32-bit (older devices)
./build.sh android armeabi-v7a

# x86_64 (emulators)
./build.sh android x86_64
```

## Continuous Integration

For CI/CD environments, use non-interactive mode:

```bash
# Desktop CI
DEBIAN_FRONTEND=noninteractive ./scripts/setup/setup.sh desktop

# Android CI
ANDROID_SDK_ROOT=/opt/android-sdk ./scripts/setup/setup.sh android
```

See [CI/CD Guide](guides/CI_CD_GUIDE.md) for more details.

## See Also

- [Build Modes Documentation](BUILD_MODES.md)
- [CI/CD Guide](guides/CI_CD_GUIDE.md)
- [Self-Healing Build System](guides/SELF_HEALING_CI.md)
- [Quick Start Guide](../README.md)

## Support

If setup fails:

1. Check system requirements
2. Review error messages
3. Run `./scripts/setup/setup.sh info` to check installed components
4. Check troubleshooting section above
5. File an issue with:
   - OS and version
   - Error output
   - Output of `./scripts/setup/setup.sh info`

---

**Last Updated**: 2024-10-30
