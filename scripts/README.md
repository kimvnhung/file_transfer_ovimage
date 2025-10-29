# Scripts Directory

Automation scripts for building, testing, and managing the project.

## Directory Structure

```
scripts/
├── build/          # Build automation scripts
├── test/           # Testing scripts
├── demo/           # Demonstration scripts
├── setup/          # Environment setup utilities
└── ci/             # CI/CD integration scripts
```

## Quick Start

From the project root, use the wrapper scripts:

```bash
# Build with self-healing
./build.sh

# Test on device with runtime self-healing
./test.sh

# Use CI helper commands
./ci.sh build
./ci.sh test
```

## Subdirectories

### build/
Build automation with self-healing capabilities:
- `self-heal-build.sh` - Main build script with auto-fix loop
- `ci-helper.sh` - Makefile-style convenience wrapper

### test/
Testing automation:
- `test-runtime-self-healing.sh` - Deploy to device, monitor logcat, auto-fix errors

### demo/
Demonstration scripts showing system capabilities:
- `demo-self-healing.sh` - Interactive demo of build-time self-healing
- `simulate-self-healing.sh` - Simulated build with error fixes
- `simulate-runtime-test.sh` - Simulated runtime testing

### setup/
Environment configuration:
- `setup_opencv_android.sh` - Download and configure OpenCV Android SDK
- `verify_opencv_android.sh` - Verify OpenCV installation
- `connect_android_wifi.sh` - Connect to Android device over WiFi
- `adb_reconnect.sh` - Reconnect ADB connection

### ci/
CI/CD integration scripts:
- `build-android.sh` - CI build script
- `test-android.sh` - CI test script

## Documentation

See the [docs/guides](../docs/guides/) directory for comprehensive documentation:
- [Self-Healing CI Guide](../docs/guides/SELF_HEALING_CI.md)
- [Runtime Self-Healing Guide](../docs/guides/RUNTIME_SELF_HEALING.md)
- [CI/CD Guide](../docs/guides/CI_CD_GUIDE.md)
- [CI Quick Start](../docs/reference/CI_QUICK_START.md)
