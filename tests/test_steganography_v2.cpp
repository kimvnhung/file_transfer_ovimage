#include <gtest/gtest.h>
#include <QTemporaryDir>
#include <QFile>
#include <QDir>
#include <QImage>
#include "steganography_v2.h"
#include "test_utils.h"

class SteganographyV2Test : public ::testing::Test {
protected:
    void SetUp() override {
        stego = new SteganographyV2();
        tempDir = new QTemporaryDir();
        ASSERT_TRUE(tempDir->isValid());
    }
    
    void TearDown() override {
        delete stego;
        delete tempDir;
    }
    
    // Helper: Create test file
    QString createTestFile(const QString &name, qint64 size) {
        QString path = tempDir->filePath(name);
        QFile file(path);
        EXPECT_TRUE(file.open(QIODevice::WriteOnly));
        
        // Write test data
        for (qint64 i = 0; i < size; ++i) {
            char byte = static_cast<char>(i % 256);
            file.write(&byte, 1);
        }
        file.close();
        
        return path;
    }
    
    // Helper: Verify file content
    bool verifyFileContent(const QString &path, qint64 expectedSize) {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly)) {
            return false;
        }
        
        QByteArray data = file.readAll();
        file.close();
        
        if (data.size() != expectedSize) {
            qDebug() << "Size mismatch: expected" << expectedSize << "got" << data.size();
            return false;
        }
        
        // Verify pattern
        for (qint64 i = 0; i < data.size(); ++i) {
            char expected = static_cast<char>(i % 256);
            if (data[i] != expected) {
                qDebug() << "Content mismatch at byte" << i;
                return false;
            }
        }
        
        return true;
    }
    
    SteganographyV2 *stego;
    QTemporaryDir *tempDir;
};

// Test frame capacity calculation
TEST_F(SteganographyV2Test, FrameCapacity) {
    qint64 capacity = stego->getFrameCapacity();
    EXPECT_EQ(capacity, 744000);  // 744 KB per frame
}

// Test small file encoding (single frame)
TEST_F(SteganographyV2Test, EncodeSmallFile) {
    // Create 10 KB test file
    QString testFile = createTestFile("small.txt", 10000);
    QString outputDir = tempDir->path();
    
    int requiredFrames = stego->calculateRequiredFrames(testFile);
    EXPECT_EQ(requiredFrames, 1);
    
    QStringList frames = stego->encodeFileInFrames(testFile, outputDir, "small_test");
    
    ASSERT_EQ(frames.size(), 1);
    EXPECT_TRUE(QFile::exists(frames[0]));
    
    // Verify frame is 1000×1000
    QImage frame(frames[0]);
    EXPECT_EQ(frame.width(), 1000);
    EXPECT_EQ(frame.height(), 1000);
    
    // Verify valid header
    EXPECT_TRUE(stego->isValidFrame(frames[0]));
}

// Test large file encoding (multiple frames)
TEST_F(SteganographyV2Test, EncodeLargeFile) {
    // Create 1.5 MB test file (should require 3 frames)
    QString testFile = createTestFile("large.bin", 1500000);
    QString outputDir = tempDir->path();
    
    int requiredFrames = stego->calculateRequiredFrames(testFile);
    EXPECT_EQ(requiredFrames, 3);
    
    QStringList frames = stego->encodeFileInFrames(testFile, outputDir, "large_test");
    
    ASSERT_EQ(frames.size(), 3);
    
    // Verify each frame
    for (int i = 0; i < frames.size(); ++i) {
        EXPECT_TRUE(QFile::exists(frames[i]));
        
        QImage frame(frames[i]);
        EXPECT_EQ(frame.width(), 1000);
        EXPECT_EQ(frame.height(), 1000);
        
        EXPECT_TRUE(stego->isValidFrame(frames[i]));
        
        QString info = stego->getFrameInfo(frames[i]);
        EXPECT_TRUE(info.contains("Frame: " + QString::number(i + 1) + " of 3"));
    }
}

// Test decode single frame
TEST_F(SteganographyV2Test, DecodeSingleFrame) {
    // Create and encode
    QString testFile = createTestFile("decode_test.txt", 50000);
    QString outputDir = tempDir->path();
    
    QStringList frames = stego->encodeFileInFrames(testFile, outputDir, "decode");
    ASSERT_EQ(frames.size(), 1);
    
    // Decode
    QString decodedFile = tempDir->filePath("decoded.txt");
    bool success = stego->decodeFileFromFrames(frames, decodedFile);
    
    ASSERT_TRUE(success);
    EXPECT_TRUE(QFile::exists(decodedFile));
    EXPECT_TRUE(verifyFileContent(decodedFile, 50000));
}

