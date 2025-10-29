# CI/CD Documentation

## Overview

This project includes both **GitHub Actions** for cloud-based CI/CD and **local CI/CD scripts** for building and testing on your machine.

## GitHub Actions CI/CD

### Workflows

The GitHub Actions workflow (`.github/workflows/android-ci.yml`) runs automatically on:
- Push to `main` or `dev_with_ai_agent` branches
- Pull requests to these branches
- Manual trigger via GitHub UI

### Jobs

1. **build-android** - Builds Android APK
   - Installs Qt 6.10.0 for Android
   - Downloads OpenCV Android SDK
   - Configures and builds with CMake
   - Uploads APK as artifact

2. **test-android** - Tests on Android Emulator
   - Runs on API levels 29 and 33
   - Installs and launches app
   - Captures screenshots and logs
   - Uploads test results

3. **lint-and-analyze** - Code quality checks
   - Runs clang-tidy
   - Runs cppcheck
   - Uploads analysis reports

### Artifacts

Artifacts are available in GitHub Actions run:
- `android-apk-{abi}-{sha}` - Built APK files
- `test-results-api{level}` - Test screenshots and logs
- `code-quality-reports` - Static analysis reports
- `build-logs-{abi}` - Build logs

### Configuration

Edit `.github/workflows/android-ci.yml` to customize:
- Qt version
- Android API level
- NDK version
- OpenCV version
- Target ABIs

## Local CI/CD

### Quick Start

```bash
# Setup environment (first time only)
./ci-helper.sh setup

# Build APK
./ci-helper.sh build

# Test on device
./ci-helper.sh test

# View logs
./ci-helper.sh logs

# Clean build artifacts
./ci-helper.sh clean
```

### Requirements

- Android NDK installed
- Qt 6.10.0 for Android installed
- ADB configured
- Device connected (for testing)

### Scripts

#### 1. build-android.sh

Builds Android APK with comprehensive logging.

```bash
# Default build (arm64-v8a, Release)
./ci/build-android.sh

# Custom ABI and build type
ANDROID_ABI=armeabi-v7a BUILD_TYPE=Debug ./ci/build-android.sh

# With custom paths
Qt6_DIR=/path/to/qt ANDROID_NDK=/path/to/ndk ./ci/build-android.sh
```

**Outputs:**
- APK: `ci-reports/app-{abi}-{type}.apk`
- Logs: `ci-reports/*.log`
- Report: `ci-reports/build-report.txt`

#### 2. test-android.sh

Tests APK on connected Android device.

```bash
# Test on default device
./ci/test-android.sh

# Test on specific device
DEVICE_SERIAL=192.168.1.100:5555 ./ci/test-android.sh

# Interactive mode
INTERACTIVE=true ./ci/test-android.sh
```

**Outputs:**
- Screenshot: `ci-reports/screenshot.png`
- Logcat: `ci-reports/logcat.txt`
- Errors: `ci-reports/errors.txt`
- Performance: `ci-reports/meminfo.txt`, `ci-reports/cpuinfo.txt`
- Report: `ci-reports/test-report.txt`

#### 3. ci-helper.sh

Convenience wrapper for all CI operations.

```bash
./ci-helper.sh [command]

Commands:
  build           Build Android APK
  test            Install and test APK on device
  clean           Clean build artifacts
  setup           Setup environment (OpenCV, etc.)
  docker-build    Build using Docker
  docker-test     Test using Docker with device
  logs            View recent test logs
  help            Show help message
```

### Environment Variables

```bash
# Android NDK path
export ANDROID_NDK=$HOME/Android/Sdk/ndk/27.2.12479018

# Qt6 CMake files
export Qt6_DIR=$HOME/Qt/6.10.0/android_arm64_v8a/lib/cmake/Qt6

# Target ABI (arm64-v8a, armeabi-v7a, x86, x86_64)
export ANDROID_ABI=arm64-v8a

# Build type (Release, Debug, RelWithDebInfo)
export BUILD_TYPE=Release

# Device serial for testing
export DEVICE_SERIAL=192.168.1.100:5555
```

