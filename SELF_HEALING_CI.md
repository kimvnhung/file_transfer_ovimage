# Self-Healing CI/CD System

## Overview

This project includes an advanced **Self-Healing CI/CD System** that automatically detects build errors, analyzes them, and attempts to fix them without human intervention.

## 🤖 Features

### Automatic Error Detection
- **CMake Configuration Errors**: Missing dependencies, incorrect paths
- **QML Import Errors**: Missing relative imports, undefined types
- **C++ Compilation Errors**: Missing includes, undefined symbols
- **OpenCV Issues**: SDK not found, incorrect paths
- **Permission Problems**: Incorrect file permissions

### Intelligent Auto-Fix Strategies
1. **QML Import Fixes**: Automatically adds missing relative imports
2. **QML Type Registration**: Adds `QML_ELEMENT` macro to C++ classes
3. **OpenCV SDK Download**: Downloads SDK if missing
4. **Include Fixes**: Adds missing C++ header includes
5. **Permission Fixes**: Corrects file permissions

### Multi-Attempt Build Loop
- Tries up to **3 build attempts**
- Analyzes errors after each failure
- Applies fixes and retries automatically
- Commits fixes with `[skip ci]` tag to prevent loops

## 🚀 Usage

### GitHub Actions (Automatic)

The workflow triggers automatically on push/PR:

```yaml
# .github/workflows/self-healing-ci.yml
on:
  push:
    branches: [ main, dev_with_ai_agent ]
  pull_request:
    branches: [ main, dev_with_ai_agent ]
```

**Workflow Jobs:**
1. **build-and-fix**: Builds with auto-fix loop
2. **test-android**: Tests on emulator if build succeeds
3. **analyze-results**: Generates summary report

**Features:**
- ✅ Multi-ABI support (arm64-v8a, armeabi-v7a, x86, x86_64)
- ✅ Qt and OpenCV caching for faster builds
- ✅ Automatic issue creation on failure
- ✅ APK and log artifact uploads
- ✅ Emulator testing with crash detection

### Local Self-Healing Build

Run the local self-healing build script:

```bash
# Set ABI (optional, defaults to arm64-v8a)
export ANDROID_ABI=arm64-v8a

# Run self-healing build
./self-heal-build.sh
```

**What it does:**
1. ✅ Checks prerequisites (Qt, OpenCV, NDK)
2. 🔄 Attempts build up to 3 times
3. 🔍 Analyzes errors after each failure
4. 🔧 Applies automatic fixes
5. ♻️ Retries build with fixes
6. 📊 Generates detailed reports

**Output locations:**
- APK: `build/android-arm64-v8a/android-build/*.apk`
- Logs: `ci-reports/self-heal/`
  - `cmake-log-1.txt`, `cmake-log-2.txt`, etc.
  - `build-log-1.txt`, `build-log-2.txt`, etc.
  - `fix-log-<timestamp>.txt`

### Manual Error Analysis

You can also run the analyzer manually:

```bash
# Analyze a specific log file
.github/scripts/analyze-and-fix.sh build/build-log.txt
```

## 📋 Error Detection Patterns

### QML Import Errors

**Detected patterns:**
```
error: PhotoCaptureControls is not a type
error: module "app.OpenCV_VideoPlayer" is not installed
error: CameraPropertyPopup is not a type
```

**Auto-fix:**
- Adds `import "../components"` for component usage
- Adds `import "../dialogs"` for dialog usage  
- Adds `import "../controls"` for control usage
- Changes `app.OpenCV_*` to `opencv_player` module

### QML Type Registration

**Detected patterns:**
```
error: module "opencv_player" is not installed
error: Type OpenCV_VideoPlayer unavailable
```

**Auto-fix:**
- Adds `#include <QQmlEngine>` to headers
- Adds `QML_ELEMENT` macro after `Q_OBJECT`
- Applies to classes with `Q_PROPERTY`, `Q_INVOKABLE`, or `signals:`

