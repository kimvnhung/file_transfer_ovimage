#include <gtest/gtest.h>
#include <QImage>
#include <QTemporaryDir>
#include <QFile>
#include <QCryptographicHash>
#include "borderheader.h"
#include "framemanager.h"

class BorderHeaderTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Create a blank 1000×1000 image for testing
        testImage = QImage(1000, 1000, QImage::Format_RGB888);
        testImage.fill(Qt::white);
    }
    
    QImage testImage;
};

// Test border header creation
TEST_F(BorderHeaderTest, CreateHeader) {
    auto header = BorderHeader::createHeader(
        "test_document.pdf",
        ".pdf",
        123456,
        1,
        3,
        QByteArray("1234567890123456")  // 16-byte checksum
    );
    
    EXPECT_EQ(header.filename, "test_document.pdf");
    EXPECT_EQ(header.extension, ".pdf");
    EXPECT_EQ(header.totalDataLength, 123456);
    EXPECT_EQ(header.currentFrame, 1);
    EXPECT_EQ(header.totalFrames, 3);
    EXPECT_EQ(header.version, 1);
    EXPECT_EQ(header.checksum.size(), 16);
}

// Test header validation
TEST_F(BorderHeaderTest, ValidateHeader) {
    auto validHeader = BorderHeader::createHeader("file.txt", ".txt", 1000, 1, 1);
    EXPECT_TRUE(BorderHeader::validate(validHeader));
    
    // Invalid: empty filename
    BorderHeader::Data invalid1;
    invalid1.filename = "";
    invalid1.totalDataLength = 1000;
    invalid1.totalFrames = 1;
    invalid1.currentFrame = 1;
    EXPECT_FALSE(BorderHeader::validate(invalid1));
    
    // Invalid: zero data length
    BorderHeader::Data invalid2;
    invalid2.filename = "test.txt";
    invalid2.totalDataLength = 0;
    invalid2.totalFrames = 1;
    invalid2.currentFrame = 1;
    EXPECT_FALSE(BorderHeader::validate(invalid2));
    
    // Invalid: frame number out of range
    BorderHeader::Data invalid3;
    invalid3.filename = "test.txt";
    invalid3.totalDataLength = 1000;
    invalid3.totalFrames = 3;
    invalid3.currentFrame = 5;  // > totalFrames
    EXPECT_FALSE(BorderHeader::validate(invalid3));
}

// Test serialization/deserialization
TEST_F(BorderHeaderTest, SerializeDeserialize) {
    QByteArray checksum = QCryptographicHash::hash("test data", QCryptographicHash::Md5);
    
    auto original = BorderHeader::createHeader(
        "my_document.pdf",
        ".pdf",
        987654,
        2,
        5,
        checksum
    );
    
    QByteArray serialized = BorderHeader::serialize(original);
    EXPECT_GT(serialized.size(), 0);
    
    auto deserialized = BorderHeader::deserialize(serialized);
    
    EXPECT_EQ(deserialized.filename, original.filename);
    EXPECT_EQ(deserialized.extension, original.extension);
    EXPECT_EQ(deserialized.totalDataLength, original.totalDataLength);
    EXPECT_EQ(deserialized.currentFrame, original.currentFrame);
    EXPECT_EQ(deserialized.totalFrames, original.totalFrames);
    EXPECT_EQ(deserialized.checksum, original.checksum);
}

// Test encoding to border
TEST_F(BorderHeaderTest, EncodeToBorder) {
    auto header = BorderHeader::createHeader(
        "test_file.txt",
        ".txt",
        5000,
        1,
        1,
        QByteArray(16, 'X')  // Dummy checksum
    );
    
    bool success = BorderHeader::encodeToBorder(testImage, header);
    EXPECT_TRUE(success);
    
    // Verify magic bytes can be detected
    EXPECT_TRUE(BorderHeader::hasValidHeader(testImage));
}

