# Quick Start - File Transfer Feature

## For Users

### Encode a File (Desktop)
1. Open app → **"📦 File Transfer"**
2. Click **"📁 Choose Image"** → Select a large photo
3. Click **"📄 Choose File"** → Select file to hide
4. Click **"💾 Choose Output"** → Set output path
5. Click **"🔒 Encode File"** → Wait for completion
6. ✅ Done! Share the output PNG

### Decode a File (Mobile)
1. Display encoded PNG on PC screen (full size)
2. Open app → **"📦 File Transfer"**
3. Toggle to **"📥 DECODE MODE"**
4. Capture image with camera OR pick from gallery
5. Click **"📂 Choose Directory"** → Set save location
6. Click **"🔓 Decode File"** → Wait for extraction
7. ✅ Done! File saved to chosen directory

## For Developers

### Using in C++
```cpp
#include "steganography.h"

Steganography stego;

// Check capacity
qint64 capacity = stego.calculateCapacity("carrier.png");
qDebug() << "Capacity:" << capacity << "bytes";

// Encode
bool success = stego.encodeFileInImage(
    "carrier.png",      // Large image
    "secret.pdf",       // File to hide
    "encoded.png"       // Output
);

// Decode
success = stego.decodeFileFromImage(
    "encoded.png",      // Image with hidden data
    "/output/path/"     // Where to save file
);

// Validate
bool hasData = stego.hasHiddenData("encoded.png");
QString info = stego.getHiddenFileInfo("encoded.png");
```

### Using in QML
```qml
import QtQuick

Item {
    Button {
        text: "Encode"
        enabled: !steganography.isProcessing
        onClicked: {
            steganography.encodeFileInImage(
                carrierImagePath,
                secretFilePath,
                outputPath
            )
        }
    }
    
    ProgressBar {
        from: 0
        to: 100
        value: steganography.progress
    }
    
    Connections {
        target: steganography
        
        function onEncodeComplete(path, size) {
            console.log("Success:", path, size)
        }
        
        function onEncodeFailed(error) {
            console.error("Failed:", error)
        }
    }
}
```

## Capacity Reference

| Image Resolution | Approximate Capacity |
|-----------------|---------------------|
| 640×480 (VGA) | ~442 KB |
| 1024×768 (XGA) | ~1.13 MB |
| 1280×720 (HD) | ~1.69 MB |
| 1920×1080 (Full HD) | ~3.0 MB |
| 2560×1440 (2K) | ~5.3 MB |
| 3840×2160 (4K) | ~11.9 MB |

**Formula**: `(width × height × 3 × 2) / 8 - 256 bytes`

## Best Practices

### ✅ DO
- Use PNG format for carrier images
- Use high-resolution images for larger files
- Display encoded images at full resolution
- Capture with good lighting (for camera decoding)
- Save encoded images as PNG (lossless)
- Verify capacity before encoding

### ❌ DON'T
- Convert encoded images to JPEG (lossy)
- Edit/filter encoded images
- Downscale encoded images
- Use tiny carrier images
- Exceed image capacity

## Troubleshooting

**"File too large"**
→ Use larger carrier image or compress file

**"Failed to load image"**
→ Check image format (PNG/JPG/BMP)

**"Invalid stego image"**
→ Image doesn't contain hidden data or was corrupted

**Decoding fails after camera capture**
→ Use better lighting, higher camera resolution, or display image larger

## Files Structure

```
include/app/
  └── steganography.h           # C++ header
src/app/
  ├── main.cpp                  # QML registration
  └── steganography.cpp         # Implementation
qml/views/
  └── FileTransferPage.qml      # UI
docs/
  ├── STEGANOGRAPHY.md          # Full documentation
  └── summary/
      └── FILE_TRANSFER_IMPLEMENTATION.md
```

## Testing

```bash
# Build
cd build/Desktop_Qt_6_10_0-Debug
cmake ../.. && cmake --build .

# Run
./file_transfer_ovimage

# Navigate to File Transfer feature
# Test encode → decode workflow
```

## API Summary

### Properties
- `bool isProcessing` - Operation in progress?
- `int progress` - Current progress (0-100)
- `QString lastError` - Last error message
- `qint64 maxCapacity` - Last calculated capacity

### Methods
- `calculateCapacity(imagePath)` → capacity in bytes
- `encodeFileInImage(carrier, secret, output)` → bool success
- `decodeFileFromImage(stego, outputDir)` → bool success
- `hasHiddenData(imagePath)` → bool
- `getHiddenFileInfo(imagePath)` → QString

### Signals
- `encodeComplete(outputPath, fileSize)`
- `decodeComplete(outputPath, fileSize)`
- `encodeFailed(error)`
- `decodeFailed(error)`
- `progressChanged(progress)`

## Need Help?

- 📖 Full docs: `docs/STEGANOGRAPHY.md`
- 📋 Implementation: `docs/summary/FILE_TRANSFER_IMPLEMENTATION.md`
- 💬 Issues: Check error messages and `steganography.lastError`
- 🐛 Debugging: Enable qDebug() output in steganography.cpp

---

**Quick tip**: Start with small files and low-res images for testing, then scale up to full-size transfers.
