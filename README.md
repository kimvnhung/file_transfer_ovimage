# File Transfer Over Image

[![Qt Version](https://img.shields.io/badge/Qt-6.0%2B-green.svg)](https://www.qt.io/)
[![OpenCV](https://img.shields.io/badge/OpenCV-4.0%2B-blue.svg)](https://opencv.org/)
[![License](https://img.shields.io/badge/license-BSD--3-blue.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/build-self--healing-brightgreen.svg)](docs/guides/SELF_HEALING_CI.md)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-automated-blue.svg)](docs/guides/CI_CD_GUIDE.md)

A research project exploring innovative file transfer methods between PC and mobile devices using visual communication - transferring data through images/video without requiring wireless, internet, or cable connections.

## 🎯 Project Overview

This project combines Qt's multimedia capabilities with OpenCV's computer vision features to create a novel approach to data transfer. The system encodes file data into visual patterns that can be displayed on one device and captured by another device's camera, then decoded back into the original file.

## ✨ Features

### Camera Application
- **Real-time Camera Preview** - Live viewfinder with Qt Multimedia
- **Photo & Video Capture** - Capture still images or record videos
- **Advanced Camera Controls**
  - Camera device selection
  - Flash and torch modes
  - White balance adjustment
  - Zoom control
  - Auto-focus capabilities

### OpenCV Video Player
- **Frame-by-Frame Control** - Precise video navigation
- **Playback Controls** - Play, pause, seek functionality
- **Frame Processing** - OpenCV-powered frame manipulation
- **High-Performance Rendering** - Optimized video display

### File Transfer via Steganography ⭐ NEW!
- **LSB Steganography** - Hide files inside images using Least Significant Bit encoding
- **Dual Mode UI** - Encode files on desktop, decode on mobile
- **High Capacity** - Up to ~12 MB in 4K images
- **Visual Transfer** - Display encoded image on screen, capture with camera to decode
- **Format Preservation** - Maintains filename and file metadata
- **Progress Tracking** - Real-time encoding/decoding progress
- **Error Validation** - Magic number verification and capacity checking
- 📖 [Full Documentation](docs/STEGANOGRAPHY.md) | [Quick Start](docs/QUICKSTART_FILE_TRANSFER.md)

## 🏗️ Project Structure

```
file_transfer_ovimage/
├── CMakeLists.txt              # Main build configuration
├── declarative-camera.qrc      # Qt resource file
├── README.md                   # This file
├── LICENSE                     # BSD-3-Clause license
├── build.sh                    # Quick build wrapper
├── test.sh                     # Quick test wrapper
├── ci.sh                       # Quick CI wrapper
├── src/                        # Source files
│   ├── app/
│   │   └── main.cpp           # Application entry point
│   └── opencv_player/
│       ├── opencv_videoplayer.cpp
│       └── opencv_player_viewport.cpp
├── include/                    # Header files
│   └── opencv_player/
│       ├── opencv_videoplayer.h
│       └── opencv_player_viewport.h
├── qml/                        # QML UI files
│   ├── views/                 # Main application views
│   ├── controls/              # Reusable controls
│   ├── components/            # UI components
│   └── dialogs/               # Dialog components
├── resources/                  # Application resources
│   └── images/                # Image assets
├── scripts/                    # Build & test automation
│   ├── build/                 # Build scripts
│   │   ├── self-heal-build.sh
│   │   └── ci-helper.sh
│   ├── test/                  # Test scripts
│   │   └── test-runtime-self-healing.sh
│   ├── demo/                  # Demo scripts
│   │   ├── demo-self-healing.sh
│   │   ├── simulate-self-healing.sh
│   │   └── simulate-runtime-test.sh
│   ├── setup/                 # Setup utilities
│   │   ├── setup_opencv_android.sh
│   │   ├── verify_opencv_android.sh
│   │   ├── connect_android_wifi.sh
│   │   └── adb_reconnect.sh
│   └── ci/                    # CI scripts
│       ├── build-android.sh
│       └── test-android.sh
├── docs/                       # Documentation
│   ├── guides/                # Comprehensive guides
│   │   ├── SELF_HEALING_CI.md
│   │   ├── RUNTIME_SELF_HEALING.md
│   │   ├── CI_CD_GUIDE.md
│   │   ├── ANDROID_BUILD_GUIDE.md
│   │   ├── OPENCV_ANDROID_SETUP_COMPLETE.md
│   │   └── WSL_ANDROID_DEVICE_SETUP.md
│   ├── reference/             # Quick references
│   │   ├── CI_QUICK_START.md
│   │   ├── SELF_HEALING_QUICK_REF.md
│   │   └── QUICK_SETUP.md
│   ├── summary/               # Project summaries
│   │   ├── IMPLEMENTATION_SUMMARY.md
│   │   └── CHANGELOG.md
│   ├── images/                # Documentation images
│   └── src/                   # Source documentation
│       └── declarative-camera.qdoc
├── .github/                    # GitHub configuration
│   ├── workflows/
│   │   └── self-healing-ci.yml
│   └── scripts/
│       └── analyze-and-fix.sh
└── build/                      # Build outputs
```

## 🛠️ Requirements

### Build Dependencies
- **Qt 6.0+** with modules:
  - Qt Core, GUI, Multimedia, QML, Quick
- **OpenCV 4.0+**
- **Tesseract 5.0+** (desktop only, optional)
- **CMake 3.16+**
- **Ninja** (build system)
- **C++17 compatible compiler**

### Android-Specific Requirements
- **Android SDK API 33+**
- **Android NDK 25.1+**
- **Java JDK 17**
- **Qt for Android 6.10+**

### Runtime Requirements
- Camera device (for capture functionality)
- Graphics card with OpenGL support
- 2+ GB RAM recommended

## 🚀 Quick Start

### Automated Setup (Recommended)

```bash
# Clone the repository
git clone https://github.com/kimvnhung/file_transfer_ovimage.git
cd file_transfer_ovimage

# Run setup script (interactive)
./scripts/setup/setup.sh

# Or choose your environment directly:
./scripts/setup/setup.sh desktop    # Desktop development
./scripts/setup/setup.sh android    # Android development
./scripts/setup/setup.sh both       # Both environments

# Build and run
./build.sh        # Desktop build
./build.sh android arm64-v8a    # Android build
```

📖 See [Environment Setup Guide](docs/ENVIRONMENT_SETUP.md) for detailed instructions.

## 🔨 Manual Building

### Desktop (Linux/macOS)

```bash
# Install dependencies first (see Environment Setup Guide)

# Create build directory
mkdir -p build/Desktop_Qt_6_10_0-Debug && cd build/Desktop_Qt_6_10_0-Debug

# Configure with CMake
cmake ../.. -GNinja -DCMAKE_BUILD_TYPE=Debug -DDESKTOP_MODE=ON

# Build
cmake --build . --parallel

# Run
./file_transfer_ovimage
```

### Android

See comprehensive guides:
- **[Quick Setup](docs/reference/QUICK_SETUP.md)** - Fast setup with Qt Creator
- **[Android Build Guide](docs/guides/ANDROID_BUILD_GUIDE.md)** - Complete manual build instructions
- **[OpenCV Android Setup](docs/guides/OPENCV_ANDROID_SETUP_COMPLETE.md)** - OpenCV configuration
- **[WSL Device Setup](docs/guides/WSL_ANDROID_DEVICE_SETUP.md)** - Connect devices in WSL2

**Quick Android build:**
```bash
# Setup OpenCV Android SDK
./scripts/setup/setup_opencv_android.sh

# Build with self-healing system (auto-fixes errors)
./build.sh

# Or use CI helper
./ci.sh build
```

### Windows

```bash
# Clone the repository
git clone https://github.com/kimvnhung/file_transfer_ovimage.git
cd file_transfer_ovimage

# Create build directory
mkdir build
cd build

# Configure with CMake (adjust paths as needed)
cmake -G "Visual Studio 17 2022" ^
      -DCMAKE_PREFIX_PATH="C:/Qt/6.5.0/msvc2019_64" ^
      -DOpenCV_DIR="C:/opencv/build" ..

# Build
cmake --build . --config Release

# Run
Release\file_transfer_ovimage.exe
```

## 🤖 CI/CD & Self-Healing System

This project includes an **advanced self-healing CI/CD system** that automatically detects and fixes build errors:

- **🔄 Automatic Error Detection** - Analyzes build logs for common issues
- **🔧 Intelligent Auto-Fix** - Applies fixes for QML imports, missing includes, OpenCV issues
- **♻️ Multi-Attempt Builds** - Retries up to 3 times with fixes
- **📊 Detailed Reports** - Comprehensive logs and artifacts
- **🚀 GitHub Actions** - Automated cloud builds and testing
- **🐳 Docker Support** - Reproducible containerized builds
- **📱 Runtime Testing** - Deploy to device, analyze logcat, auto-fix errors
- **📊 Web Dashboard** - Visualize test results and logs in browser
- **🐳 Docker Support** - Reproducible containerized builds
- **📱 Runtime Testing** - Deploy to device, analyze logcat, auto-fix errors

**Quick start:**
```bash
# Local self-healing build
./build.sh

# Runtime testing on connected device
./test.sh

# View test results dashboard
./dashboard.sh

# Use CI helper for manual control
./ci.sh build
./ci.sh test
./ci.sh logs
```

**Documentation:**
- **[Self-Healing CI Guide](docs/guides/SELF_HEALING_CI.md)** - Complete build-time self-healing documentation
- **[Runtime Self-Healing](docs/guides/RUNTIME_SELF_HEALING.md)** - Device testing and runtime error fixing
- **[Test Results Dashboard](docs/guides/DASHBOARD.md)** - Web UI for visualizing test logs and results
- **[CI/CD Guide](docs/guides/CI_CD_GUIDE.md)** - Manual CI/CD setup and usage
- **[CI Quick Start](docs/reference/CI_QUICK_START.md)** - Quick reference
- **[Self-Healing Quick Ref](docs/reference/SELF_HEALING_QUICK_REF.md)** - Command cheat sheet


## 📱 Usage

### Camera Mode
1. Launch the application
2. Grant camera permissions when prompted
3. Use "Switch to Photo/Video" to toggle modes
4. Capture photos or record videos
5. Preview captured media

### Video Player Mode
1. Select a video file using the file dialog
2. Use playback controls:
   - Play/Pause button
   - Frame-by-frame navigation (◄ ►)
   - Progress bar for seeking
3. Click/double-click on video for interaction

### File Transfer (Experimental)
_Documentation will be added as features are implemented_

## 🧪 Testing

```bash
# Run tests (when available)
cd build
ctest
```

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

### Development Guidelines
- Follow Qt coding conventions
- Use C++17 features appropriately
- Document all public APIs
- Write clear commit messages
- Add tests for new features

## 📝 License

This project is licensed under the BSD-3-Clause License - see the [LICENSE](LICENSE) file for details.

Parts of this project are based on Qt examples:
- Copyright (C) 2017-2022 The Qt Company Ltd.
- SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

## 👥 Authors

- **Hung Kim** - [@kimvnhung](https://github.com/kimvnhung)

## 🙏 Acknowledgments

- Qt Framework for excellent multimedia support
- OpenCV community for powerful computer vision tools
- Research inspiration from QR codes and visual communication systems

## 📚 References

- [Qt Multimedia Documentation](https://doc.qt.io/qt-6/qtmultimedia-index.html)
- [OpenCV Documentation](https://docs.opencv.org/)
- [QML Documentation](https://doc.qt.io/qt-6/qmlapplications.html)

## 🔮 Roadmap

- [ ] Implement visual encoding algorithm
- [ ] Add error correction mechanisms
- [ ] Optimize transfer speed
- [ ] Multi-platform testing (Android, iOS)
- [ ] Performance benchmarking
- [ ] User documentation
- [ ] Example file transfer demonstrations

## 📧 Contact

For questions or suggestions, please open an issue on GitHub or contact the maintainer.

---
**Note**: This is a research project and is under active development. Features and APIs may change.
