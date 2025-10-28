# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Complete project restructuring with professional organization
- Comprehensive README.md with badges, features, and usage instructions
- CONTRIBUTING.md with development guidelines and code standards
- OpenCV-based video player with frame-by-frame control
- Enhanced VideoPreview with playback controls
- QML module organization (views, components, controls, dialogs)
- qmldir files for proper QML module structure
- Professional CMakeLists.txt with clear sections and comments
- Build configuration summary output

### Changed
- Reorganized source files into `src/` and `include/` directories
- Moved QML files to `qml/` with logical subdirectories
- Moved resources to `resources/` directory
- Updated all file paths to match new structure
- Replaced MediaPlayer with OpenCV player in VideoPreview
- Renamed `declarative-camera.qml` to `MainView.qml`
- Renamed `qmlcamera.cpp` to `main.cpp`
- Updated image resource paths to use `qrc:/resources/images/`
- Enhanced CMake configuration with better organization

### Fixed
- Include paths in OpenCV player source files
- Resource paths in all QML files
- QRC file structure and organization

## [1.0.0] - Initial Release

### Added
- Basic camera application with Qt Multimedia
- Photo and video capture functionality
- Camera controls (flash, white balance, zoom)
- Camera device selection
- Preview functionality for photos and videos
- OpenCV integration for video processing
- Basic project structure

---

## Version History Notes

### Project Evolution
This project started as a Qt declarative camera example and evolved into a research project for file transfer using visual communication. The restructuring in version 2.0.0 provides a solid foundation for future development.

### Migration Guide
If you're upgrading from an earlier version:

1. **File Locations Changed:**
   - All QML files moved to `qml/` subdirectories
   - C++ sources moved to `src/` and `include/`
   - Resources moved to `resources/`

2. **QML Import Changes:**
   - Use proper module imports from subdirectories
   - Image paths now use `qrc:/resources/images/`

3. **Build System:**
   - CMake configuration updated with new paths
   - Rerun CMake configuration for existing build directories

4. **API Changes:**
   - VideoPreview now uses OpenCV player instead of MediaPlayer
   - Enhanced playback controls and frame navigation

### Future Roadmap
See README.md for upcoming features and development plans.
