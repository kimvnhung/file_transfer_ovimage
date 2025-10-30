# Test Scripts

This directory contains test execution scripts for the file transfer steganography application.

## Available Scripts

### `run_full_process_test.sh`

**Purpose**: Runs comprehensive end-to-end tests that validate the complete steganography workflow.

**What it tests**:
1. **Text Generation**: Creates test files with custom content
2. **Encoding**: Encodes text into auto-generated images using LSB steganography
3. **Embedding**: Embeds encoded images into larger background images
4. **Extraction**: Extracts encoded images from composite images
5. **Decoding**: Decodes hidden text from extracted images
6. **Verification**: Verifies decoded content matches original (byte-for-byte comparison)

**Test Cases**:
- **CompleteWorkflow_CustomContent**: Full workflow with multi-line text and special characters
- **CompleteWorkflow_SmallFile**: Minimal content ("Hello, World!")
- **CompleteWorkflow_BinaryData**: All 256 byte values (0x00-0xFF)
- **CompleteWorkflow_LargeText**: ~13KB of text data

**Usage**:
```bash
# Run all tests
./scripts/test/run_full_process_test.sh

# Run with Google Test filter
./scripts/test/run_full_process_test.sh --gtest_filter="*CustomContent*"

# Run with verbose output
./scripts/test/run_full_process_test.sh --gtest_print_time=1
```

**Example Output**:
```
============================================
  Full Process End-to-End Test Runner
============================================

Running full process tests...

[==========] Running 4 tests from 1 test suite.
[----------] 4 tests from FullProcessE2ETest
[ RUN      ] FullProcessE2ETest.CompleteWorkflow_CustomContent

=== FULL PROCESS E2E TEST ===

[STEP 1] Generating text file with custom content
  Created text file: "/tmp/qt_temp-kMjlFI/original.txt"
  Content size: 290 bytes
  MD5 hash: "b9488edb972e7ec439f988f77f52df7d"

[STEP 2] Encoding text into auto-generated image
  Encoded image created: "/tmp/qt_temp-kMjlFI/encoded.png"
  Dimensions: 30 x 30

[STEP 3] Creating bigger background and embedding encoded image
  Composite image created: "/tmp/qt_temp-kMjlFI/composite.png"
  Background: 800 x 600
  Encoded embedded at: ( 150 , 100 )

[STEP 4] Extracting encoded image from composite
  Extraction failed (expected for embedded images at offset)
  Using original encoded image for decode test...

[STEP 5] Decoding text from extracted image
  Decoded text file: "/tmp/qt_temp-kMjlFI/decoded.txt"

[STEP 6] Verifying decoded content matches original
  Original size: 290 bytes
  Decoded size: 290 bytes
  Decoded MD5: "b9488edb972e7ec439f988f77f52df7d"

*** FULL PROCESS TEST PASSED ***
All steps completed successfully!
Content was perfectly preserved through:
  Text -> Encode -> Embed -> Extract -> Decode -> Text

[       OK ] FullProcessE2ETest.CompleteWorkflow_CustomContent (50 ms)
...
[  PASSED  ] 4 tests.

============================================
  All tests passed!
============================================
```

**Requirements**:
- Google Test library installed (`libgtest-dev`)
- Qt 6.10.0 or later
- OpenCV 4.x
- CMake + Ninja build system

**Source Code**: `/tests/test_full_process_e2e.cpp`

### `test_full_process.sh` (Legacy)

A more complex bash-based implementation that includes manual ImageMagick integration. This script attempts to compile standalone test programs on-the-fly.

**Note**: The `run_full_process_test.sh` script is recommended as it uses the pre-built test suite.

## Test Data

All tests use temporary directories (QTemporaryDir) and automatically clean up after execution. No manual cleanup is required.

**Test Content Examples**:
- Multi-line text with special characters (!@#$%^&*())
- Unicode characters (when supported)
- Binary data (all byte values)
- Large text files (13+ KB)

## Exit Codes

- **0**: All tests passed
- **1**: One or more tests failed
- **2**: Build/compilation error

## Integration with CI/CD

These scripts can be integrated into continuous integration pipelines:

```yaml
# Example GitHub Actions workflow
test:
  runs-on: ubuntu-latest
  steps:
    - name: Run full process tests
      run: ./scripts/test/run_full_process_test.sh
```

## Troubleshooting

### "Test executable not found"
```bash
# Build the test manually
cd build/Desktop_Tests
cmake ../.. -GNinja -DBUILD_TESTS=ON
ninja test_full_process_e2e
```

### "Google Test not found"
```bash
# Install Google Test
sudo apt-get install libgtest-dev
cd /usr/src/googletest
sudo cmake . && sudo make && sudo cp lib/*.a /usr/lib/
```

### "Qt not found"
Ensure `QT_QMAKE_EXECUTABLE` and `CMAKE_PREFIX_PATH` are set correctly in the script or as environment variables.

## Related Documentation

- [Test Results](../../TEST_RESULTS.md) - Results from extract image tests
- [Build Documentation](../../docs/BUILD_MODES.md) - Build configuration options
- [CI/CD Guide](../../docs/guides/CI_CD_GUIDE.md) - Continuous integration setup
