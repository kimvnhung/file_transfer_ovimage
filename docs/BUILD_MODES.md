# Build Modes - Platform Auto-Detection

## Overview

The application automatically detects the target platform and builds with the appropriate UI:

- **Mobile Platforms** (Android, iOS): Full mobile UI with camera, permissions, and navigation
- **Desktop Platforms** (Linux, Windows, macOS): Simplified test UI for development

## Platform Detection

### CMakeLists.txt Logic

```cmake
if(ANDROID OR IOS)
    set(MOBILE_MODE ON)
    message(STATUS "Platform: ${CMAKE_SYSTEM_NAME} - Building in MOBILE MODE")
else()
    set(DESKTOP_MODE ON)
    add_definitions(-DDESKTOP_MODE)
    message(STATUS "Platform: ${CMAKE_SYSTEM_NAME} - Building in DESKTOP MODE")
endif()
```

### Platform-Specific Behavior

| Platform | Mode | UI Entry Point | Features |
|----------|------|---------------|----------|
| Android | MOBILE | AppMain.qml | Full UI, Camera, OCR warning |
| iOS | MOBILE | AppMain.qml | Full UI, Camera, OCR warning |
| Linux | DESKTOP | DesktopTestView.qml | Simple "Hello World", OCR test |
| Windows | DESKTOP | DesktopTestView.qml | Simple "Hello World", OCR test |
| macOS | DESKTOP | DesktopTestView.qml | Simple "Hello World", OCR test |

## Build Commands

### Desktop Build (Linux/Windows/macOS)
```bash
./scripts/build/desktop-test-build.sh
```

**Output:**
```
Platform: Linux - Building in DESKTOP MODE
Simplified UI for testing
```

**Result:**
- Builds to: `build/Desktop_TestMode/`
- Loads: `DesktopTestView.qml`
- Shows: "Hello World" test interface

### Mobile Build (Android)
```bash
./scripts/build/cmake-build.sh
```

**Output:**
```
Platform: Android - Building in MOBILE MODE
Full mobile UI with camera and permissions
```

**Result:**
- Builds to: `build/Android_Qt_6_10_0_Clang_arm64_v8a-Debug/`
- Loads: `AppMain.qml`
- Shows: Full navigation menu with Camera/Video/OCR

## Code Integration

### main.cpp Conditional Compilation

```cpp
#ifdef DESKTOP_MODE
    // Desktop Test Mode - Simplified UI
    qDebug() << "=== DESKTOP TEST MODE ===";
    engine.load(QUrl("qrc:/qml/views/DesktopTestView.qml"));
#else
    // Mobile Mode - Full Application
    qDebug() << "=== MOBILE MODE ===";
    #if QT_CONFIG(permissions)
        // Request camera permissions for mobile
        QCameraPermission cameraPermission;
        qApp->requestPermission(cameraPermission, ...);
    #endif
    engine.load(QUrl("qrc:/qml/views/AppMain.qml"));
#endif
```

## Testing Different Modes

### Test Desktop Mode
```bash
# Build
./scripts/build/desktop-test-build.sh

# Run
./build/Desktop_TestMode/file_transfer_ovimage
```

**Expected:**
- Window opens with "Hello World"
- System info displayed
- OCR status shown
- Test button works

### Test Mobile Mode
```bash
# Build and install to device
./scripts/build/cmake-build.sh

# Or use ADB
adb install -r app-debug.apk
adb shell am start -n org.qtproject.example.file_transfer_ovimage/.QtActivity
```

**Expected:**
- Main menu with 3 options
- Camera/Video features work
- OCR shows warning message

## Advantages of Auto-Detection

1. **No Manual Configuration**: Platform is detected automatically
2. **Consistent Builds**: Same commands work across platforms
3. **Developer Friendly**: Quick desktop testing without mobile overhead
4. **Production Ready**: Full mobile features when needed
5. **CI/CD Compatible**: Build scripts don't need platform-specific flags

## Troubleshooting

### Wrong Mode Detected?

Check CMake output:
```bash
cmake /path/to/project | grep "Platform:"
```

Should show:
```
Platform: Linux - Building in DESKTOP MODE
```
or
```
Platform: Android - Building in MOBILE MODE
```

### Force Desktop Mode on Mobile Platform

Not recommended, but possible by modifying CMakeLists.txt:
```cmake
# Force desktop mode (for testing only)
set(DESKTOP_MODE ON)
add_definitions(-DDESKTOP_MODE)
```

### Verify Runtime Mode

Check console output when launching:
```
=== DESKTOP TEST MODE ===  # Desktop
=== MOBILE MODE ===         # Mobile
```

## Future Enhancements

Possible additions:
- iOS build scripts
- Windows build scripts (.bat files)
- macOS-specific configurations
- Platform-specific feature flags
- Conditional OCR compilation per platform