// Test reading from border
TEST_F(BorderHeaderTest, ReadFromBorder) {
    QByteArray checksum = QCryptographicHash::hash("important data", QCryptographicHash::Md5);
    
    auto original = BorderHeader::createHeader(
        "important.docx",
        ".docx",
        234567,
        3,
        7,
        checksum
    );
    
    // Encode
    bool encoded = BorderHeader::encodeToBorder(testImage, original);
    ASSERT_TRUE(encoded);
    
    // Read back
    auto readHeader = BorderHeader::readFromBorder(testImage);
    
    EXPECT_EQ(readHeader.filename, original.filename);
    EXPECT_EQ(readHeader.extension, original.extension);
    EXPECT_EQ(readHeader.totalDataLength, original.totalDataLength);
    EXPECT_EQ(readHeader.currentFrame, original.currentFrame);
    EXPECT_EQ(readHeader.totalFrames, original.totalFrames);
    EXPECT_EQ(readHeader.checksum, original.checksum);
}

// Test long filename (truncation)
TEST_F(BorderHeaderTest, LongFilename) {
    QString longName = QString("a").repeated(100);  // 100 characters
    
    auto header = BorderHeader::createHeader(longName, ".txt", 1000, 1, 1);
    
    EXPECT_LE(header.filename.length(), BorderHeader::MAX_FILENAME_LENGTH);
    EXPECT_EQ(header.filename.length(), BorderHeader::MAX_FILENAME_LENGTH);
}

// Test capacity calculation
TEST_F(BorderHeaderTest, CalculateCapacity) {
    qint64 capacity = BorderHeader::calculateDataCapacity();
    
    // 996×996 pixels × 6 bits/pixel / 8 = ~744,012 bytes
    EXPECT_GT(capacity, 700000);
    EXPECT_LT(capacity, 750000);
    
    qDebug() << "Border header data capacity:" << capacity << "bytes";
}

// Frame Manager Tests
class FrameManagerTest : public ::testing::Test {
protected:
    QByteArray createTestData(qint64 size) {
        QByteArray data;
        data.resize(size);
        for (qint64 i = 0; i < size; ++i) {
            data[i] = static_cast<char>(i % 256);
        }
        return data;
    }
};

// Test frame count calculation
TEST_F(FrameManagerTest, CalculateFrameCount) {
    qint64 capacity = FrameManager::getFrameCapacity();
    
    EXPECT_EQ(FrameManager::calculateFrameCount(0), 0);
    EXPECT_EQ(FrameManager::calculateFrameCount(1000), 1);
    EXPECT_EQ(FrameManager::calculateFrameCount(capacity), 1);
    EXPECT_EQ(FrameManager::calculateFrameCount(capacity + 1), 2);
    EXPECT_EQ(FrameManager::calculateFrameCount(capacity * 2), 2);
    EXPECT_EQ(FrameManager::calculateFrameCount(capacity * 2 + 1), 3);
}

// Test splitting small file (single frame)
TEST_F(FrameManagerTest, SplitSmallFile) {
    QByteArray data = createTestData(10000);  // 10 KB
    
    auto frames = FrameManager::splitIntoFrames(data);
    
    ASSERT_EQ(frames.size(), 1);
    EXPECT_EQ(frames[0], data);
}

// Test splitting large file (multiple frames)
TEST_F(FrameManagerTest, SplitLargeFile) {
    qint64 capacity = FrameManager::getFrameCapacity();
    QByteArray data = createTestData(capacity * 2 + 50000);  // 2.5 frames worth
    
    auto frames = FrameManager::splitIntoFrames(data);
    
    ASSERT_EQ(frames.size(), 3);
    EXPECT_EQ(frames[0].size(), capacity);
    EXPECT_EQ(frames[1].size(), capacity);
    EXPECT_EQ(frames[2].size(), 50000);
}

