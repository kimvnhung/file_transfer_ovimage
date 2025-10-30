#include <QCoreApplication>
#include <QImage>
#include <QFile>
#include <QDebug>
#include <QTemporaryDir>
#include "steganography.h"

/**
 * Simple standalone test program for steganography
 * Can be built without Google Test dependency
 */

class SimpleTest {
public:
    static int passed;
    static int failed;
    
    static void assert_true(bool condition, const QString& message) {
        if (condition) {
            qDebug() << "[PASS]" << message;
            passed++;
        } else {
            qWarning() << "[FAIL]" << message;
            failed++;
        }
    }
    
    static void assert_equal(int actual, int expected, const QString& message) {
        if (actual == expected) {
            qDebug() << "[PASS]" << message << "(" << actual << "==" << expected << ")";
            passed++;
        } else {
            qWarning() << "[FAIL]" << message << "(" << actual << "!=" << expected << ")";
            failed++;
        }
    }
};

int SimpleTest::passed = 0;
int SimpleTest::failed = 0;

// Helper to create test image
QImage createTestImage(int width, int height) {
    QImage image(width, height, QImage::Format_RGB888);
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            int r = (x * 255) / width;
            int g = (y * 255) / height;
            int b = ((x + y) * 255) / (width + height);
            image.setPixel(x, y, qRgb(r, g, b));
        }
    }
    return image;
}

// Test 1: Capacity Calculation
void test_capacity_calculation() {
    qDebug() << "\n=== Test 1: Capacity Calculation ===";
    
    Steganography stego;
    QTemporaryDir tempDir;
    
    QImage image = createTestImage(100, 100);
    QString imagePath = tempDir.filePath("test.png");
    image.save(imagePath, "PNG");
    
    qint64 capacity = stego.calculateCapacity(imagePath);
    
    // Expected: (100 * 100 * 3 * 2) / 8 - 256 = 7244
    SimpleTest::assert_equal(capacity, 7244, "Capacity for 100x100 image");
}

// Test 2: Encode and Decode Small Text
void test_encode_decode_text() {
    qDebug() << "\n=== Test 2: Encode/Decode Text ===";
    
    Steganography stego;
    QTemporaryDir tempDir;
    
    // Create carrier image
    QImage carrier = createTestImage(200, 200);
    QString carrierPath = tempDir.filePath("carrier.png");
    carrier.save(carrierPath, "PNG");
    
    // Create secret file
    QString secretPath = tempDir.filePath("secret.txt");
    QFile secretFile(secretPath);
    secretFile.open(QIODevice::WriteOnly);
    QByteArray originalData = "Hello, Steganography! This is a secret message.";
    secretFile.write(originalData);
    secretFile.close();
    
    // Encode
    QString outputPath = tempDir.filePath("output.png");
    bool encodeResult = stego.encodeFileInImage(carrierPath, secretPath, outputPath);
    SimpleTest::assert_true(encodeResult, "Encode text file");
    SimpleTest::assert_true(QFile::exists(outputPath), "Output file created");
    
    // Decode
    QString decodedPath = tempDir.filePath("decoded.txt");
    bool decodeResult = stego.decodeFileFromImage(outputPath, decodedPath);
    SimpleTest::assert_true(decodeResult, "Decode text file");
    
    // Verify content
    QFile decodedFile(decodedPath);
    decodedFile.open(QIODevice::ReadOnly);
    QByteArray decodedData = decodedFile.readAll();
    
    SimpleTest::assert_true(originalData == decodedData, "Decoded data matches original");
    qDebug() << "Original:" << originalData;
    qDebug() << "Decoded: " << decodedData;
}

