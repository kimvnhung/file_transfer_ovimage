# CI/CD Quick Reference

## Local Development Workflow

```bash
# 1. First time setup
./ci-helper.sh setup

# 2. Build APK
./ci-helper.sh build

# 3. Connect device (WSL2)
./connect_android_wifi.sh

# 4. Test on device
./ci-helper.sh test

# 5. View results
./ci-helper.sh logs
```

## Common Commands

```bash
# Full rebuild
./ci-helper.sh clean && ./ci-helper.sh build

# Debug build
BUILD_TYPE=Debug ./ci-helper.sh build

# Build for specific ABI
ANDROID_ABI=armeabi-v7a ./ci-helper.sh build

# Test on specific device
DEVICE_SERIAL=192.168.1.100:5555 ./ci-helper.sh test
```

## GitHub Actions

Automatic builds trigger on:
- Push to `main` or `dev_with_ai_agent`
- Pull requests

View results: GitHub → Actions tab

## Output Locations

```
ci-reports/
├── app-arm64-v8a-Release.apk   # Your APK
├── build-report.txt             # Build summary
├── test-report.txt              # Test summary
├── screenshot.png               # App screenshot
├── logcat.txt                   # Full logs
└── errors.txt                   # Filtered errors
```

## Troubleshooting

```bash
# Environment check
./verify_opencv_android.sh

# View build errors
cat ci-reports/build.log | grep -i error

# View test errors
cat ci-reports/errors.txt

# Clean everything
./ci-helper.sh clean
```

## Tips

- Use `./ci-helper.sh help` for full command list
- APK is automatically signed for debug/testing
- Reports persist until next build
- Screenshots help verify UI issues
- Check `CI_CD_GUIDE.md` for detailed documentation
