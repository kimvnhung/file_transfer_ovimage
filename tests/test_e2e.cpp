#include <QCoreApplication>
#include <QImage>
#include <QFile>
#include <QDebug>
#include "steganography.h"

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);
    
    qDebug() << "=== Steganography End-to-End Test ===\n";
    
    // Step 1: Create a carrier image
    qDebug() << "Step 1: Creating carrier image...";
    QImage carrierImage(800, 600, QImage::Format_RGB888);
    for (int y = 0; y < 600; ++y) {
        for (int x = 0; x < 800; ++x) {
            int r = (x * 255) / 800;
            int g = (y * 255) / 600;
            int b = 128;
            carrierImage.setPixel(x, y, qRgb(r, g, b));
        }
    }
    QString carrierPath = "/tmp/test_carrier.png";
    if (!carrierImage.save(carrierPath, "PNG")) {
        qCritical() << "Failed to save carrier image!";
        return 1;
    }
    qDebug() << "✓ Carrier image created:" << carrierPath;
    qDebug() << "  Size:" << carrierImage.width() << "x" << carrierImage.height();
    
    // Step 2: Create a secret text file
    qDebug() << "\nStep 2: Creating secret text file...";
    QString secretPath = "/tmp/test_secret.txt";
    QFile secretFile(secretPath);
    if (!secretFile.open(QIODevice::WriteOnly)) {
        qCritical() << "Failed to create secret file!";
        return 1;
    }
    QByteArray secretData = "Hello, this is a secret message for testing steganography!";
    secretFile.write(secretData);
    secretFile.close();
    qDebug() << "✓ Secret file created:" << secretPath;
    qDebug() << "  Content:" << secretData;
    qDebug() << "  Size:" << secretData.size() << "bytes";
    
    // Step 3: Calculate capacity
    qDebug() << "\nStep 3: Calculating image capacity...";
    Steganography stego;
    qint64 capacity = stego.calculateCapacity(carrierPath);
    qDebug() << "✓ Image capacity:" << capacity << "bytes";
    qDebug() << "  Required:" << secretData.size() << "bytes";
    
    if (secretData.size() > capacity) {
        qCritical() << "✗ File too large for this image!";
        return 1;
    }
    qDebug() << "  ✓ Sufficient capacity";
    
    // Step 4: Encode the secret file into the image
    qDebug() << "\nStep 4: Encoding secret file into image...";
    QString encodedPath = "/tmp/test_encoded.png";
    
    bool encodeResult = stego.encodeFileInImage(carrierPath, secretPath, encodedPath);
    
    if (!encodeResult) {
        qCritical() << "✗ Encoding failed:" << stego.lastError();
        return 1;
    }
    qDebug() << "✓ Encoding successful!";
    qDebug() << "  Output:" << encodedPath;
    qDebug() << "  Progress:" << stego.progress() << "%";
    
    // Verify encoded file exists
    if (!QFile::exists(encodedPath)) {
        qCritical() << "✗ Encoded file not found!";
        return 1;
    }
    
    QImage encodedImage(encodedPath);
    qDebug() << "  Encoded image size:" << encodedImage.width() << "x" << encodedImage.height();
    
    // Step 5: Check if the image has hidden data
    qDebug() << "\nStep 5: Detecting hidden data...";
    bool hasData = stego.hasHiddenData(encodedPath);
    qDebug() << "  Has hidden data:" << (hasData ? "YES" : "NO");
    
    if (hasData) {
        QString fileInfo = stego.getHiddenFileInfo(encodedPath);
        qDebug() << "  File info:" << fileInfo;
    }
    
    // Step 6: Decode the secret file from the image
    qDebug() << "\nStep 6: Decoding secret file from image...";
    QString decodedPath = "/tmp/test_decoded.txt";
    
    bool decodeResult = stego.decodeFileFromImage(encodedPath, decodedPath);
    
    if (!decodeResult) {
        qCritical() << "✗ Decoding failed:" << stego.lastError();
        return 1;
    }
    qDebug() << "✓ Decoding successful!";
    qDebug() << "  Output:" << decodedPath;
    qDebug() << "  Progress:" << stego.progress() << "%";
    
    // Step 7: Verify the decoded content matches original
    qDebug() << "\nStep 7: Verifying decoded content...";
    QFile decodedFile(decodedPath);
    if (!decodedFile.open(QIODevice::ReadOnly)) {
        qCritical() << "✗ Failed to open decoded file!";
        return 1;
    }
    
    QByteArray decodedData = decodedFile.readAll();
    decodedFile.close();
    
    qDebug() << "  Original content:" << secretData;
    qDebug() << "  Decoded content: " << decodedData;
    qDebug() << "  Original size:" << secretData.size() << "bytes";
    qDebug() << "  Decoded size: " << decodedData.size() << "bytes";
    
    if (secretData == decodedData) {
        qDebug() << "\n✓✓✓ SUCCESS! Content matches perfectly! ✓✓✓";
        return 0;
    } else {
        qCritical() << "\n✗✗✗ FAILURE! Content mismatch! ✗✗✗";
        
        // Show hex comparison
        qDebug() << "\nHex comparison:";
        qDebug() << "  Original:" << secretData.toHex();
        qDebug() << "  Decoded: " << decodedData.toHex();
        
        // Show byte-by-byte comparison for first 20 bytes
        int compareLen = qMin(secretData.size(), decodedData.size());
        compareLen = qMin(compareLen, 20);
        qDebug() << "\nByte-by-byte comparison (first" << compareLen << "bytes):";
        for (int i = 0; i < compareLen; ++i) {
            unsigned char orig = secretData[i];
            unsigned char dec = decodedData[i];
            QString match = (orig == dec) ? "✓" : "✗";
            qDebug() << QString("  Byte %1: 0x%2 vs 0x%3 %4")
                        .arg(i, 2)
                        .arg(orig, 2, 16, QChar('0'))
                        .arg(dec, 2, 16, QChar('0'))
                        .arg(match);
        }
        
        return 1;
    }
}