## Docker-based CI

### Build Docker Image

```bash
docker-compose build
```

### Run Build in Docker

```bash
docker-compose up
```

### Custom Docker Build

```bash
docker build -t android-ci -f docker/Dockerfile.android-ci .

docker run --rm \
  -v $(pwd):/workspace \
  -e ANDROID_ABI=arm64-v8a \
  -e BUILD_TYPE=Release \
  android-ci
```

## CI Reports Structure

```
ci-reports/
├── app-arm64-v8a-Release.apk   # Built APK
├── build-report.txt             # Build summary
├── cmake-configure.log          # CMake configuration log
├── build.log                    # Build output
├── apk-info.txt                 # APK metadata
├── cppcheck-report.xml          # Static analysis
├── test-report.txt              # Test summary
├── install.log                  # Installation log
├── logcat.txt                   # Full logcat
├── errors.txt                   # Filtered errors
├── screenshot.png               # App screenshot
├── meminfo.txt                  # Memory usage
└── cpuinfo.txt                  # CPU usage
```

## Continuous Integration Best Practices

### 1. Pre-commit Checks

```bash
# Before committing
./ci-helper.sh build
./ci-helper.sh test
./ci-helper.sh logs
```

### 2. Automated Testing

Add to your git hooks (`.git/hooks/pre-push`):

```bash
#!/bin/bash
echo "Running CI build..."
./ci-helper.sh build || exit 1
echo "Build successful!"
```

### 3. Regular Checks

```bash
# Weekly full check
./ci-helper.sh clean
./ci-helper.sh setup
./ci-helper.sh build
./ci-helper.sh test
```

## Troubleshooting

### Build Fails

1. Check environment:
   ```bash
   ./verify_opencv_android.sh
   ```

2. Check logs:
   ```bash
   cat ci-reports/cmake-configure.log
   cat ci-reports/build.log
   ```

3. Clean and retry:
   ```bash
   ./ci-helper.sh clean
   ./ci-helper.sh build
   ```

### Test Fails

1. Check device connection:
   ```bash
   adb devices
   ```

2. Check app logs:
   ```bash
   adb logcat | grep -i error
   ```

3. View collected errors:
   ```bash
   cat ci-reports/errors.txt
   ```

### Docker Issues

1. Rebuild image:
   ```bash
   docker-compose build --no-cache
   ```

2. Check container logs:
   ```bash
   docker-compose logs
   ```

## Integration with IDEs

### Qt Creator

Add build configurations:
1. Projects → Build Settings → Add Build Step
2. Command: `bash ci/build-android.sh`
3. Working Directory: `%{buildDir}`

### VS Code

Add to `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build Android APK",
      "type": "shell",
      "command": "./ci-helper.sh build",
      "problemMatcher": []
    },
    {
      "label": "Test Android APK",
      "type": "shell",
      "command": "./ci-helper.sh test",
      "problemMatcher": []
    }
  ]
}
```

## Advanced Usage

### Multiple ABIs

```bash
for abi in arm64-v8a armeabi-v7a x86_64; do
    ANDROID_ABI=$abi ./ci/build-android.sh
done
```

### Performance Testing

```bash
# Build release with profiling
BUILD_TYPE=RelWithDebInfo ./ci/build-android.sh

# Install and profile
./ci/test-android.sh
adb shell am profile start com.example.app /sdcard/profile.trace
# Use app...
adb shell am profile stop com.example.app
adb pull /sdcard/profile.trace
```

### Automated Smoke Tests

Create `ci/smoke-tests.sh`:

```bash
#!/bin/bash
# Install app
./ci/test-android.sh

# Run monkey test
adb shell monkey -p com.example.app --throttle 200 -v 500

# Collect results
adb logcat -d > ci-reports/smoke-test.log
```

## Support

For issues or questions:
1. Check `ci-reports/` for logs
2. Run `./ci-helper.sh logs`
3. Review documentation: `ANDROID_BUILD_GUIDE.md`
4. Check GitHub Actions logs (if using CI/CD)

---

**Last Updated:** October 29, 2025