// Test 3: Encode and Decode Binary Data
void test_encode_decode_binary() {
    qDebug() << "\n=== Test 3: Encode/Decode Binary Data ===";
    
    Steganography stego;
    QTemporaryDir tempDir;
    
    // Create carrier image
    QImage carrier = createTestImage(300, 300);
    QString carrierPath = tempDir.filePath("carrier.png");
    carrier.save(carrierPath, "PNG");
    
    // Create binary data
    QByteArray binaryData;
    for (int i = 0; i < 1024; ++i) {
        binaryData.append(static_cast<char>(i % 256));
    }
    
    QString secretPath = tempDir.filePath("secret.bin");
    QFile secretFile(secretPath);
    secretFile.open(QIODevice::WriteOnly);
    secretFile.write(binaryData);
    secretFile.close();
    
    // Encode
    QString outputPath = tempDir.filePath("output.png");
    bool encodeResult = stego.encodeFileInImage(carrierPath, secretPath, outputPath);
    SimpleTest::assert_true(encodeResult, "Encode binary file (1KB)");
    
    // Decode
    QString decodedPath = tempDir.filePath("decoded.bin");
    bool decodeResult = stego.decodeFileFromImage(outputPath, decodedPath);
    SimpleTest::assert_true(decodeResult, "Decode binary file");
    
    // Verify exact match
    QFile decodedFile(decodedPath);
    decodedFile.open(QIODevice::ReadOnly);
    QByteArray decodedData = decodedFile.readAll();
    
    SimpleTest::assert_equal(decodedData.size(), binaryData.size(), "Binary data size matches");
    SimpleTest::assert_true(binaryData == decodedData, "Binary data content matches");
}

// Test 4: File Too Large Error
void test_file_too_large() {
    qDebug() << "\n=== Test 4: File Too Large Error ===";
    
    Steganography stego;
    QTemporaryDir tempDir;
    
    // Create small carrier image
    QImage carrier = createTestImage(50, 50);
    QString carrierPath = tempDir.filePath("carrier.png");
    carrier.save(carrierPath, "PNG");
    
    qint64 capacity = stego.calculateCapacity(carrierPath);
    qDebug() << "Capacity:" << capacity << "bytes";
    
    // Create file larger than capacity
    QByteArray largeData;
    for (int i = 0; i < capacity + 1000; ++i) {
        largeData.append('X');
    }
    
    QString secretPath = tempDir.filePath("large.bin");
    QFile secretFile(secretPath);
    secretFile.open(QIODevice::WriteOnly);
    secretFile.write(largeData);
    secretFile.close();
    
    // Try to encode (should fail)
    QString outputPath = tempDir.filePath("output.png");
    bool encodeResult = stego.encodeFileInImage(carrierPath, secretPath, outputPath);
    SimpleTest::assert_true(!encodeResult, "Encode fails for oversized file");
    SimpleTest::assert_true(!stego.lastError().isEmpty(), "Error message set");
    qDebug() << "Error message:" << stego.lastError();
}

// Test 5: Hidden Data Detection
void test_hidden_data_detection() {
    qDebug() << "\n=== Test 5: Hidden Data Detection ===";
    
    Steganography stego;
    QTemporaryDir tempDir;
    
    // Create plain image
    QImage plain = createTestImage(200, 200);
    QString plainPath = tempDir.filePath("plain.png");
    plain.save(plainPath, "PNG");
    
    SimpleTest::assert_true(!stego.hasHiddenData(plainPath), "Plain image has no hidden data");
    
    // Create encoded image
    QString secretPath = tempDir.filePath("secret.txt");
    QFile secretFile(secretPath);
    secretFile.open(QIODevice::WriteOnly);
    secretFile.write("Secret data");
    secretFile.close();
    
    QString encodedPath = tempDir.filePath("encoded.png");
    stego.encodeFileInImage(plainPath, secretPath, encodedPath);
    
    SimpleTest::assert_true(stego.hasHiddenData(encodedPath), "Encoded image has hidden data");
    
    QString info = stego.getHiddenFileInfo(encodedPath);
    qDebug() << "Hidden file info:" << info;
    SimpleTest::assert_true(info.contains("secret.txt"), "File info contains filename");
}

