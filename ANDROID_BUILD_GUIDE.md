# Android Build Guide for OpenCV Integration

This guide explains how to build the project for Android ARM64-v8a with OpenCV support.

## Prerequisites

1. **Qt 6.10.0 for Android** installed
2. **Android NDK** (installed via Qt Creator or Android Studio)
3. **Android SDK** (minimum API level 24 recommended)
4. **OpenCV Android SDK** (automatically installed by setup script)

## OpenCV Android SDK Setup

### Automatic Installation (Recommended)

Run the setup script included in the project:

```bash
./setup_opencv_android.sh
```

This will:
- Download OpenCV 4.10.0 Android SDK
- Extract it to `$HOME/Android/OpenCV-android-sdk`
- Configure all supported ABIs (arm64-v8a, armeabi-v7a, x86, x86_64)

### Manual Installation

If you prefer to install manually:

1. Download OpenCV Android SDK from: https://opencv.org/releases/
2. Extract to: `$HOME/Android/OpenCV-android-sdk`
3. Verify the structure:
   ```
   $HOME/Android/OpenCV-android-sdk/
   ├── sdk/
   │   ├── native/
   │   │   ├── jni/
   │   │   │   ├── abi-arm64-v8a/
   │   │   │   │   ├── OpenCVConfig.cmake
   │   │   │   │   └── ...
   │   │   │   ├── abi-armeabi-v7a/
   │   │   │   ├── abi-x86/
   │   │   │   └── abi-x86_64/
   │   │   └── libs/
   │   │       ├── arm64-v8a/
   │   │       │   └── libopencv_java4.so
   │   │       └── ...
   ```

## Qt Creator Configuration

### Method 1: Using CMake Arguments (Recommended)

1. Open **Qt Creator**
2. Go to **Projects** mode (Ctrl+5)
3. Select **Android Qt 6.10.0 Clang arm64-v8a** kit
4. Under **Build Settings** → **CMake**, add to **Initial Configuration**:

```cmake
OpenCV_DIR:PATH=$HOME/Android/OpenCV-android-sdk/sdk/native/jni/abi-arm64-v8a
```

Or use the environment variable:

```cmake
OpenCV_DIR:PATH=%{Env:HOME}/Android/OpenCV-android-sdk/sdk/native/jni/abi-arm64-v8a
```

### Method 2: Environment Variable

1. Open **Qt Creator**
2. Go to **Projects** → **Build Environment**
3. Add environment variable:
   - Variable: `OpenCV_DIR`
   - Value: `/home/hungkv/Android/OpenCV-android-sdk/sdk/native/jni/abi-arm64-v8a`

### Method 3: CMakeLists.txt Override

If the above methods don't work, you can hardcode the path in CMakeLists.txt (line ~30):

```cmake
if(ANDROID)
    if(NOT DEFINED OpenCV_DIR)
        set(OpenCV_DIR "/home/hungkv/Android/OpenCV-android-sdk/sdk/native/jni" CACHE PATH "OpenCV Android SDK directory")
    endif()
    # ... rest of the configuration
endif()
```

## Building for Android

### Step 1: Configure the Build

1. Open the project in Qt Creator
2. Select **Android Qt 6.10.0 Clang arm64-v8a** kit
3. Click **Configure Project**
4. Wait for CMake configuration to complete

### Step 2: Verify OpenCV Detection

Check the **Compile Output** tab for these messages:

```
-- Android build detected
-- OpenCV_DIR: /home/hungkv/Android/OpenCV-android-sdk/sdk/native/jni/abi-arm64-v8a
-- ANDROID_ABI: arm64-v8a
-- Found OpenCV: 4.10.0
-- OpenCV Version: 4.10.0
```

If you see these messages, OpenCV is properly configured!

### Step 3: Build the Project

1. Click **Build** (Ctrl+B)
2. Wait for compilation to complete
3. Check for errors in the **Issues** tab

### Common Build Issues

#### Issue 1: OpenCV not found