// Test merging frames
TEST_F(FrameManagerTest, MergeFrames) {
    QByteArray original = createTestData(2000000);  // 2 MB
    
    // Split
    auto frames = FrameManager::splitIntoFrames(original);
    EXPECT_GT(frames.size(), 1);
    
    // Merge
    QByteArray merged = FrameManager::mergeFrames(frames);
    
    EXPECT_EQ(merged.size(), original.size());
    EXPECT_EQ(merged, original);
}

// Test round-trip split/merge
TEST_F(FrameManagerTest, RoundTripSplitMerge) {
    // Test with various sizes
    QList<qint64> testSizes = {500, 50000, 750000, 1500000, 3000000};
    
    for (qint64 size : testSizes) {
        QByteArray original = createTestData(size);
        
        auto frames = FrameManager::splitIntoFrames(original);
        QByteArray merged = FrameManager::mergeFrames(frames);
        
        EXPECT_EQ(merged, original) << "Round-trip failed for size " << size;
    }
}

// Test frame filename generation
TEST_F(FrameManagerTest, GenerateFrameFilename) {
    QString name1 = FrameManager::generateFrameFilename("document.pdf", 1, 1);
    EXPECT_EQ(name1, "document_encoded.png");
    
    QString name2 = FrameManager::generateFrameFilename("document.pdf", 1, 3);
    EXPECT_EQ(name2, "document_frame_1_of_3.png");
    
    QString name3 = FrameManager::generateFrameFilename("document.pdf", 2, 3);
    EXPECT_EQ(name3, "document_frame_2_of_3.png");
}

// Test frame filename parsing
TEST_F(FrameManagerTest, ParseFrameFilename) {
    int frameNum, totalFrames;
    QString baseName;
    
    // Single frame
    bool ok1 = FrameManager::parseFrameFilename("doc_encoded.png", frameNum, totalFrames, baseName);
    EXPECT_TRUE(ok1);
    EXPECT_EQ(baseName, "doc");
    EXPECT_EQ(frameNum, 1);
    EXPECT_EQ(totalFrames, 1);
    
    // Multi-frame
    bool ok2 = FrameManager::parseFrameFilename("document_frame_2_of_5.png", frameNum, totalFrames, baseName);
    EXPECT_TRUE(ok2);
    EXPECT_EQ(baseName, "document");
    EXPECT_EQ(frameNum, 2);
    EXPECT_EQ(totalFrames, 5);
    
    // Invalid
    bool ok3 = FrameManager::parseFrameFilename("invalid_filename.png", frameNum, totalFrames, baseName);
    EXPECT_FALSE(ok3);
}

// Integration test: Complete workflow
TEST_F(BorderHeaderTest, CompleteWorkflow) {
    // 1. Create test data
    QByteArray fileData = "This is test file content for steganography.\n";
    fileData.append(QString("A").repeated(50000).toUtf8());  // Make it substantial
    
    QByteArray checksum = QCryptographicHash::hash(fileData, QCryptographicHash::Md5);
    
    // 2. Create header
    auto header = BorderHeader::createHeader(
        "test_workflow.txt",
        ".txt",
        fileData.size(),
        1,
        1,
        checksum
    );
    
    // 3. Create image and encode header
    QImage image(1000, 1000, QImage::Format_RGB888);
    image.fill(Qt::white);
    
    bool encoded = BorderHeader::encodeToBorder(image, header);
    ASSERT_TRUE(encoded);
    
    // 4. Verify detection
    EXPECT_TRUE(BorderHeader::hasValidHeader(image));
    
    // 5. Read header back
    auto readHeader = BorderHeader::readFromBorder(image);
    
    EXPECT_EQ(readHeader.filename, header.filename);
    EXPECT_EQ(readHeader.extension, header.extension);
    EXPECT_EQ(readHeader.totalDataLength, header.totalDataLength);
    EXPECT_EQ(readHeader.currentFrame, header.currentFrame);
    EXPECT_EQ(readHeader.totalFrames, header.totalFrames);
    EXPECT_EQ(readHeader.checksum, checksum);
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
