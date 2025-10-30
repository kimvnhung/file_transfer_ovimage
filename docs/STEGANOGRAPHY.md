# File Transfer via Steganography

## Overview

The file transfer feature uses **LSB (Least Significant Bit) steganography** to hide files inside images. This allows transferring files visually between devices without wireless, internet, or cables.

## How It Works

### Encoding Process
1. Select a **carrier image** (PNG, JPG, BMP) that will hold the hidden data
2. Select the **file to hide** (any file type)
3. The system:
   - Validates the image has sufficient capacity
   - Creates a header with file metadata (magic number, version, filename, size)
   - Embeds the header + file data into the image's pixel LSBs
   - Saves as a PNG file (lossless format preserves hidden data)

### Decoding Process
1. Select an **image with hidden data**
2. The system:
   - Validates the magic number ("STEG")
   - Extracts the header to get filename and data size
   - Extracts the file data from pixel LSBs
   - Saves the original file

## Technical Details

### LSB Encoding Parameters
- **Bits per channel**: 2 (uses 2 LSBs of each RGB channel)
- **Bits per pixel**: 6 (2 bits × 3 channels)
- **Capacity formula**: `(width × height × 3 × 2) / 8 - 256 bytes`

### Example Capacities
| Image Size | Capacity |
|-----------|----------|
| 640×480 | ~442 KB |
| 1024×768 | ~1.13 MB |
| 1920×1080 | ~3.0 MB |
| 3840×2160 (4K) | ~11.9 MB |

### Data Header Format
```
MAGIC (4 bytes) : "STEG"
VERSION (2 bytes) : 0x0001
FILENAME_LENGTH (2 bytes) : Length of filename
FILENAME (variable) : UTF-8 encoded filename
FILE_SIZE (8 bytes) : Size of file data in bytes
DATA (variable) : The actual file content
```

## Usage Examples

### Desktop Mode (Encoding)

1. Launch the application
2. Navigate to **"📦 File Transfer"**
3. Ensure **Encode Mode** is active (toggle if needed)
4. **Step 1**: Select a carrier image
   - Click "📁 Choose Image"
   - Select a high-resolution image (larger = more capacity)
   - View the calculated capacity
5. **Step 2**: Select file to hide
   - Click "📄 Choose File"
   - Select any file (must fit within capacity)
6. **Step 3**: Choose output location
   - Click "💾 Choose Output"
   - Specify where to save the encoded PNG
7. Click **"🔒 Encode File"**
8. Wait for progress bar to complete
9. Success! The output image contains your hidden file

### Mobile Mode (Decoding)

1. Display the encoded image on a PC/monitor
2. Launch the app on mobile device
3. Navigate to **"📦 File Transfer"**
4. Switch to **Decode Mode** (toggle button)
5. **Option A - Camera Capture**:
   - Point camera at the displayed image
   - Capture/select the image
6. **Option B - From Gallery**:
   - Click "📁 Choose Image"
   - Select from gallery
7. **Optional**: Click "🔍 Check for Hidden Data" to verify
8. **Step 2**: Choose output directory
   - Click "📂 Choose Directory"
   - Select where to save the extracted file
9. Click **"🔓 Decode File"**
10. Wait for extraction to complete
11. Success! The original file is saved

## Use Cases

### 1. PC to Mobile Transfer
- Display encoded image on PC screen
- Capture with mobile camera
- Decode and save file on mobile

### 2. QR Code Alternative
- Encode files in images instead of QR codes
- Higher capacity than QR codes
- Works with standard image formats

### 3. Secure File Sharing
- Hidden files are not obvious
- Images look normal to casual observers
- Can be shared via normal image channels

### 4. Air-Gapped Transfer
- Transfer files between isolated systems
- No network connection required
- Visual channel only

## Best Practices

### For Best Results

**Carrier Image Selection**:
- ✅ Use high-resolution images (more capacity)
- ✅ Use images with natural noise/texture
- ✅ PNG format recommended
- ❌ Avoid images with large solid color areas
- ❌ Don't use highly compressed JPGs

**File Size**:
- ✅ Check capacity before encoding
- ✅ Compress large files first if needed
- ❌ Don't exceed image capacity

**Display/Capture**:
- ✅ Display at full resolution
- ✅ Ensure good lighting for camera capture
- ✅ Avoid screen glare/reflections
- ✅ Capture image straight-on (no angle)
- ❌ Don't downscale/compress when sharing

**Format Preservation**:
- ✅ Always save encoded images as PNG
- ✅ Transfer using lossless methods
- ❌ Never convert to lossy JPEG after encoding
- ❌ Don't apply filters/edits to encoded images

