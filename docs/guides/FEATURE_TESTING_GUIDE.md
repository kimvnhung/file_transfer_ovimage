# Testing Guide: Real-Time Frame Extraction Feature

## Testing Status

### ✅ Desktop Mode - TESTED
- **Status**: Successfully built and running
- **Application**: `/home/hungkv/projects/file_transfer_ovimage/build/Desktop_Qt_6_10_0-Debug/file_transfer_ovimage`
- **Build**: Successful (commit 925e072)
- **Features verified**:
  - Application launches successfully
  - Encoding works (test file tt.txt encoded successfully)
  - VideoPreview UI with extraction toggle available

### ⏳ Android Mode - BUILD PENDING
- **Status**: SDK/NDK configuration needed
- **Requirements**: 
  - Android SDK properly configured
  - NDK 27.2.12479018 or compatible
  - Qt 6.10.0 for Android (arm64-v8a)
  - Ninja build tool in PATH
- **Alternative**: Docker-based build available (`docker-compose.yml`)

---

## Desktop Mode Testing

### Prerequisites
```bash
# Ensure app is built
cd /home/hungkv/projects/file_transfer_ovimage/build/Desktop_Qt_6_10_0-Debug
ninja

# Launch application
./file_transfer_ovimage
```

### Test Scenario 1: Video File Detection

**Steps:**
1. **Create test encoded frame** (already done):
   ```bash
   # Available test frame:
   ls -lh ~/Downloads/tt_encoded.png
   # Should be 1000x1000 PNG with steganography data
   ```

2. **Create video from encoded frame** (optional):
   ```bash
   # Using ffmpeg to create a test video
   cd ~/Downloads
   
   # Create a 5-second video repeating the encoded frame
   ffmpeg -loop 1 -i tt_encoded.png -c:v libx264 -t 5 -pix_fmt yuv420p test_encoded_video.mp4
   ```

3. **Test in application**:
   - Open FileTransferView (Desktop mode)
   - Navigate to VideoPreview
   - Load `test_encoded_video.mp4`
   - Click "🔍 Detect" button (should turn green)
   - Play video
   - **Expected**: Green flash overlay when frame detected
   - **Expected**: Counter updates: "✓ Detected: X | Saved: X"
   - **Expected**: Frame saved to `~/Downloads/detected_frame_<timestamp>.png`

### Test Scenario 2: Static Image Detection

**Steps:**
1. Open VideoPreview
2. Load the encoded image as single frame
3. Enable detection mode
4. **Expected**: Immediate detection and save

### Verification Commands

```bash
# Check if frames were detected and saved
ls -lt ~/Downloads/detected_frame_*.png | head -5

# Verify detected frame is valid
cd /home/hungkv/projects/file_transfer_ovimage/build/Desktop_Qt_6_10_0-Debug
# Use app to check frame info - should show valid header

# Check application logs
tail -f /tmp/app_output.log
# Should show:
# - "Saved detected frame to: ..."
# - Detection statistics
```

### Current Desktop Test Status

**✅ Verified:**
- Application builds successfully
- Application launches without errors
- Encoding feature works (tt.txt → tt_encoded.png)
- VideoPreview component available

**🔄 To Verify:**
- Load video file in VideoPreview
- Enable detection mode
- Verify frame detection overlay
- Verify auto-save functionality
- Check detection statistics

---

## Android Mode Testing

### Build Requirements

#### Option 1: Native Build
```bash
# Ensure Qt Android is installed
ls ~/Qt/6.10.0/android_arm64_v8a/

# Set environment variables
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export ANDROID_NDK="$ANDROID_SDK_ROOT/ndk/27.2.12479018"
export QT_ANDROID_PATH="$HOME/Qt/6.10.0/android_arm64_v8a"

# Install ninja if not available
sudo apt-get install ninja-build  # Ubuntu/Debian
# or
brew install ninja  # macOS

# Build APK
cd /home/hungkv/projects/file_transfer_ovimage
bash scripts/build/android-build.sh
```