// Test 6: Empty File Handling
void test_empty_file() {
    qDebug() << "\n=== Test 6: Empty File Handling ===";
    
    Steganography stego;
    QTemporaryDir tempDir;
    
    QImage carrier = createTestImage(200, 200);
    QString carrierPath = tempDir.filePath("carrier.png");
    carrier.save(carrierPath, "PNG");
    
    // Create empty file
    QString emptyPath = tempDir.filePath("empty.txt");
    QFile emptyFile(emptyPath);
    emptyFile.open(QIODevice::WriteOnly);
    emptyFile.close();
    
    QString outputPath = tempDir.filePath("output.png");
    bool encodeResult = stego.encodeFileInImage(carrierPath, emptyPath, outputPath);
    SimpleTest::assert_true(encodeResult, "Encode empty file succeeds");
    
    if (encodeResult) {
        QString decodedPath = tempDir.filePath("decoded.txt");
        bool decodeResult = stego.decodeFileFromImage(outputPath, decodedPath);
        SimpleTest::assert_true(decodeResult, "Decode empty file succeeds");
        
        QFile decodedFile(decodedPath);
        decodedFile.open(QIODevice::ReadOnly);
        QByteArray decodedData = decodedFile.readAll();
        SimpleTest::assert_equal(decodedData.size(), 0, "Decoded empty file is empty");
    }
}

// Test 7: Image Quality Preservation
void test_image_quality() {
    qDebug() << "\n=== Test 7: Image Quality Preservation ===";
    
    Steganography stego;
    QTemporaryDir tempDir;
    
    QImage original = createTestImage(400, 400);
    QString carrierPath = tempDir.filePath("carrier.png");
    original.save(carrierPath, "PNG");
    
    // Create small secret file
    QString secretPath = tempDir.filePath("secret.txt");
    QFile secretFile(secretPath);
    secretFile.open(QIODevice::WriteOnly);
    secretFile.write("Small secret");
    secretFile.close();
    
    QString outputPath = tempDir.filePath("output.png");
    stego.encodeFileInImage(carrierPath, secretPath, outputPath);
    
    QImage encoded(outputPath);
    
    // Calculate visual difference
    int totalPixels = original.width() * original.height();
    int significantlyChanged = 0;
    
    for (int y = 0; y < original.height(); ++y) {
        for (int x = 0; x < original.width(); ++x) {
            QRgb origPixel = original.pixel(x, y);
            QRgb encPixel = encoded.pixel(x, y);
            
            int diffR = qAbs(qRed(origPixel) - qRed(encPixel));
            int diffG = qAbs(qGreen(origPixel) - qGreen(encPixel));
            int diffB = qAbs(qBlue(origPixel) - qBlue(encPixel));
            
            // Count pixels with significant change (>10 intensity levels)
            if (diffR > 10 || diffG > 10 || diffB > 10) {
                significantlyChanged++;
            }
        }
    }
    
    double changePercent = (significantlyChanged * 100.0) / totalPixels;
    qDebug() << "Pixels with significant change:" << significantlyChanged 
             << "(" << changePercent << "%)";
    
    SimpleTest::assert_true(changePercent < 1.0, "Less than 1% pixels significantly changed");
}

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);
    
    qDebug() << "========================================";
    qDebug() << "Steganography Implementation Tests";
    qDebug() << "========================================";
    
    // Run tests
    test_capacity_calculation();
    test_encode_decode_text();
    test_encode_decode_binary();
    test_file_too_large();
    test_hidden_data_detection();
    test_empty_file();
    test_image_quality();
    
    // Summary
    qDebug() << "\n========================================";
    qDebug() << "Test Summary";
    qDebug() << "========================================";
    qDebug() << "Passed:" << SimpleTest::passed;
    qDebug() << "Failed:" << SimpleTest::failed;
    qDebug() << "Total: " << (SimpleTest::passed + SimpleTest::failed);
    
    if (SimpleTest::failed == 0) {
        qDebug() << "\n✓ All tests passed!";
        return 0;
    } else {
        qDebug() << "\n✗ Some tests failed!";
        return 1;
    }
}
