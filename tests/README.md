# Steganography Test Suite

Comprehensive unit tests for the LSB steganography implementation.

## Test Structure

```
tests/
├── CMakeLists.txt              # Test build configuration
├── test_utils.h/.cpp           # Testing utilities and fixtures
├── unit/                       # Unit tests
│   ├── test_steganography.cpp              # Core functionality tests
│   ├── test_steganography_edge_cases.cpp   # Boundary & edge cases
│   └── test_steganography_performance.cpp  # Performance benchmarks
└── data/                       # Test data (images, files)
```

## Test Coverage

### Core Functionality Tests (`test_steganography.cpp`)
- ✅ Capacity calculation for various image sizes
- ✅ Encode/decode small text files
- ✅ Encode/decode binary data
- ✅ Encode/decode large files (10KB+)
- ✅ Image quality preservation (PSNR > 40 dB)
- ✅ Hidden data detection
- ✅ Metadata extraction
- ✅ Error handling (invalid files, oversized data)
- ✅ Progress tracking
- ✅ Multiple image patterns (solid, gradient, noise, checkerboard)

### Edge Cases Tests (`test_steganography_edge_cases.cpp`)
- ✅ Empty files
- ✅ Single-byte files
- ✅ Maximum capacity utilization
- ✅ Over-capacity rejection
- ✅ Minimal images (1x1 pixels)
- ✅ Long filenames (>100 characters)
- ✅ Special characters in filenames
- ✅ Unicode filenames
- ✅ All-zero byte patterns
- ✅ All-ones byte patterns
- ✅ Alternating bit patterns
- ✅ Corrupted magic number detection
- ✅ Truncated image handling
- ✅ Multiple encode/decode cycles
- ✅ Extreme dimensions (very wide/tall images)

### Performance Tests (`test_steganography_performance.cpp`)
- ✅ Small files (1 KB - 100 KB)
- ✅ Medium files (1 MB)
- ✅ Large files (5 MB)
- ✅ Performance scaling with image size
- ✅ Memory efficiency
- ✅ Repeated operations consistency
- ✅ Capacity calculation speed

## Building and Running Tests

### Prerequisites
```bash
# Install Google Test
sudo apt-get install libgtest-dev
cd /usr/src/gtest
sudo cmake .
sudo make
sudo cp lib/*.a /usr/lib
```

### Build Tests
```bash
cd build
mkdir Desktop_Tests
cd Desktop_Tests

# Configure with tests enabled
cmake ../.. \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Debug \
    -DDESKTOP_MODE=ON \
    -DBUILD_TESTS=ON \
    -DCMAKE_PREFIX_PATH=/home/hungkv/Qt/6.10.0/gcc_64

# Build
ninja
```

### Run All Tests
```bash
cd tests
./steganography_tests
```

### Run Specific Tests
```bash
# Run only core functionality tests
./steganography_tests --gtest_filter=SteganographyTest.*

# Run only edge case tests
./steganography_tests --gtest_filter=SteganographyEdgeCaseTest.*

# Run only performance benchmarks
./steganography_tests --gtest_filter=SteganographyPerformanceTest.*

# Run a specific test
./steganography_tests --gtest_filter=SteganographyTest.EncodeAndDecode_SmallTextFile_Success
```

### Verbose Output
```bash
./steganography_tests --gtest_print_time=1 --gtest_color=yes
```

## Test Metrics

### Expected Performance Benchmarks
| File Size | Image Size | Encode Time | Decode Time |
|-----------|-----------|-------------|-------------|
| 1 KB      | 100x100   | < 500 ms    | < 500 ms    |
| 100 KB    | 400x400   | < 2 sec     | < 2 sec     |
| 1 MB      | 1000x1000 | < 5 sec     | < 5 sec     |
| 5 MB      | 2000x2000 | < 15 sec    | < 15 sec    |

### Image Quality Metrics
- **PSNR**: > 40 dB (imperceptible changes)
- **Visual Similarity**: > 99%
- **LSB Modification**: Only 2 lowest bits per channel

## Test Utilities

### ImageGenerator
- `createSolidColorImage()` - Uniform color images
- `createGradientImage()` - Color gradient patterns
- `createRandomNoiseImage()` - Random pixel values
- `createCheckerboardImage()` - Black/white checkerboard
- `createImageForCapacity()` - Image with specific capacity

### FileGenerator
- `createRandomData()` - Random binary data
- `createTextData()` - UTF-8 text data
- `createPatternData()` - Repeating byte patterns
- `createSequentialData()` - Sequential 0-255 bytes

### Validator
- `compareBytes()` - Exact binary comparison
- `imagesVisuallySimilar()` - Visual similarity check
- `calculatePSNR()` - Peak Signal-to-Noise Ratio
- `isValidImage()` - Image validity check

## Continuous Integration

Tests should be run:
- Before committing to main branch
- In CI/CD pipeline
- After algorithm changes
- Before releases

## Adding New Tests

1. Add test function to appropriate file
2. Follow naming convention: `TEST_F(FixtureName, TestName_Scenario_ExpectedResult)`
3. Use descriptive test names
4. Include EXPECT/ASSERT macros
5. Clean up resources in tearDown
6. Update this README

## Known Limitations

- Performance tests may vary based on hardware
- Large file tests (>10MB) are disabled by default (can enable with flag)
- Some Unicode filename tests may fail on non-UTF8 filesystems

## Contact

For test failures or new test suggestions, contact the development team.
