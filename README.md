# File Transfer Over Image

[![Qt Version](https://img.shields.io/badge/Qt-6.0%2B-green.svg)](https://www.qt.io/)
[![OpenCV](https://img.shields.io/badge/OpenCV-4.0%2B-blue.svg)](https://opencv.org/)
[![License](https://img.shields.io/badge/license-BSD--3-blue.svg)](LICENSE)

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

### File Transfer (Research Component)
- Visual encoding/decoding algorithms (in development)
- Error correction mechanisms
- Progressive transfer with visual feedback

## 🏗️ Project Structure

```
file_transfer_ovimage/
├── CMakeLists.txt              # Main build configuration
├── declarative-camera.qrc      # Qt resource file
├── README.md                   # This file
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
│   │   ├── MainView.qml
│   │   ├── PhotoPreview.qml
│   │   ├── VideoPreview.qml
│   │   ├── HomePage.qml
│   │   └── PermissionDenied.qml
│   ├── controls/              # Reusable controls
│   │   ├── PhotoCaptureControls.qml
│   │   ├── VideoCaptureControls.qml
│   │   ├── ZoomControl.qml
│   │   └── FlashControl.qml
│   ├── components/            # UI components
│   │   ├── CameraButton.qml
│   │   ├── CameraListButton.qml
│   │   └── CameraPropertyButton.qml
│   └── dialogs/               # Dialog components
│       ├── Popup.qml
│       ├── CameraListPopup.qml
│       └── CameraPropertyPopup.qml
├── resources/                  # Application resources
│   └── images/                # Image assets
└── docs/                       # Documentation
    ├── images/
    └── src/
```

## 🛠️ Requirements

### Build Dependencies
- **Qt 6.0+** with modules:
  - Qt Core
  - Qt GUI
  - Qt Multimedia
  - Qt QML
  - Qt Quick
- **OpenCV 4.0+**
- **CMake 3.16+**
- **C++17 compatible compiler**

### Runtime Requirements
- Camera device (for capture functionality)
- Graphics card with OpenGL support

## 🚀 Building the Project

### Linux/macOS

```bash
# Clone the repository
git clone https://github.com/kimvnhung/file_transfer_ovimage.git
cd file_transfer_ovimage

# Create build directory
mkdir build && cd build

# Configure with CMake
cmake ..

# Build
cmake --build .

# Run
./file_transfer_ovimage
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
