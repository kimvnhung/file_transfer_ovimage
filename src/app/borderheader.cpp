#include "borderheader.h"
#include <QCryptographicHash>
#include <QDataStream>
#include <QIODevice>
#include <QDebug>
#include <cstring>

// Initialize static constexpr with const for string literals
const char BorderHeader::MAGIC_BYTES[5];

BorderHeader::Data BorderHeader::createHeader(const QString &filename,
                                              const QString &extension,
                                              qint64 totalSize,
                                              quint16 frameNum,
                                              quint16 totalFrames,
                                              const QByteArray &dataChecksum)
{
    Data header;
    
    // Truncate filename if too long
    header.filename = filename.left(MAX_FILENAME_LENGTH);
    
    // Normalize extension (ensure dot prefix, max length)
    QString ext = extension;
    if (!ext.startsWith('.')) {
        ext = "." + ext;
    }
    header.extension = ext.left(MAX_EXTENSION_LENGTH);
    
    header.totalDataLength = totalSize;
    header.currentFrame = frameNum;
    header.totalFrames = totalFrames;
    header.version = 1;
    header.checksum = dataChecksum;
    
    return header;
}

qint64 BorderHeader::calculateDataCapacity()
{
    // Data area is 996×996 pixels
    qint64 pixels = DATA_AREA_SIZE * DATA_AREA_SIZE;
    qint64 bits = pixels * BITS_PER_PIXEL;  // 6 bits per pixel
    return bits / 8;  // Convert to bytes: ~744,012 bytes
}

QByteArray BorderHeader::serialize(const Data &data)
{
    QByteArray buffer;
    QDataStream stream(&buffer, QIODevice::WriteOnly);
    stream.setVersion(QDataStream::Qt_6_0);
    
    // Magic bytes (4 bytes)
    stream.writeRawData(MAGIC_BYTES, 4);
    
    // Version (2 bytes)
    stream << data.version;
    
    // Filename length (1 byte) + filename
    quint8 nameLen = static_cast<quint8>(data.filename.length());
    stream << nameLen;
    stream.writeRawData(data.filename.toUtf8().constData(), nameLen);
    
    // Extension length (1 byte) + extension
    quint8 extLen = static_cast<quint8>(data.extension.length());
    stream << extLen;
    stream.writeRawData(data.extension.toUtf8().constData(), extLen);
    
    // Total data length (8 bytes)
    stream << data.totalDataLength;
    
    // Frame info (2 + 2 = 4 bytes)
    stream << data.totalFrames;
    stream << data.currentFrame;
    
    // Checksum (16 bytes for MD5)
    QByteArray checksumData = data.checksum;
    if (checksumData.size() != 16) {
        // Pad or truncate to 16 bytes
        checksumData.resize(16);
    }
    stream.writeRawData(checksumData.constData(), 16);
    
    qDebug() << "BorderHeader: Serialized" << buffer.size() << "bytes";
    qDebug() << "  Filename:" << data.filename << "(" << nameLen << "bytes)";
    qDebug() << "  Extension:" << data.extension << "(" << extLen << "bytes)";
    qDebug() << "  Total size:" << data.totalDataLength;
    qDebug() << "  Frame:" << data.currentFrame << "/" << data.totalFrames;
    
    return buffer;
}