// Test decode multiple frames
TEST_F(SteganographyV2Test, DecodeMultipleFrames) {
    // Create and encode 2 MB file
    QString testFile = createTestFile("multi_decode.bin", 2000000);
    QString outputDir = tempDir->path();
    
    QStringList frames = stego->encodeFileInFrames(testFile, outputDir, "multi");
    EXPECT_GT(frames.size(), 1);  // Should be 3 frames
    
    // Decode
    QString decodedFile = tempDir->filePath("decoded_multi.bin");
    bool success = stego->decodeFileFromFrames(frames, decodedFile);
    
    ASSERT_TRUE(success);
    EXPECT_TRUE(QFile::exists(decodedFile));
    EXPECT_TRUE(verifyFileContent(decodedFile, 2000000));
}

// Test round-trip encode/decode
TEST_F(SteganographyV2Test, RoundTripEncodeDecode) {
    QList<qint64> testSizes = {1000, 100000, 750000, 1500000};
    
    for (qint64 size : testSizes) {
        QString testFile = createTestFile(QString("roundtrip_%1.dat").arg(size), size);
        QString outputDir = tempDir->path();
        
        // Encode
        QStringList frames = stego->encodeFileInFrames(testFile, outputDir, QString("rt_%1").arg(size));
        ASSERT_GT(frames.size(), 0) << "Failed to encode " << size << " bytes";
        
        // Decode
        QString decodedFile = tempDir->filePath(QString("decoded_%1.dat").arg(size));
        bool success = stego->decodeFileFromFrames(frames, decodedFile);
        ASSERT_TRUE(success) << "Failed to decode " << size << " bytes";
        
        // Verify
        EXPECT_TRUE(verifyFileContent(decodedFile, size)) 
            << "Content mismatch for " << size << " bytes";
    }
}

// Test frame extraction from larger image
TEST_F(SteganographyV2Test, ExtractFramesFromLargeImage) {
    // Create small test file
    QString testFile = createTestFile("extract_test.txt", 20000);
    QString outputDir = tempDir->path();
    
    // Encode to get frame
    QStringList frames = stego->encodeFileInFrames(testFile, outputDir, "extract");
    ASSERT_EQ(frames.size(), 1);
    
    QImage encodedFrame(frames[0]);
    ASSERT_FALSE(encodedFrame.isNull());
    
    // Create larger image and embed the frame at position (0, 0)
    QImage largeImage(2000, 2000, QImage::Format_RGB888);
    largeImage.fill(Qt::white);
    
    // Copy encoded frame to (0, 0)
    for (int y = 0; y < 1000; ++y) {
        for (int x = 0; x < 1000; ++x) {
            largeImage.setPixel(x, y, encodedFrame.pixel(x, y));
        }
    }
    
    // Save large image
    QString largeImagePath = tempDir->filePath("large_composite.png");
    largeImage.save(largeImagePath, "PNG");
    
    // Extract frames
    QString extractDir = tempDir->filePath("extracted");
    QStringList extractedFrames = stego->extractEncodedFrames(largeImagePath, extractDir);
    
    ASSERT_EQ(extractedFrames.size(), 1);
    
    // Verify extracted frame is valid
    EXPECT_TRUE(stego->isValidFrame(extractedFrames[0]));
    
    // Decode extracted frame
    QString decodedFile = tempDir->filePath("extracted_decoded.txt");
    bool success = stego->decodeFileFromFrames(extractedFrames, decodedFile);
    ASSERT_TRUE(success);
    EXPECT_TRUE(verifyFileContent(decodedFile, 20000));
}

