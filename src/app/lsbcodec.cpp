#include "lsbcodec.h"
#include <QDebug>

LSBCodec::LSBCodec()
{
}

bool LSBCodec::embedData(QImage &image, const QByteArray &data)
{
    int width = image.width();
    int height = image.height();
    int totalPixels = width * height;
    
    // Calculate required capacity
    int requiredBits = data.size() * 8;
    int availableBits = totalPixels * BITS_PER_PIXEL * BITS_PER_CHANNEL;
    
    if (requiredBits > availableBits) {
        qDebug() << "Data too large:" << requiredBits << "bits needed," << availableBits << "bits available";
        return false;
    }
    
    int byteIndex = 0;
    int bitIndex = 0;
    
    // Embed data bit by bit
    for (int y = 0; y < height && byteIndex < data.size(); ++y) {
        for (int x = 0; x < width && byteIndex < data.size(); ++x) {
            QRgb pixel = image.pixel(x, y);
            int r = qRed(pixel);
            int g = qGreen(pixel);
            int b = qBlue(pixel);
            
            // Embed bits into each channel
            for (int channel = 0; channel < 3 && byteIndex < data.size(); ++channel) {
                for (int bit = 0; bit < BITS_PER_CHANNEL && byteIndex < data.size(); ++bit) {
                    uchar dataByte = static_cast<uchar>(data[byteIndex]);
                    int dataBit = (dataByte >> bitIndex) & 1;
                    
                    // Clear the target bit and set it to our data bit
                    switch (channel) {
                    case 0: // Red
                        r = (r & ~(1 << bit)) | (dataBit << bit);
                        break;
                    case 1: // Green
                        g = (g & ~(1 << bit)) | (dataBit << bit);
                        break;
                    case 2: // Blue
                        b = (b & ~(1 << bit)) | (dataBit << bit);
                        break;
                    }
                    
                    bitIndex++;
                    if (bitIndex >= 8) {
                        bitIndex = 0;
                        byteIndex++;
                    }
                }
            }
            
            image.setPixel(x, y, qRgb(r, g, b));
        }
    }
    
    qDebug() << "Embedded" << data.size() << "bytes in" << width << "x" << height << "image";
    return true;
}

QByteArray LSBCodec::extractData(const QImage &image)
{
    int width = image.width();
    int height = image.height();
    int totalPixels = width * height;
    
    // Calculate total capacity to avoid reading beyond available data
    int maxBytes = (totalPixels * BITS_PER_PIXEL * BITS_PER_CHANNEL) / 8;
    
    QByteArray allData;
    allData.reserve(maxBytes);
    
    int byteIndex = 0;
    int bitIndex = 0;
    uchar byte = 0;
    
    // Extract all data in one pass
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            QRgb pixel = image.pixel(x, y);
            int r = qRed(pixel);
            int g = qGreen(pixel);
            int b = qBlue(pixel);
            
            // Extract bits from each channel
            for (int channel = 0; channel < 3; ++channel) {
                for (int bit = 0; bit < BITS_PER_CHANNEL; ++bit) {
                    int value = 0;
                    switch (channel) {
                    case 0: value = (r >> bit) & 1; break;
                    case 1: value = (g >> bit) & 1; break;
                    case 2: value = (b >> bit) & 1; break;
                    }
                    
                    byte |= (value << bitIndex);
                    bitIndex++;
                    
                    if (bitIndex >= 8) {
                        allData.append(static_cast<char>(byte));
                        byte = 0;
                        bitIndex = 0;
                        byteIndex++;
                        
                        // Stop if we've read enough based on header
                        if (byteIndex >= maxBytes) {
                            return allData;
                        }
                    }
                }
            }
        }
    }
    
    // Append any remaining partial byte
    if (bitIndex > 0) {
        allData.append(static_cast<char>(byte));
    }
    
    return allData;
}

qint64 LSBCodec::calculateCapacity(int imageSize)
{
    // capacity = (pixels * 3 channels * 2 bits) / 8 bits per byte - header overhead
    qint64 capacity = (imageSize * BITS_PER_PIXEL * BITS_PER_CHANNEL) / 8;
    capacity -= 256; // Header overhead
    return capacity;
}
