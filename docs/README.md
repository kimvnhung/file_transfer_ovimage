# Documentation

Comprehensive documentation for the File Transfer Over Image project.

## Directory Structure

```
docs/
├── guides/         # Detailed guides and tutorials
├── reference/      # Quick reference documentation
├── summary/        # Project summaries and changelogs
├── images/         # Documentation images
└── src/            # Source documentation (qdoc files)
```

## Guides

Comprehensive step-by-step documentation:

- **[Self-Healing CI Guide](guides/SELF_HEALING_CI.md)** - Complete build-time self-healing system
- **[Runtime Self-Healing Guide](guides/RUNTIME_SELF_HEALING.md)** - Device testing with runtime error detection
- **[CI/CD Guide](guides/CI_CD_GUIDE.md)** - CI/CD setup and configuration
- **[Android Build Guide](guides/ANDROID_BUILD_GUIDE.md)** - Manual Android build instructions
- **[OpenCV Android Setup](guides/OPENCV_ANDROID_SETUP_COMPLETE.md)** - OpenCV configuration for Android
- **[WSL Android Device Setup](guides/WSL_ANDROID_DEVICE_SETUP.md)** - Connect Android devices in WSL2

## Quick References

Fast lookup documentation:

- **[CI Quick Start](reference/CI_QUICK_START.md)** - Quick CI/CD commands
- **[Self-Healing Quick Ref](reference/SELF_HEALING_QUICK_REF.md)** - Command cheat sheet
- **[Quick Setup](reference/QUICK_SETUP.md)** - Fast project setup with Qt Creator

## Project Summaries

High-level project information:

- **[Implementation Summary](summary/IMPLEMENTATION_SUMMARY.md)** - Complete implementation overview
- **[Changelog](summary/CHANGELOG.md)** - Project change history

## Quick Start

### Build System
```bash
# Simple build with self-healing
./build.sh

# Runtime testing on device
./test.sh

# CI helper commands
./ci.sh build
./ci.sh test
./ci.sh logs
```

### Documentation Topics

- **Getting Started**: See [Quick Setup](reference/QUICK_SETUP.md)
- **Understanding Self-Healing**: See [Self-Healing CI Guide](guides/SELF_HEALING_CI.md)
- **Testing on Devices**: See [Runtime Self-Healing](guides/RUNTIME_SELF_HEALING.md)
- **Manual Building**: See [Android Build Guide](guides/ANDROID_BUILD_GUIDE.md)
- **Environment Setup**: See [OpenCV Setup](guides/OPENCV_ANDROID_SETUP_COMPLETE.md)

## Contributing

When adding new documentation:
1. Place detailed guides in `guides/`
2. Place quick references in `reference/`
3. Place project summaries in `summary/`
4. Add images to `images/`
5. Update this README with links

See [CONTRIBUTING.md](../CONTRIBUTING.md) for more details.