BorderHeader::Data BorderHeader::deserialize(const QByteArray &bytes)
{
    Data data;
    
    if (bytes.size() < 4) {
        qWarning() << "BorderHeader: Buffer too small for magic bytes";
        return data;
    }
    
    QDataStream stream(bytes);
    stream.setVersion(QDataStream::Qt_6_0);
    
    // Read and verify magic bytes
    char magic[5] = {0};
    stream.readRawData(magic, 4);
    if (std::memcmp(magic, MAGIC_BYTES, 4) != 0) {
        qWarning() << "BorderHeader: Invalid magic bytes:" << QByteArray(magic, 4).toHex();
        return data;
    }
    
    // Version
    stream >> data.version;
    
    // Filename
    quint8 nameLen;
    stream >> nameLen;
    if (nameLen > MAX_FILENAME_LENGTH) {
        qWarning() << "BorderHeader: Filename length exceeds maximum:" << nameLen;
        return data;
    }
    char nameBuffer[MAX_FILENAME_LENGTH + 1] = {0};
    stream.readRawData(nameBuffer, nameLen);
    data.filename = QString::fromUtf8(nameBuffer, nameLen);
    
    // Extension
    quint8 extLen;
    stream >> extLen;
    if (extLen > MAX_EXTENSION_LENGTH) {
        qWarning() << "BorderHeader: Extension length exceeds maximum:" << extLen;
        return data;
    }
    char extBuffer[MAX_EXTENSION_LENGTH + 1] = {0};
    stream.readRawData(extBuffer, extLen);
    data.extension = QString::fromUtf8(extBuffer, extLen);
    
    // Total data length
    stream >> data.totalDataLength;
    
    // Frame info
    stream >> data.totalFrames;
    stream >> data.currentFrame;
    
    // Checksum
    char checksumBuffer[16];
    stream.readRawData(checksumBuffer, 16);
    data.checksum = QByteArray(checksumBuffer, 16);
    
    qDebug() << "BorderHeader: Deserialized header:";
    qDebug() << "  Filename:" << data.filename;
    qDebug() << "  Extension:" << data.extension;
    qDebug() << "  Total size:" << data.totalDataLength;
    qDebug() << "  Frame:" << data.currentFrame << "/" << data.totalFrames;
    
    return data;
}

bool BorderHeader::validate(const Data &data)
{
    if (data.filename.isEmpty()) {
        qWarning() << "BorderHeader: Empty filename";
        return false;
    }
    
    if (data.filename.length() > MAX_FILENAME_LENGTH) {
        qWarning() << "BorderHeader: Filename too long:" << data.filename.length();
        return false;
    }
    
    if (data.extension.length() > MAX_EXTENSION_LENGTH) {
        qWarning() << "BorderHeader: Extension too long:" << data.extension.length();
        return false;
    }
    
    if (data.totalDataLength <= 0) {
        qWarning() << "BorderHeader: Invalid total data length:" << data.totalDataLength;
        return false;
    }
    
    if (data.totalFrames == 0) {
        qWarning() << "BorderHeader: Total frames cannot be zero";
        return false;
    }
    
    if (data.currentFrame == 0 || data.currentFrame > data.totalFrames) {
        qWarning() << "BorderHeader: Invalid frame number:" << data.currentFrame << "/" << data.totalFrames;
        return false;
    }
    
    return true;
}

quint8 BorderHeader::extractLSBs(quint8 value)
{
    return value & 0b00000011;  // Extract 2 least significant bits
}

quint8 BorderHeader::embedLSBs(quint8 original, quint8 bits)
{
    // Clear 2 LSBs, then set them to new bits
    return (original & 0b11111100) | (bits & 0b00000011);
}

void BorderHeader::encodeBytesToBorder(QImage &image, const QByteArray &data, int startPixel)
{
    if (image.width() != IMAGE_SIZE || image.height() != IMAGE_SIZE) {
        qWarning() << "BorderHeader: Image must be 1000×1000, got" << image.width() << "×" << image.height();
        return;
    }
    
    int pixelIndex = startPixel;
    int bitIndex = 0;
    
    for (int byteIdx = 0; byteIdx < data.size(); ++byteIdx) {
        quint8 byte = static_cast<quint8>(data[byteIdx]);
        
        // Encode byte as 4 pairs of bits (8 bits total)
        // Each pixel can hold 6 bits (2 per channel), so 8 bits = 2 pixels (with 4 bits leftover)
        // Actually: 8 bits / 6 bits per pixel = 1.33 pixels needed
        
        // We'll encode each byte across ceil(8/6) = 2 pixels
        for (int bit = 0; bit < 8; bit += 2) {
            if (pixelIndex >= IMAGE_SIZE * BORDER_WIDTH) {
                qWarning() << "BorderHeader: Exceeded border capacity";
                return;
            }
            
            // Calculate position in top border (2 rows)
            int x = pixelIndex % IMAGE_SIZE;
            int y = pixelIndex / IMAGE_SIZE;
            
            QRgb pixel = image.pixel(x, y);
            quint8 r = qRed(pixel);
            quint8 g = qGreen(pixel);
            quint8 b = qBlue(pixel);
            
            // Extract 2 bits at current position
            quint8 bits = (byte >> (6 - bit)) & 0b00000011;
            
            // Embed into RGB channels based on which pair we're encoding
            switch (bitIndex % 3) {
                case 0: r = embedLSBs(r, bits); break;
                case 1: g = embedLSBs(g, bits); break;
                case 2: b = embedLSBs(b, bits); break;
            }
            
            image.setPixel(x, y, qRgb(r, g, b));
            
            bitIndex++;
            if (bitIndex % 3 == 0) {
                pixelIndex++;  // Move to next pixel after using all 3 channels
            }
        }
    }
    
    qDebug() << "BorderHeader: Encoded" << data.size() << "bytes into border using" 
             << pixelIndex - startPixel << "pixels";
}