### OpenCV Not Found

**Detected patterns:**
```
CMake Error: Could not find OpenCV
error: OpenCV not found
```

**Auto-fix:**
- Downloads OpenCV 4.10.0 Android SDK
- Extracts to `~/Android/OpenCV-android-sdk`
- Updates CMake cache

### Missing Includes

**Detected patterns:**
```
error: use of undeclared identifier 'QQmlEngine'
error: no member named 'qmlRegisterType'
```

**Auto-fix:**
- Adds `#include <QQmlEngine>` for QML registration
- Adds `#include <QQuickPaintedItem>` for Quick items
- Adds common missing headers

## 🔍 How It Works

### Analysis Flow

```
Build Failed
     ↓
Extract Errors from Log
     ↓
Pattern Matching:
  - QML import errors?
  - Missing QML_ELEMENT?
  - OpenCV not found?
  - Missing includes?
  - Permission issues?
     ↓
Apply Fixes
     ↓
Retry Build
```

### Fix Strategy Priority

1. **High Priority**: Permission fixes, OpenCV download
2. **Medium Priority**: QML imports, type registration
3. **Low Priority**: Include fixes

### Safety Features

- **Max 3 attempts**: Prevents infinite loops
- **[skip ci] tag**: Prevents CI loops when committing fixes
- **Detailed logging**: All actions logged for review
- **Manual fallback**: Clear instructions when auto-fix fails

## 📊 Reporting

### GitHub Actions Summary

After each workflow run, a summary is generated:

```
🤖 Self-Healing CI Summary

Build Status: ✅ SUCCESS
- Attempts: 2
- Auto-fixes applied: Yes

Test Status: ✅ SUCCESS

Workflow Details
- Commit: abc1234
- Branch: main
- Actor: @username
```

### Issue Creation

On failure, automatic issues are created:

**Build Failure:**
```
[Auto] Build failed after 3 fix attempts - abc1234

## Build Failure Report
**Commit:** abc1234567890
**Attempts:** 3

### Errors Detected:
[Error details]

### Suggested Actions:
1. Review error logs
2. Check recent changes
3. Manual intervention required
```

**Test Failure:**
```
[Auto] Test failed on Android API 29 - abc1234

## Test Failure Report
**API Level:** 29

### Crash Log:
[Crash details]
```

## 🛠️ Configuration

### Environment Variables

```bash
# Local build
export ANDROID_ABI=arm64-v8a          # Target ABI
export ANDROID_SDK_ROOT=/path/to/sdk  # Android SDK
export OPENCV_VERSION=4.10.0          # OpenCV version

# GitHub Actions (in workflow file)
QT_VERSION: '6.10.0'
ANDROID_API_LEVEL: 23
ANDROID_NDK_VERSION: '27.2.12479018'
OPENCV_VERSION: '4.10.0'
MAX_FIX_ATTEMPTS: 3
```

### Customize Fix Attempts

Edit `.github/workflows/self-healing-ci.yml`:

```yaml
env:
  MAX_FIX_ATTEMPTS: 5  # Change from 3 to 5
```

Or for local builds, edit `self-heal-build.sh`:

```bash
MAX_ATTEMPTS=5  # Change from 3 to 5
```

## 📝 Logs and Artifacts

### GitHub Actions Artifacts

After each run, artifacts are uploaded:

- **build-logs-arm64-v8a-attempt-N**: Build logs for each attempt
- **android-apk-arm64-v8a-SHA**: Generated APK (on success)
- **test-results-apiNN**: Screenshots, logcat, crash logs

**Retention:** 7 days

### Local Logs

```
ci-reports/self-heal/
├── cmake-log-1.txt      # CMake configuration log
├── cmake-log-2.txt
├── build-log-1.txt      # Build output log
├── build-log-2.txt
└── fix-log-*.txt        # Auto-fix actions log
```

## 🐛 Troubleshooting