// Test extraction of multiple frames from grid
TEST_F(SteganographyV2Test, ExtractMultipleFramesFromGrid) {
    // Create 2 small test files
    QString testFile1 = createTestFile("grid1.txt", 15000);
    QString testFile2 = createTestFile("grid2.txt", 25000);
    QString outputDir = tempDir->path();
    
    // Encode both
    QStringList frames1 = stego->encodeFileInFrames(testFile1, outputDir, "grid1");
    QStringList frames2 = stego->encodeFileInFrames(testFile2, outputDir, "grid2");
    
    ASSERT_EQ(frames1.size(), 1);
    ASSERT_EQ(frames2.size(), 1);
    
    // Create 2000×1000 image with both frames side by side
    QImage compositeImage(2000, 1000, QImage::Format_RGB888);
    compositeImage.fill(Qt::gray);
    
    QImage frame1(frames1[0]);
    QImage frame2(frames2[0]);
    
    // Place frame1 at (0, 0)
    for (int y = 0; y < 1000; ++y) {
        for (int x = 0; x < 1000; ++x) {
            compositeImage.setPixel(x, y, frame1.pixel(x, y));
        }
    }
    
    // Place frame2 at (1000, 0)
    for (int y = 0; y < 1000; ++y) {
        for (int x = 0; x < 1000; ++x) {
            compositeImage.setPixel(x + 1000, y, frame2.pixel(x, y));
        }
    }
    
    // Save composite
    QString compositePath = tempDir->filePath("composite_grid.png");
    compositeImage.save(compositePath, "PNG");
    
    // Extract all frames
    QString extractDir = tempDir->filePath("grid_extracted");
    QStringList extractedFrames = stego->extractEncodedFrames(compositePath, extractDir);
    
    EXPECT_EQ(extractedFrames.size(), 2);
}

// Test frame info retrieval
TEST_F(SteganographyV2Test, GetFrameInfo) {
    QString testFile = createTestFile("info_test.pdf", 123456);
    QString outputDir = tempDir->path();
    
    QStringList frames = stego->encodeFileInFrames(testFile, outputDir, "info");
    ASSERT_EQ(frames.size(), 1);
    
    QString info = stego->getFrameInfo(frames[0]);
    
    EXPECT_TRUE(info.contains("Filename: info_test.pdf"));
    EXPECT_TRUE(info.contains("Extension: .pdf"));
    EXPECT_TRUE(info.contains("Total Size: 123456 bytes"));
    EXPECT_TRUE(info.contains("Frame: 1 of 1"));
}

// Test invalid frame detection
TEST_F(SteganographyV2Test, InvalidFrameDetection) {
    // Create non-encoded image
    QImage invalidImage(1000, 1000, QImage::Format_RGB888);
    invalidImage.fill(Qt::blue);
    
    QString invalidPath = tempDir->filePath("invalid.png");
    invalidImage.save(invalidPath, "PNG");
    
    EXPECT_FALSE(stego->isValidFrame(invalidPath));
    
    QString info = stego->getFrameInfo(invalidPath);
    EXPECT_TRUE(info.contains("No valid frame header found"));
}

// Test legacy compatibility - encodeFileInImage
TEST_F(SteganographyV2Test, LegacyEncodeCompatibility) {
    QString testFile = createTestFile("legacy.txt", 30000);
    QString outputPath = tempDir->filePath("legacy_encoded.png");
    
    bool success = stego->encodeFileInImage("", testFile, outputPath);
    ASSERT_TRUE(success);
    
    // Should create a file (might be in parent directory with _encoded suffix)
    QDir dir(tempDir->path());
    QStringList pngFiles = dir.entryList(QStringList() << "*.png", QDir::Files);
    EXPECT_GT(pngFiles.size(), 0);
}

// Test legacy compatibility - decodeFileFromImage
TEST_F(SteganographyV2Test, LegacyDecodeCompatibility) {
    QString testFile = createTestFile("legacy_decode.txt", 40000);
    QString outputDir = tempDir->path();
    
    QStringList frames = stego->encodeFileInFrames(testFile, outputDir, "legacy_dec");
    ASSERT_EQ(frames.size(), 1);
    
    // Use legacy decode method
    QString decodedFile = tempDir->filePath("legacy_decoded.txt");
    bool success = stego->decodeFileFromImage(frames[0], decodedFile);
    
    ASSERT_TRUE(success);
    EXPECT_TRUE(verifyFileContent(decodedFile, 40000));
}

// Performance test: Large file handling
TEST_F(SteganographyV2Test, LargeFilePerformance) {
    // Create 5 MB file
    QString testFile = createTestFile("performance.bin", 5000000);
    QString outputDir = tempDir->path();
    
    int requiredFrames = stego->calculateRequiredFrames(testFile);
    EXPECT_EQ(requiredFrames, 7);  // 5MB / 744KB ≈ 7 frames
    
    QStringList frames = stego->encodeFileInFrames(testFile, outputDir, "perf");
    ASSERT_EQ(frames.size(), 7);
    
    // Decode
    QString decodedFile = tempDir->filePath("performance_decoded.bin");
    bool success = stego->decodeFileFromFrames(frames, decodedFile);
    ASSERT_TRUE(success);
    
    EXPECT_TRUE(verifyFileContent(decodedFile, 5000000));
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