QByteArray BorderHeader::readBytesFromBorder(const QImage &image, int startPixel, int numBytes)
{
    if (image.width() != IMAGE_SIZE || image.height() != IMAGE_SIZE) {
        qWarning() << "BorderHeader: Image must be 1000×1000";
        return QByteArray();
    }
    
    QByteArray result;
    result.reserve(numBytes);
    
    int pixelIndex = startPixel;
    int bitIndex = 0;
    quint8 currentByte = 0;
    int bitsInCurrentByte = 0;
    
    for (int byteIdx = 0; byteIdx < numBytes; ++byteIdx) {
        currentByte = 0;
        bitsInCurrentByte = 0;
        
        while (bitsInCurrentByte < 8) {
            if (pixelIndex >= IMAGE_SIZE * BORDER_WIDTH) {
                qWarning() << "BorderHeader: Exceeded border while reading";
                return result;
            }
            
            int x = pixelIndex % IMAGE_SIZE;
            int y = pixelIndex / IMAGE_SIZE;
            
            QRgb pixel = image.pixel(x, y);
            quint8 value;
            
            switch (bitIndex % 3) {
                case 0: value = qRed(pixel); break;
                case 1: value = qGreen(pixel); break;
                case 2: value = qBlue(pixel); break;
            }
            
            quint8 bits = extractLSBs(value);
            currentByte = (currentByte << 2) | bits;
            bitsInCurrentByte += 2;
            
            bitIndex++;
            if (bitIndex % 3 == 0) {
                pixelIndex++;
            }
        }
        
        result.append(static_cast<char>(currentByte));
    }
    
    return result;
}

bool BorderHeader::encodeToBorder(QImage &image, const Data &data)
{
    if (!validate(data)) {
        qWarning() << "BorderHeader: Invalid header data";
        return false;
    }
    
    if (image.width() != IMAGE_SIZE || image.height() != IMAGE_SIZE) {
        qWarning() << "BorderHeader: Image must be exactly 1000×1000 pixels";
        return false;
    }
    
    // Serialize header to bytes
    QByteArray headerBytes = serialize(data);
    
    // Check if it fits in border (2000 pixels × 6 bits/pixel = 1500 bytes max)
    int maxBorderBytes = (IMAGE_SIZE * BORDER_WIDTH * BITS_PER_PIXEL) / 8;
    if (headerBytes.size() > maxBorderBytes) {
        qWarning() << "BorderHeader: Header too large:" << headerBytes.size() << "bytes (max:" << maxBorderBytes << ")";
        return false;
    }
    
    // Encode into top border starting at pixel 0
    encodeBytesToBorder(image, headerBytes, 0);
    
    qDebug() << "BorderHeader: Successfully encoded header to border";
    return true;
}

BorderHeader::Data BorderHeader::readFromBorder(const QImage &image)
{
    Data data;
    
    if (image.width() != IMAGE_SIZE || image.height() != IMAGE_SIZE) {
        qWarning() << "BorderHeader: Image must be 1000×1000";
        return data;
    }
    
    // First, read magic bytes (4 bytes = 7 pixels with 6 bits/pixel encoding)
    QByteArray magic = readBytesFromBorder(image, 0, 4);
    if (magic != MAGIC_BYTES) {
        qWarning() << "BorderHeader: No valid header found (bad magic)";
        return data;
    }
    
    // Read full header (estimate ~150 bytes to be safe)
    QByteArray headerBytes = readBytesFromBorder(image, 0, 150);
    
    // Deserialize
    data = deserialize(headerBytes);
    
    return data;
}

bool BorderHeader::hasValidHeader(const QImage &image)
{
    if (image.width() != IMAGE_SIZE || image.height() != IMAGE_SIZE) {
        return false;
    }
    
    // Quick check: read magic bytes only
    QByteArray magic = readBytesFromBorder(image, 0, 4);
    return (magic == MAGIC_BYTES);
}
