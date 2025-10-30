# Fixed 1000×1000 Encoded Image Format

## Overview

New standardized format for steganography with fixed dimensions and visible border headers.

## Image Specifications

- **Fixed Size**: 1000 × 1000 pixels (always)
- **Format**: PNG RGB888
- **Border**: 2-pixel width on all sides (8 pixels total)
- **Data Area**: 996 × 996 pixels for LSB encoding
- **Capacity**: ~1.86 MB per frame (996×996×3 channels × 2 bits / 8)

## Border Header Structure

### Layout (2-pixel border)

```
┌────────────────────────────────────┐
│     Top Border (2 pixels)          │ ← Header data encoded here
├────────────────────────────────────┤
│L│                                │R│ ← Left/Right borders (2px each)
│e│      Data Area 996×996         │i│
│f│      (LSB encoded data)        │g│
│t│                                │h│
│ │                                │t│
├────────────────────────────────────┤
│   Bottom Border (2 pixels)         │ ← Additional header data
└────────────────────────────────────┘
```

### Header Encoding (Top Border - 2000 pixels)

Each pixel encodes 6 bits (2 bits per RGB channel):

**Pixel Layout (0-based indexing)**:

```
Pixels 0-3: Magic bytes "STGV" (4 bytes = 6 pixels, rounded to 7)
Pixels 7-9: Version (2 bytes = 3 pixels)
Pixels 10-19: Filename length (1 byte = 2 pixels)
Pixels 20-79: Filename (up to 60 chars = 60 bytes = 80 pixels)
Pixels 80-92: File extension (8 chars = 8 bytes = 11 pixels)
Pixels 93-105: Total data length (8 bytes = 11 pixels)
Pixels 106-110: Total frames (2 bytes = 3 pixels)
Pixels 111-115: Current frame (2 bytes = 3 pixels)
Pixels 116-127: Reserved (12 pixels for future use)
Pixels 128-143: Checksum (16 bytes MD5 = 16 pixels minimum)
```

### Encoding Method

Each byte is distributed across multiple pixels:

```cpp
// Example: Store byte 0xAB (10101011)
// Split into pairs: 10, 10, 10, 11
// Store in pixel RGB:
// R channel LSB 2 bits: 10
// G channel LSB 2 bits: 10
// B channel LSB 2 bits: 10
// Next pixel R channel LSB 2 bits: 11
```

## Frame Management

### Multi-Frame Files

For files exceeding 1.86 MB:

1. **Split** data into chunks of max 1,862,000 bytes
2. **Generate** multiple 1000×1000 images
3. **Label** each with frame number (1/3, 2/3, 3/3)
4. **Embed** frame info in border header

### Frame Naming Convention

```
original_file.pdf → encoded_frame_1_of_3.png
                 → encoded_frame_2_of_3.png
                 → encoded_frame_3_of_3.png
```

## Detection Algorithm

### Simplified Detection

Since size is fixed, detection is trivial:

```cpp
bool detectEncodedImage(const QImage &largeImage, QPoint offset) {
    // Check if 1000×1000 region exists at offset
    if (offset.x() + 1000 > largeImage.width() ||
        offset.y() + 1000 > largeImage.height()) {
        return false;
    }
    
    // Extract 1000×1000 region
    QImage region = largeImage.copy(offset.x(), offset.y(), 1000, 1000);
    
    // Read magic bytes from top border
    QByteArray magic = readBorderHeader(region, 0, 4);
    return (magic == "STGV");
}
```

### Grid Scan for Multiple Images

```cpp
// Scan with 1000-pixel stride
for (int y = 0; y < height - 1000; y += 1000) {
    for (int x = 0; x < width - 1000; x += 1000) {
        if (detectEncodedImage(image, QPoint(x, y))) {
            // Found encoded image at (x, y)
        }
    }
}
```

## Benefits Over Variable Size Format