## Limitations

- **Lossy Compression**: JPEG compression will destroy hidden data
- **Image Editing**: Any pixel modifications invalidate the data
- **Camera Quality**: Low-quality captures may fail to decode
- **Screen Quality**: Low DPI displays may lose LSB precision
- **File Size**: Limited by carrier image dimensions

## Security Notes

⚠️ **This is NOT encryption!**
- Hidden data is obscured, not encrypted
- Anyone with this tool can extract the data
- The image looks normal but data is technically visible
- For security, encrypt files BEFORE embedding

## C++ API Reference

### Class: `Steganography`

#### Properties
- `bool isProcessing` - Currently encoding/decoding
- `int progress` - Progress percentage (0-100)
- `QString lastError` - Last error message
- `qint64 maxCapacity` - Maximum capacity of last loaded image

#### Methods

**Capacity Calculation**:
```cpp
Q_INVOKABLE qint64 calculateCapacity(const QString &imagePath);
```

**Encoding**:
```cpp
Q_INVOKABLE bool encodeFileInImage(
    const QString &imagePath,      // Carrier image
    const QString &secretFilePath, // File to hide
    const QString &outputPath      // Output PNG path
);
```

**Decoding**:
```cpp
Q_INVOKABLE bool decodeFileFromImage(
    const QString &stegoImagePath, // Image with hidden data
    const QString &outputDirPath   // Where to save extracted file
);
```

**Validation**:
```cpp
Q_INVOKABLE bool hasHiddenData(const QString &imagePath);
Q_INVOKABLE QString getHiddenFileInfo(const QString &imagePath);
```

#### Signals
- `void encodeComplete(const QString &outputPath, qint64 fileSize)`
- `void decodeComplete(const QString &outputPath, qint64 fileSize)`
- `void encodeFailed(const QString &error)`
- `void decodeFailed(const QString &error)`
- `void progressChanged(int progress)`

## QML Integration

The `Steganography` instance is globally available in QML as `steganography`:

```qml
Button {
    text: "Encode"
    enabled: !steganography.isProcessing
    onClicked: {
        steganography.encodeFileInImage(
            carrierImage,
            secretFile,
            outputPath
        )
    }
}

ProgressBar {
    from: 0
    to: 100
    value: steganography.progress
    visible: steganography.isProcessing
}

Connections {
    target: steganography
    
    function onEncodeComplete(outputPath, fileSize) {
        console.log("Encoding complete:", outputPath)
    }
    
    function onEncodeFailed(error) {
        console.error("Encoding failed:", error)
    }
}
```

## Testing

### Manual Test Steps

1. **Encode Test**:
   ```
   Carrier: test.png (1920×1080)
   Secret: document.pdf (2 MB)
   Output: encoded.png
   Expected: Success, ~3 MB capacity available
   ```

2. **Decode Test**:
   ```
   Input: encoded.png
   Output directory: /tmp/decoded/
   Expected: document.pdf restored exactly
   ```

3. **Capacity Test**:
   ```
   Carrier: small.png (640×480)
   Secret: large.zip (5 MB)
   Expected: Error "File too large for image capacity"
   ```

4. **Validation Test**:
   ```
   Check normal image: Expected false
   Check encoded image: Expected true with filename
   ```

## Troubleshooting

**"File too large for image capacity"**
- Solution: Use larger carrier image or compress file first

**"Failed to load image"**
- Check image format (PNG/JPG/BMP supported)
- Verify file path is correct

**"Invalid stego image format"**
- Image doesn't contain hidden data
- Image was corrupted/compressed after encoding

**"Decoding failed"**
- Image quality too low (use higher resolution)
- Image was edited after encoding
- Carrier image was saved as lossy JPEG

**Progress stuck at 0%**
- Check file permissions
- Verify sufficient disk space
- Check application logs for errors

## Future Enhancements

Potential improvements:
- [ ] Error correction codes for robustness
- [ ] Multiple image support for large files
- [ ] Compression before embedding
- [ ] Built-in encryption option
- [ ] Batch encoding/decoding
- [ ] Reed-Solomon error correction
- [ ] BCH codes for camera capture errors
- [ ] Automatic image size recommendation
- [ ] File splitting across multiple images
- [ ] Checksum validation

## References

- [Steganography on Wikipedia](https://en.wikipedia.org/wiki/Steganography)
- [LSB Method](https://en.wikipedia.org/wiki/Bit_numbering#Least_significant_bit)
- Qt Image Processing: [QImage Documentation](https://doc.qt.io/qt-6/qimage.html)
