#ifndef BORDERHEADER_H
#define BORDERHEADER_H

#include <QObject>
#include <QImage>
#include <QByteArray>
#include <QString>

/**
 * BorderHeader - Manages header data encoded in 2-pixel border of 1000×1000 images
 * 
 * Format: Fixed 1000×1000 pixel images with 2-pixel border containing metadata
 * Border pixels encode header information using LSB technique (6 bits per pixel)
 */
class BorderHeader
{
public:
    // Header data structure
    struct Data {
        QString filename;        // Original filename (max 60 chars)
        QString extension;       // File extension (max 8 chars, e.g., ".pdf", ".txt")
        qint64 totalDataLength;  // Total bytes across all frames
        quint16 totalFrames;     // Number of frames (1 for small files)
        quint16 currentFrame;    // Current frame number (1-based)
        quint16 version;         // Format version (current: 1)
        QByteArray checksum;     // MD5 checksum (16 bytes)
        
        Data() : totalDataLength(0), totalFrames(1), currentFrame(1), version(1) {}
    };
    
    // Constants
    static constexpr int IMAGE_SIZE = 1000;        // Fixed image dimension
    static constexpr int BORDER_WIDTH = 2;         // Border width in pixels
    static constexpr int DATA_AREA_SIZE = 996;     // 1000 - 2*2
    static constexpr int BITS_PER_PIXEL = 6;       // 2 bits per RGB channel
    static constexpr int MAX_FILENAME_LENGTH = 60;
    static constexpr int MAX_EXTENSION_LENGTH = 8;
    static constexpr char MAGIC_BYTES[5] = "STGV"; // STeganaography Version (V=variable/visible)
    
    /**
     * Encode header data into the border of a 1000×1000 image
     * @param image The 1000×1000 image to encode header into
     * @param data The header data to encode
     * @return true if encoding succeeded
     */
    static bool encodeToBorder(QImage &image, const Data &data);
    
    /**
     * Read header data from the border of a 1000×1000 image
     * @param image The 1000×1000 image to read from
     * @return Parsed header data, or default Data if invalid
     */
    static Data readFromBorder(const QImage &image);
    
    /**
     * Check if image has valid border header (checks magic bytes)
     * @param image The image to check (should be 1000×1000)
     * @return true if valid header detected
     */
    static bool hasValidHeader(const QImage &image);
    
    /**
     * Calculate capacity for data area (996×996 pixels)
     * @return Maximum bytes that can be stored in data area
     */
    static qint64 calculateDataCapacity();
    
    /**
     * Create header data for a file
     * @param filename Original filename
     * @param extension File extension (with or without dot)
     * @param totalSize Total file size in bytes
     * @param frameNum Current frame number (1-based)
     * @param totalFrames Total number of frames
     * @param dataChecksum MD5 checksum of the file data
     * @return Initialized header data
     */
    static Data createHeader(const QString &filename,
                           const QString &extension,
                           qint64 totalSize,
                           quint16 frameNum = 1,
                           quint16 totalFrames = 1,
                           const QByteArray &dataChecksum = QByteArray());
    
    /**
     * Validate header data integrity
     * @param data Header data to validate
     * @return true if all fields are valid
     */
    static bool validate(const Data &data);
    
    /**
     * Serialize header data to byte array for encoding
     * @param data Header data to serialize
     * @return Byte array ready for border encoding
     */
    static QByteArray serialize(const Data &data);
    
    /**
     * Deserialize byte array to header data
     * @param bytes Raw bytes read from border
     * @return Parsed header data
     */
    static Data deserialize(const QByteArray &bytes);

private:
    /**
     * Encode bytes into top border pixels (2 rows × 1000 pixels)
     * Uses 2 LSBs per channel, 6 bits per pixel
     * @param image Image to encode into
     * @param data Bytes to encode
     * @param startPixel Starting pixel index in border
     */
    static void encodeBytesToBorder(QImage &image, const QByteArray &data, int startPixel);
    
    /**
     * Read bytes from top border pixels
     * @param image Image to read from
     * @param startPixel Starting pixel index in border
     * @param numBytes Number of bytes to read
     * @return Extracted bytes
     */
    static QByteArray readBytesFromBorder(const QImage &image, int startPixel, int numBytes);
    
    /**
     * Extract 2 LSBs from a color channel
     */
    static quint8 extractLSBs(quint8 value);
    
    /**
     * Embed 2 bits into a color channel's LSBs
     */
    static quint8 embedLSBs(quint8 original, quint8 bits);
};

#endif // BORDERHEADER_H