**Common Issues:**
1. **Qt not found**: Install Qt for Android or set `QT_ANDROID_PATH`
2. **NDK not found**: Install Android NDK or set `ANDROID_NDK`
3. **Ninja not found**: Install ninja build tool
4. **ABI mismatch**: Use `arm64_v8a` (underscore) not `arm64-v8a` (dash)

#### Option 2: Docker Build (Recommended)
```bash
cd /home/hungkv/projects/file_transfer_ovimage

# Build container and APK
docker-compose up android-ci

# APK location after build:
# build/Android_Qt_6.10.0_Clang_arm64-v8a-Release/android-build/build/outputs/apk/release/
```

### Android Testing Steps

#### Installation
```bash
# Connect Android device via USB or use emulator
adb devices

# Install APK
adb install -r path/to/file_transfer_ovimage.apk

# Grant permissions (camera, storage)
adb shell pm grant com.example.filetransfer android.permission.CAMERA
adb shell pm grant com.example.filetransfer android.permission.WRITE_EXTERNAL_STORAGE
```

#### Test Scenario 1: Camera Detection

**Setup:**
1. Display encoded frame on another device/screen
2. Launch app on Android device
3. Navigate to camera view

**Steps:**
1. Open camera view
2. Tap detection toggle button "🔍 Detect"
3. Point camera at encoded frame (1000×1000)
4. **Expected**: Green border flash on detection
5. **Expected**: Statistics update
6. **Expected**: Frame saved to Downloads

**Verification:**
```bash
# Check saved frames via ADB
adb shell ls -la /storage/emulated/0/Download/detected_frame_*.png

# Pull frames to computer for verification
adb pull /storage/emulated/0/Download/detected_frame_<timestamp>.png ./

# Check logs
adb logcat | grep -i "detected frame"
```

#### Test Scenario 2: Video File Detection

**Steps:**
1. Push test video to device:
   ```bash
   adb push test_encoded_video.mp4 /storage/emulated/0/Download/
   ```
2. Open video in app
3. Enable detection mode
4. Play video
5. **Expected**: Automatic frame detection and save

### Performance Testing (Android)

**Metrics to measure:**
```bash
# CPU usage
adb shell top -n 1 | grep file_transfer

# Battery drain
adb shell dumpsys battery

# Memory usage
adb shell dumpsys meminfo com.example.filetransfer

# Frame rate
adb logcat | grep -i "fps"
```

**Expected Performance:**
- Detection overhead: 5-10% CPU
- Frame processing: 1-2ms per frame
- No dropped frames during detection
- Battery: ~10% increase in consumption when active

---

## Feature Verification Checklist

### Desktop Mode
- [ ] Application builds without errors
- [ ] Application launches successfully
- [ ] VideoPreview loads without errors
- [ ] Detection toggle button visible
- [ ] Detection toggle changes state (gray → green)
- [ ] Statistics display shows counters
- [ ] Video playback works normally
- [ ] Detection overlay appears on valid frame
- [ ] Detection overlay flashes 3 times
- [ ] Frame saved to Downloads folder
- [ ] Saved frame has correct format (PNG, 1000×1000)
- [ ] Saved frame filename includes timestamp
- [ ] Detection statistics increment correctly
- [ ] No performance impact when detection disabled
- [ ] No crashes or memory leaks

### Android Mode
- [ ] APK builds without errors
- [ ] APK installs on device
- [ ] App launches without crashes
- [ ] Camera permission granted
- [ ] Storage permission granted
- [ ] Camera view works
- [ ] Detection toggle accessible
- [ ] Camera feed shows in VideoPreview
- [ ] Detection works with camera feed
- [ ] Detection overlay visible on Android
- [ ] Frames saved to device storage
- [ ] No excessive battery drain
- [ ] No UI lag during detection
- [ ] App doesn't crash on rotation
- [ ] Works on different Android versions (API 26+)

---

## Troubleshooting

### Desktop Issues

**Issue**: App won't launch
```bash
# Check dependencies
ldd ./file_transfer_ovimage | grep "not found"

# Check Qt plugins
export QT_DEBUG_PLUGINS=1
./file_transfer_ovimage
```

