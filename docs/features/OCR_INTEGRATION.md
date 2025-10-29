# Tesseract OCR Integration

## Overview

This project integrates Tesseract OCR for camera-based text recognition. The OCR feature allows users to point their camera at text and get real-time recognition with multiple language support.

## Platform Support

**⚠️ Important: OCR is currently available for DESKTOP builds only.**

- ✅ **Desktop (Linux/Windows/macOS)**: Full Tesseract OCR support
- ❌ **Android**: OCR disabled (requires Tesseract Android build)

The code is written to be platform-aware and will automatically disable OCR functionality on Android builds to avoid compilation errors.

## Components

### C++ Backend

#### TesseractOCR Class (`include/app/tesseractocr.h`, `src/app/tesseractocr.cpp`)

A Qt/QML-integrated wrapper for Tesseract OCR library.

**Properties:**
- `language` (QString): Current OCR language (default: "eng")
- `isInitialized` (bool): Initialization status
- `lastError` (QString): Last error message

**Methods:**
- `initialize()`: Initialize Tesseract with current language
- `recognizeText(QImage)`: Recognize text from QImage
- `recognizeFromFile(QString)`: Recognize text from file path

**Signals:**
- `textRecognized(QString)`: Emitted when text is recognized
- `recognitionProgress(int)`: Progress updates (0-100)
- `languageChanged()`: Language changed
- `isInitializedChanged()`: Initialization status changed
- `lastErrorChanged()`: Error status changed

### QML Frontend

#### OCRCameraView Component (`qml/components/OCRCameraView.qml`)

A reusable camera component with OCR overlay.

**Features:**
- Camera preview with VideoOutput
- Scanning frame overlay (80% width × 30% height)
- Visual feedback (green border when scanning)
- Text display overlay with scrollable content
- Copy to clipboard button

**Public API:**
- `captureAndRecognize()`: Capture image and perform OCR
- `clearText()`: Clear recognized text
- `startCamera()`: Start camera preview
- `stopCamera()`: Stop camera preview

#### OCRPage (`qml/views/OCRPage.qml`)

Complete OCR page with full UI.

**Features:**
- Back navigation button
- Language selector (English, Vietnamese, Chinese, Japanese, Korean)
- Capture button with visual feedback
- Auto-copy to clipboard option
- Clear text button
- Status messages with 3-second timeout

## Dependencies

### Desktop Build Requirements

```bash
# Ubuntu/Debian
sudo apt-get install -y libtesseract-dev libleptonica-dev tesseract-ocr

# Language data packages
sudo apt-get install -y tesseract-ocr-eng tesseract-ocr-vie

# Tesseract data location
/usr/share/tesseract-ocr/5/tessdata/
```

### CMake Configuration

The CMakeLists.txt automatically detects the build platform:

```cmake
# Desktop builds: Include Tesseract
if(NOT ANDROID)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(TESSERACT REQUIRED tesseract)
    pkg_check_modules(LEPTONICA REQUIRED lept)
    add_definitions(-DUSE_TESSERACT)
endif()
```

### Conditional Compilation

The code uses `#ifdef USE_TESSERACT` to conditionally compile Tesseract-specific code:

```cpp
#ifdef USE_TESSERACT
    tesseract::TessBaseAPI *m_tesseract;
    PIX* qImageToPix(const QImage &image);
#endif
```

On Android builds:
- Tesseract headers are not included
- OCR methods return error messages
- `initialize()` returns false with "not available" error

## Supported Languages

Currently configured languages:

- **eng**: English
- **vie**: Vietnamese
- **chi_sim**: Chinese Simplified
- **jpn**: Japanese
- **kor**: Korean

To add more languages:
1. Install language data: `sudo apt-get install tesseract-ocr-<lang>`
2. Update language selector in `OCRPage.qml`

## Usage in QML

The TesseractOCR instance is exposed globally in main.cpp:

```cpp
TesseractOCR tesseractOCR;
view.rootContext()->setContextProperty("tesseractOCR", &tesseractOCR);
```

Access in QML:

```qml
Component.onCompleted: {
    tesseractOCR.initialize()
}

Button {
    text: "Scan"
    onClicked: {
        var text = tesseractOCR.recognizeText(capturedImage)
        console.log("Recognized:", text)
    }
}
```

## Image Conversion

QImage → Leptonica PIX conversion:

1. Convert QImage to `Format_RGBA8888`
2. Create PIX with 32-bit depth
3. Copy pixel data (R << 24 | G << 16 | B << 8 | A)
4. Use `pixDestroy()` to clean up

## Error Handling

All OCR methods set `lastError` property on failure:

```qml
Connections {
    target: tesseractOCR
    function onLastErrorChanged() {
        if (tesseractOCR.lastError !== "") {
            statusLabel.text = tesseractOCR.lastError
        }
    }
}
```

## Future Enhancements

### Android Support

To enable OCR on Android:

1. **Build Tesseract for Android:**
   - Use vcpkg or manually build Tesseract + Leptonica for ARM64
   - Install to Android NDK sysroot

2. **Update CMakeLists.txt:**
   ```cmake
   if(ANDROID)
       set(TESSERACT_ANDROID_DIR "$ENV{HOME}/Android/tesseract-android")
       include_directories(${TESSERACT_ANDROID_DIR}/include)
       link_directories(${TESSERACT_ANDROID_DIR}/lib/${ANDROID_ABI})
   endif()
   ```

3. **Bundle tessdata files:**
   - Copy tessdata to Android assets
   - Update initialize() to use Android paths

### Real-time OCR

- Add continuous scanning mode
- Process camera frames periodically
- Debounce text updates

### OCR Accuracy Improvements

- Add preprocessing filters (contrast, brightness)
- Allow user to adjust PSM (Page Segmentation Mode)
- Add confidence threshold filtering

## Testing

### Desktop Testing

```bash
# Build for desktop
cd build
cmake .. -DCMAKE_PREFIX_PATH=/path/to/Qt/gcc_64
make

# Run
./file_transfer_ovimage
```

### Verify OCR

1. Navigate to OCR page
2. Select language
3. Point camera at text
4. Click "Scan Text"
5. Verify recognized text appears

## Troubleshooting

### "Failed to initialize Tesseract"

- Check tessdata path: `/usr/share/tesseract-ocr/5/tessdata/`
- Verify language data installed: `ls /usr/share/tesseract-ocr/5/tessdata/eng.traineddata`

### "Tesseract OCR is not available in this build"

- This is expected on Android builds
- Build for desktop to use OCR features

### Poor recognition quality

- Ensure good lighting
- Hold camera steady
- Adjust camera distance
- Try different languages
- Check text contrast

## References

- [Tesseract OCR Documentation](https://tesseract-ocr.github.io/)
- [Leptonica Image Processing](http://www.leptonica.org/)
- [Qt QML Camera](https://doc.qt.io/qt-6/qml-qtmultimedia-camera.html)