1. **Position Independent**: Always 1000×1000, easy to scan
2. **No Grid Search**: Fixed stride, predictable positions
3. **Visible Headers**: Metadata in border, not LSB-hidden
4. **Multi-Frame**: Support files > 2MB with pagination
5. **Faster Detection**: No need to scan LSB for headers
6. **Easier Compositing**: Standard size simplifies layout
7. **Visual Identification**: Can display frame info without decoding

## Capacity Calculation

```
Data area: 996 × 996 = 992,016 pixels
Bits per pixel: 6 (2 bits × 3 channels)
Total bits: 992,016 × 6 = 5,952,096 bits
Total bytes: 5,952,096 / 8 = 744,012 bytes
Minus header overhead: ~500 bytes
Effective capacity: ~743,500 bytes ≈ 726 KB per frame

With compression (typical 2.5x):
Effective capacity: ~1.86 MB per frame
```

## Implementation Phases

### Phase 1: Border Header Encoding/Decoding
- Implement `encodeBorderHeader()`
- Implement `readBorderHeader()`
- Unit tests for header serialization

### Phase 2: Fixed Size Encode/Decode
- Modify `encodeFileInImage()` to use 1000×1000
- Update LSB embedding for 996×996 data area
- Border header integration

### Phase 3: Frame Management
- Multi-frame splitting logic
- Frame metadata tracking
- Reassembly decoder

### Phase 4: Detection Update
- Simplified grid scan (1000px stride)
- Border header validation
- Multi-frame discovery

### Phase 5: Backward Compatibility
- Detect old vs new format
- Dual decoder support
- Migration tools

## API Changes

### Encode

```cpp
// Old: Variable size output
bool encodeFileInImage(imageUrl, fileUrl, outputUrl);

// New: Returns list of frame URLs for large files
QStringList encodeFileInFrames(fileUrl, outputDir, baseName);
// Returns: ["frame_1_of_3.png", "frame_2_of_3.png", "frame_3_of_3.png"]
```

### Decode

```cpp
// Old: Single image input
bool decodeFileFromImage(imageUrl, outputUrl);

// New: Accepts frame list or auto-discovers
bool decodeFileFromFrames(QStringList frameUrls, outputUrl);
// Also supports single frame for small files
```

### Extract

```cpp
// Old: Complex grid scan with variable sizes
QRect findEncodedRegion(largeImage);

// New: Simple fixed-size scan
QList<QRect> findAllEncodedRegions(largeImage);
// Returns: [QRect(0,0,1000,1000), QRect(1000,0,1000,1000), ...]
```

## File Format Comparison

| Feature | Old Format | New Format |
|---------|-----------|-----------|
| Size | Variable (calculated) | Fixed 1000×1000 |
| Header Location | LSB-encoded | Border pixels |
| Max Single File | ~1 MB | ~726 KB |
| Multi-File Support | No | Yes (frames) |
| Detection Speed | Slow (LSB scan) | Fast (fixed stride) |
| Position Independent | No | Yes |
| Visual Metadata | No | Yes (in border) |

## Migration Strategy

1. **Version Detection**: Check for "STGV" magic in border vs "STEG" in LSB
2. **Dual Support**: Keep old decoder for legacy images
3. **UI Toggle**: "Legacy Mode" checkbox for old format
4. **Conversion Tool**: Batch convert old → new format
5. **Deprecation**: Phase out old format in v3.0

## Testing Strategy

1. **Unit Tests**:
   - Border header encode/decode
   - Frame splitting logic
   - Detection algorithm

2. **Integration Tests**:
   - Single frame files (<726 KB)
   - Multi-frame files (>726 KB)
   - Edge cases (exactly 726 KB)

3. **E2E Tests**:
   - Encode → Extract → Decode multi-frame
   - Grid scan with multiple embedded images
   - Legacy format compatibility

## Future Enhancements

1. **Compression**: Add zlib compression before encoding (2-3× capacity)
2. **Error Correction**: Reed-Solomon codes in border
3. **Encryption**: AES encryption before LSB embedding
4. **Thumbnails**: Store preview in border area
5. **Metadata Tags**: Author, timestamp, description