**Issue**: Detection not working
```bash
# Check logs
tail -f /tmp/app_output.log

# Verify frame is valid
# Use app's "Check Frame Info" feature on test image
```

**Issue**: Frames not saving
```bash
# Check permissions
ls -ld ~/Downloads/

# Check disk space
df -h ~/Downloads/

# Check logs for errors
grep -i "save" /tmp/app_output.log
```

### Android Issues

**Issue**: APK won't install
```bash
# Check device compatibility
adb shell getprop ro.build.version.sdk  # Should be >= 26

# Clear previous installation
adb uninstall com.example.filetransfer
adb install path/to/app.apk
```

**Issue**: Camera not working
```bash
# Check permissions
adb shell dumpsys package com.example.filetransfer | grep permission

# Grant manually
adb shell pm grant com.example.filetransfer android.permission.CAMERA
```

**Issue**: Detection not triggering
```bash
# Check logs
adb logcat -s "OpenCV_VideoPlayer:*" "SteganographyV2:*"

# Verify frame format
# Frame must be exactly 1000×1000 pixels
# Frame must have valid BorderHeader
```

---

## Test Results Template

### Test Report: [Date]

**Environment:**
- OS: [Linux/Android version]
- Device: [Model/CPU]
- Qt Version: 6.10.0
- Build Type: Debug/Release
- Commit: 925e072

**Desktop Tests:**
| Test Case | Status | Notes |
|-----------|--------|-------|
| App Launch | ✅/❌ | |
| Video Load | ✅/❌ | |
| Detection Toggle | ✅/❌ | |
| Frame Detection | ✅/❌ | Frames detected: X |
| Frame Saving | ✅/❌ | Saved to: path |
| Overlay Animation | ✅/❌ | |
| Statistics Update | ✅/❌ | |

**Android Tests:**
| Test Case | Status | Notes |
|-----------|--------|-------|
| APK Build | ✅/❌ | |
| Installation | ✅/❌ | |
| App Launch | ✅/❌ | |
| Camera Access | ✅/❌ | |
| Detection Toggle | ✅/❌ | |
| Frame Detection | ✅/❌ | |
| Frame Saving | ✅/❌ | |
| Performance | ✅/❌ | CPU: X%, FPS: Y |

**Issues Found:**
1. [Description]
2. [Description]

**Recommendations:**
1. [Improvement]
2. [Fix needed]

---

## Next Steps

### Desktop Mode
1. ✅ Build completed
2. ✅ Basic functionality verified
3. ⏳ Full feature testing in progress
4. ⏳ Performance benchmarking
5. ⏳ User documentation

### Android Mode
1. ⏳ SDK/NDK setup needed
2. ⏳ APK build pending
3. ⏳ Device testing
4. ⏳ Performance optimization
5. ⏳ Release build

### Documentation
1. ✅ Implementation documented (REAL_TIME_EXTRACTION.md)
2. ✅ Testing guide created (this document)
3. ⏳ User manual update
4. ⏳ Video tutorial
5. ⏳ Release notes

---

## Quick Reference

### Build Commands
```bash
# Desktop
cd build/Desktop_Qt_6_10_0-Debug && ninja

# Android (when SDK/NDK ready)
bash scripts/build/android-build.sh

# Android (Docker)
docker-compose up android-ci
```

### Test Commands
```bash
# Launch desktop
./build/Desktop_Qt_6_10_0-Debug/file_transfer_ovimage

# Install Android
adb install path/to/app.apk

# Check logs
tail -f /tmp/app_output.log  # Desktop
adb logcat | grep file_transfer  # Android
```

### File Locations
```bash
# Desktop test frame
~/Downloads/tt_encoded.png

# Detected frames (Desktop)
~/Downloads/detected_frame_*.png

# Detected frames (Android)
/storage/emulated/0/Download/detected_frame_*.png

# Build output
build/Desktop_Qt_6_10_0-Debug/file_transfer_ovimage  # Desktop
build/Android_Qt_6.10.0_Clang_arm64-v8a-Release/android-build/build/outputs/apk/  # Android
```