### Build Still Fails After 3 Attempts

1. **Check the last fix log**:
   ```bash
   cat ci-reports/self-heal/fix-log-*.txt
   ```

2. **Review detected errors**:
   ```bash
   grep -i "error:" ci-reports/self-heal/build-log-3.txt
   ```

3. **Common issues**:
   - Qt path incorrect → Check `~/Qt/6.10.0/android_arm64_v8a`
   - NDK version mismatch → Verify NDK 27.2.12479018
   - OpenCV ABI mismatch → Check ABI in CMakeLists.txt

### Auto-Fix Not Working

1. **Test analyzer manually**:
   ```bash
   .github/scripts/analyze-and-fix.sh ci-reports/self-heal/build-log-1.txt
   ```

2. **Check analyzer output**:
   ```bash
   cat fix-log-*.txt
   ```

3. **Verify file permissions**:
   ```bash
   ls -la .github/scripts/analyze-and-fix.sh
   # Should show: -rwxr-xr-x
   ```

### GitHub Actions Not Triggering

1. **Check workflow syntax**:
   ```bash
   # Install actionlint
   sudo apt install actionlint
   
   # Validate workflow
   actionlint .github/workflows/self-healing-ci.yml
   ```

2. **Verify branch name**:
   - Workflow triggers on `main` and `dev_with_ai_agent`
   - Check your current branch: `git branch`

3. **Check Actions tab**: Visit `https://github.com/USER/REPO/actions`

## 🎯 Examples

### Example 1: QML Import Fix

**Error detected:**
```
qml/views/MainView.qml:25: error: PhotoCaptureControls is not a type
```

**Auto-fix applied:**
```diff
# qml/views/MainView.qml
+import "../controls"
 import QtQuick
 import QtQuick.Controls
```

**Result:** ✅ Build succeeds on attempt 2

### Example 2: Missing QML_ELEMENT

**Error detected:**
```
error: module "opencv_player" is not installed
```

**Auto-fix applied:**
```diff
# include/opencv_player/opencv_videoplayer.h
+#include <QQmlEngine>
 #include <QObject>
 
 class OpenCV_VideoPlayer : public QObject {
     Q_OBJECT
+    QML_ELEMENT
```

**Result:** ✅ Build succeeds on attempt 2

### Example 3: OpenCV Download

**Error detected:**
```
CMake Error: Could not find OpenCV
```

**Auto-fix applied:**
```bash
Downloading OpenCV Android SDK...
Extracting to ~/Android/OpenCV-android-sdk...
```

**Result:** ✅ Build succeeds on attempt 2

## 🔐 Security Considerations

### Automatic Commits

- Auto-fixes are committed with `[skip ci]` to prevent loops
- Commits are made by "GitHub Actions Bot"
- Only applied in CI environment (not local builds)

### Token Permissions

Required for issue creation:

```yaml
permissions:
  contents: write
  issues: write
```

## 📚 Related Documentation

- [CI/CD Guide](CI_CD_GUIDE.md) - Complete CI/CD documentation
- [CI Quick Start](CI_QUICK_START.md) - Quick reference
- [Android Build Guide](ANDROID_BUILD_GUIDE.md) - Manual build instructions
- [WSL Device Setup](WSL_ANDROID_DEVICE_SETUP.md) - Device connection

## 🤝 Contributing

To add new error patterns:

1. Edit `.github/scripts/analyze-and-fix.sh`
2. Add new detection function:
   ```bash
   fix_my_error() {
       if grep -q "my error pattern" "$LOG_FILE"; then
           # Apply fix
           return 0
       fi
       return 1
   }
   ```
3. Call in `main()`:
   ```bash
   if fix_my_error; then
       log_success "Applied my fix"
       FIXED=true
   fi
   ```

## 📄 License

Same as project license (see [LICENSE](LICENSE))

---

**Last Updated:** October 29, 2025
**Version:** 1.0.0
