#include <QCoreApplication>
#include <QImage>
#include <QFile>
#include <QDebug>
#include <QTemporaryDir>
#include <QDataStream>

/**
 * Debug program to test LSB encoding/decoding logic
 */

void testLSBLogic() {
    qDebug() << "\n=== Testing LSB Encode/Decode Logic ===\n";
    
    // Test data
    QByteArray testData;
    testData.append(char(0xAB)); // 10101011
    testData.append(char(0xCD)); // 11001101
    testData.append(char(0xEF)); // 11101111
    
    qDebug() << "Original data (hex):" << testData.toHex();
    
    // Create test image
    QImage image(10, 10, QImage::Format_RGB888);
    image.fill(qRgb(128, 128, 128));
    
    // Add size header
    qint64 dataSize = testData.size();
    QByteArray sizeData;
    QDataStream sizeStream(&sizeData, QIODevice::WriteOnly);
    sizeStream << dataSize;
    
    qDebug() << "Size header (hex):" << sizeData.toHex();
    qDebug() << "Size value:" << dataSize;
    
    QByteArray fullData = sizeData + testData;
    qDebug() << "Full data size:" << fullData.size() << "bytes";
    qDebug() << "Full data (hex):" << fullData.toHex();
    
    // ENCODE
    int dataIndex = 0;
    int bitIndex = 0;
    const int BITS_PER_CHANNEL = 2;
    
    for (int y = 0; y < image.height() && dataIndex < fullData.size(); ++y) {
        for (int x = 0; x < image.width() && dataIndex < fullData.size(); ++x) {
            QRgb pixel = image.pixel(x, y);
            int r = qRed(pixel);
            int g = qGreen(pixel);
            int b = qBlue(pixel);
            
            for (int channel = 0; channel < 3 && dataIndex < fullData.size(); ++channel) {
                for (int bit = 0; bit < BITS_PER_CHANNEL && dataIndex < fullData.size(); ++bit) {
                    int dataBit = (fullData[dataIndex] >> bitIndex) & 1;
                    
                    switch (channel) {
                    case 0: r = (r & ~(1 << bit)) | (dataBit << bit); break;
                    case 1: g = (g & ~(1 << bit)) | (dataBit << bit); break;
                    case 2: b = (b & ~(1 << bit)) | (dataBit << bit); break;
                    }
                    
                    bitIndex++;
                    if (bitIndex >= 8) {
                        bitIndex = 0;
                        dataIndex++;
                        if (dataIndex >= fullData.size()) break;
                    }
                }
            }
            
            image.setPixel(x, y, qRgb(r, g, b));
        }
    }
    
    qDebug() << "\n--- Encoding complete ---";
    qDebug() << "Encoded" << dataIndex << "bytes into" << ((dataIndex * 8 + 5) / 6) << "pixels";
    qDebug() << "First 10 pixels (RGB):";
    for (int i = 0; i < 10; ++i) {
        QRgb p = image.pixel(i % image.width(), i / image.width());
        qDebug() << QString("Pixel %1: R=%2 G=%3 B=%4 (binary: %5 %6 %7)")
                    .arg(i)
                    .arg(qRed(p))
                    .arg(qGreen(p))
                    .arg(qBlue(p))
                    .arg(qRed(p), 8, 2, QChar('0'))
                    .arg(qGreen(p), 8, 2, QChar('0'))
                    .arg(qBlue(p), 8, 2, QChar('0'));
    }
    
    // DECODE
    qDebug() << "\n--- Starting decode ---";
    
    // Extract size (8 bytes)
    QByteArray extractedSize;
    dataIndex = 0;
    bitIndex = 0;
    uchar byte = 0;  // Declare outside while loop
    
    qDebug() << "Extracting 8 bytes for size header...";
    
    while (extractedSize.size() < 8) {
        int x = dataIndex % image.width();
        int y = dataIndex / image.width();
        
        qDebug() << QString("  Processing pixel %1 (x=%2, y=%3)").arg(dataIndex).arg(x).arg(y);
        
        QRgb pixel = image.pixel(x, y);
        int r = qRed(pixel);
        int g = qGreen(pixel);
        int b = qBlue(pixel);
        
        qDebug() << QString("    Pixel RGB: %1 %2 %3 (binary: %4 %5 %6)")
                    .arg(r).arg(g).arg(b)
                    .arg(r, 8, 2, QChar('0'))
                    .arg(g, 8, 2, QChar('0'))
                    .arg(b, 8, 2, QChar('0'));
        
        int bitsExtracted = 0;
        for (int channel = 0; channel < 3 && extractedSize.size() < 8; ++channel) {
            for (int bit = 0; bit < BITS_PER_CHANNEL && extractedSize.size() < 8; ++bit) {
                int value = 0;
                switch (channel) {
                case 0: value = (r >> bit) & 1; break;
                case 1: value = (g >> bit) & 1; break;
                case 2: value = (b >> bit) & 1; break;
                }
                
                qDebug() << QString("      Channel %1, bit %2: value=%3, storing at bitIndex=%4")
                            .arg(channel).arg(bit).arg(value).arg(bitIndex);
                
                byte |= (value << bitIndex);
                qDebug() << QString("        byte is now: 0x%1 (binary: %2)")
                            .arg(byte, 2, 16, QChar('0'))
                            .arg(byte, 8, 2, QChar('0'));
                
                bitIndex++;
                bitsExtracted++;
                
                if (bitIndex >= 8) {
                    extractedSize.append(byte);
                    qDebug() << QString("    Extracted byte #%1: 0x%2 (bitIndex was %3, extracted %4 bits from this pixel so far)")
                                .arg(extractedSize.size())
                                .arg((unsigned char)byte, 2, 16, QChar('0'))
                                .arg(bitIndex)
                                .arg(bitsExtracted);
                    byte = 0;
                    bitIndex = 0;
                }
            }
        }
        qDebug() << QString("    Extracted %1 bits from this pixel, bitIndex now=%2").arg(bitsExtracted).arg(bitIndex);
        dataIndex++;
    }
    
    qDebug() << "\nExtracted size header (hex):" << extractedSize.toHex();
    
    QDataStream sizeDecodeStream(extractedSize);
    qint64 extractedDataSize;
    sizeDecodeStream >> extractedDataSize;
    qDebug() << "Decoded size value:" << extractedDataSize;
    
    // Extract actual data
    QByteArray extractedData;
    bitIndex = 0;
    byte = 0;  // Reset for data extraction (already declared)
    
    while (extractedData.size() < extractedDataSize) {
        int x = dataIndex % image.width();
        int y = dataIndex / image.width();
        
        QRgb pixel = image.pixel(x, y);
        int r = qRed(pixel);
        int g = qGreen(pixel);
        int b = qBlue(pixel);
        
        for (int channel = 0; channel < 3 && extractedData.size() < extractedDataSize; ++channel) {
            for (int bit = 0; bit < BITS_PER_CHANNEL && extractedData.size() < extractedDataSize; ++bit) {
                int value = 0;
                switch (channel) {
                case 0: value = (r >> bit) & 1; break;
                case 1: value = (g >> bit) & 1; break;
                case 2: value = (b >> bit) & 1; break;
                }
                
                byte |= (value << bitIndex);
                bitIndex++;
                
                if (bitIndex >= 8) {
                    extractedData.append(byte);
                    byte = 0;
                    bitIndex = 0;
                }
            }
        }
        dataIndex++;
    }
    
    qDebug() << "\nExtracted data (hex):" << extractedData.toHex();
    qDebug() << "Expected data (hex): " << testData.toHex();
    
    if (extractedData == testData) {
        qDebug() << "\n✓ SUCCESS: Extracted data matches original!";
    } else {
        qDebug() << "\n✗ FAILURE: Data mismatch!";
        qDebug() << "Expected:" << testData.size() << "bytes";
        qDebug() << "Got:     " << extractedData.size() << "bytes";
    }
}

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);
    
    testLSBLogic();
    
    return 0;
}