**Error:**
```
CMake Error at CMakeLists.txt:54 (find_package):
  Could not find a package configuration file provided by "OpenCV"
```

**Solution:**
- Verify OpenCV Android SDK is installed at: `$HOME/Android/OpenCV-android-sdk`
- Check CMake arguments include correct `OpenCV_DIR`
- Reconfigure the project (right-click project → **Run CMake**)

#### Issue 2: Wrong ABI architecture

**Error:**
```
error: ... is incompatible with arm64-v8a
```

**Solution:**
- Ensure you're using the correct kit: **Android Qt 6.10.0 Clang arm64-v8a**
- Verify `ANDROID_ABI` matches `OpenCV_DIR` path (both should be arm64-v8a)

#### Issue 3: Missing OpenCV libraries at runtime

**Error:** App crashes with "dlopen failed: library not found"

**Solution:**
The CMakeLists.txt automatically handles this, but verify that `libopencv_java4.so` is included in the APK:
```cmake
# This is already configured in CMakeLists.txt
target_link_libraries(opencv_player PRIVATE ${OpenCV_LIBS})
```

## Deploying to Device

### Step 1: Connect Android Device

1. Enable **Developer Options** on your Android device
2. Enable **USB Debugging**
3. Connect via USB
4. Allow USB debugging when prompted

### Step 2: Deploy and Run

1. In Qt Creator, select **Run** (Ctrl+R)
2. Choose your device from the **Select Android Device** dialog
3. Wait for APK installation
4. App will launch automatically

## Architecture Support

The project supports multiple Android architectures:

| ABI | OpenCV Path | Status |
|-----|-------------|--------|
| arm64-v8a | `abi-arm64-v8a` | ✅ Recommended |
| armeabi-v7a | `abi-armeabi-v7a` | ✅ Supported |
| x86 | `abi-x86` | ✅ Emulator only |
| x86_64 | `abi-x86_64` | ✅ Emulator only |

To switch architectures:
1. Select different kit in Qt Creator (e.g., **Android Qt 6.10.0 Clang armeabi-v7a**)
2. CMakeLists.txt will automatically select the correct OpenCV ABI

## Testing on Emulator

If testing on Android Emulator:

1. Create an emulator with **API 29+** and **x86_64** architecture
2. Use the **Android Qt 6.10.0 Clang x86_64** kit
3. OpenCV will automatically use `abi-x86_64` libraries

## Troubleshooting

### CMake cannot find OpenCV

```bash
# Check if OpenCV SDK exists
ls -la $HOME/Android/OpenCV-android-sdk/sdk/native/jni/abi-arm64-v8a/

# Should show:
# OpenCVConfig.cmake
# OpenCVConfig-version.cmake
# OpenCVModules.cmake
# OpenCVModules-release.cmake
```

### Check OpenCV library

```bash
# Verify library exists
ls -lh $HOME/Android/OpenCV-android-sdk/sdk/native/libs/arm64-v8a/

# Should show:
# libopencv_java4.so (~20MB)
```

### Re-run setup script

```bash
# Clean and reinstall
rm -rf $HOME/Android/OpenCV-android-sdk
./setup_opencv_android.sh
```

## Additional Resources

- [OpenCV Android Documentation](https://docs.opencv.org/4.x/d5/df8/tutorial_dev_with_OCV_on_Android.html)
- [Qt for Android Documentation](https://doc.qt.io/qt-6/android.html)
- [Qt Android CMake Documentation](https://doc.qt.io/qt-6/android-building.html)

## Support

If you encounter issues not covered in this guide:

1. Check the **Compile Output** in Qt Creator for detailed error messages
2. Verify all paths are correct (no typos in OpenCV_DIR)
3. Ensure Android NDK is properly installed
4. Try cleaning and rebuilding: **Build** → **Clean All** → **Rebuild All**

---

**Last Updated:** October 28, 2025
**OpenCV Version:** 4.10.0
**Qt Version:** 6.10.0
