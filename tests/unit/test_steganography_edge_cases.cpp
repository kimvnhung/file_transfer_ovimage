#include <gtest/gtest.h>
#include "steganography.h"
#include "../test_utils.h"
#include <QFile>

using namespace TestUtils;

/**
 * Test fixture for edge cases and boundary conditions
 */
class SteganographyEdgeCaseTest : public ::testing::Test {
protected:
    void SetUp() override {
        stego = new Steganography();
        env = new TestEnvironment();
    }
    
    void TearDown() override {
        delete stego;
        delete env;
    }
    
    Steganography *stego;
    TestEnvironment *env;
};

// ============================================================================
// Boundary Condition Tests
// ============================================================================

TEST_F(SteganographyEdgeCaseTest, Encode_EmptyFile_Success)
{
    QImage carrierImage = ImageGenerator::createGradientImage(200, 200);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    // Create empty file
    QByteArray emptyData;
    QString secretPath = FileGenerator::createTempFile(emptyData, ".txt");
    
    QString outputPath = env->createTempPath("output.png");
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    
    // Empty files should still work (just header)
    EXPECT_TRUE(result);
    
    if (result) {
        QString decodedPath = env->createTempPath("decoded.txt");
        bool decodeResult = stego->decodeFileFromImage(outputPath, decodedPath);
        EXPECT_TRUE(decodeResult);
        
        QFile decodedFile(decodedPath);
        ASSERT_TRUE(decodedFile.open(QIODevice::ReadOnly));
        QByteArray decodedData = decodedFile.readAll();
        EXPECT_EQ(decodedData.size(), 0);
    }
}

TEST_F(SteganographyEdgeCaseTest, Encode_SingleByteFile_Success)
{
    QImage carrierImage = ImageGenerator::createSolidColorImage(100, 100, qRgb(128, 128, 128));
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    QByteArray oneByteData;
    oneByteData.append('X');
    QString secretPath = FileGenerator::createTempFile(oneByteData, ".bin");
    
    QString outputPath = env->createTempPath("output.png");
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    ASSERT_TRUE(result);
    
    QString decodedPath = env->createTempPath("decoded.bin");
    bool decodeResult = stego->decodeFileFromImage(outputPath, decodedPath);
    ASSERT_TRUE(decodeResult);
    
    QFile decodedFile(decodedPath);
    ASSERT_TRUE(decodedFile.open(QIODevice::ReadOnly));
    QByteArray decodedData = decodedFile.readAll();
    
    EXPECT_EQ(decodedData.size(), 1);
    EXPECT_EQ(decodedData[0], 'X');
}

TEST_F(SteganographyEdgeCaseTest, Encode_MaximumCapacity_Success)
{
    // Create image with known capacity
    QImage carrierImage = ImageGenerator::createGradientImage(300, 300);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    qint64 capacity = stego->calculateCapacity(carrierPath);
    ASSERT_GT(capacity, 100);
    
    // Create file at exactly maximum capacity (minus a few bytes for safety)
    QByteArray maxData = FileGenerator::createRandomData(capacity - 50);
    QString secretPath = FileGenerator::createTempFile(maxData, ".bin");
    
    QString outputPath = env->createTempPath("output.png");
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    EXPECT_TRUE(result);
    
    if (result) {
        QString decodedPath = env->createTempPath("decoded.bin");
        bool decodeResult = stego->decodeFileFromImage(outputPath, decodedPath);
        ASSERT_TRUE(decodeResult);
        
        QFile decodedFile(decodedPath);
        ASSERT_TRUE(decodedFile.open(QIODevice::ReadOnly));
        QByteArray decodedData = decodedFile.readAll();
        
        EXPECT_TRUE(Validator::compareBytes(maxData, decodedData));
    }
}

TEST_F(SteganographyEdgeCaseTest, Encode_OnePixelOverCapacity_Fails)
{
    QImage smallImage = ImageGenerator::createSolidColorImage(50, 50, qRgb(128, 128, 128));
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(smallImage.save(carrierPath, "PNG"));
    
    qint64 capacity = stego->calculateCapacity(carrierPath);
    
    // Create file just 1 byte over capacity
    QByteArray overCapacityData = FileGenerator::createRandomData(capacity + 1);
    QString secretPath = FileGenerator::createTempFile(overCapacityData, ".bin");
    
    QString outputPath = env->createTempPath("output.png");
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    
    EXPECT_FALSE(result);
    EXPECT_FALSE(stego->lastError().isEmpty());
}

TEST_F(SteganographyEdgeCaseTest, Encode_MinimalImage_1x1Pixel_Fails)
{
    QImage tinyImage = ImageGenerator::createSolidColorImage(1, 1, qRgb(128, 128, 128));
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(tinyImage.save(carrierPath, "PNG"));
    
    qint64 capacity = stego->calculateCapacity(carrierPath);
    
    // 1x1 image has very limited capacity (negative after header overhead)
    EXPECT_LT(capacity, 100); // Should be minimal or negative
    
    QByteArray testData = FileGenerator::createTextData("Test");
    QString secretPath = FileGenerator::createTempFile(testData, ".txt");
    QString outputPath = env->createTempPath("output.png");
    
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    EXPECT_FALSE(result); // Should fail - not enough capacity
}

// ============================================================================
// Special Character and Filename Tests
// ============================================================================

TEST_F(SteganographyEdgeCaseTest, Encode_LongFilename_Success)
{
    QImage carrierImage = ImageGenerator::createGradientImage(200, 200);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    // Create file with very long name
    QString longName = "very_long_filename_with_many_characters_to_test_header_parsing_" 
                      "and_ensure_it_handles_extended_names_properly_12345.txt";
    QByteArray testData = FileGenerator::createTextData("Content");
    QString secretPath = env->createTempPath(longName);
    QFile secretFile(secretPath);
    ASSERT_TRUE(secretFile.open(QIODevice::WriteOnly));
    secretFile.write(testData);
    secretFile.close();
    
    QString outputPath = env->createTempPath("output.png");
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    EXPECT_TRUE(result);
    
    if (result) {
        QString info = stego->getHiddenFileInfo(outputPath);
        EXPECT_TRUE(info.contains(longName));
    }
}

TEST_F(SteganographyEdgeCaseTest, Encode_SpecialCharactersInFilename_Success)
{
    QImage carrierImage = ImageGenerator::createGradientImage(200, 200);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    // File with special characters (that are filesystem-safe)
    QString specialName = "test_file-2024(1)[copy].txt";
    QByteArray testData = FileGenerator::createTextData("Test content");
    QString secretPath = env->createTempPath(specialName);
    QFile secretFile(secretPath);
    ASSERT_TRUE(secretFile.open(QIODevice::WriteOnly));
    secretFile.write(testData);
    secretFile.close();
    
    QString outputPath = env->createTempPath("output.png");
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    EXPECT_TRUE(result);
}

TEST_F(SteganographyEdgeCaseTest, Encode_UnicodeFilename_Success)
{
    QImage carrierImage = ImageGenerator::createGradientImage(200, 200);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    // Unicode filename
    QString unicodeName = "测试文件_テスト_тест.txt";
    QByteArray testData = FileGenerator::createTextData("Unicode test");
    QString secretPath = env->createTempPath(unicodeName);
    QFile secretFile(secretPath);
    ASSERT_TRUE(secretFile.open(QIODevice::WriteOnly));
    secretFile.write(testData);
    secretFile.close();
    
    QString outputPath = env->createTempPath("output.png");
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    EXPECT_TRUE(result);
    
    if (result) {
        QString decodedPath = env->createTempPath("decoded_unicode");
        bool decodeResult = stego->decodeFileFromImage(outputPath, decodedPath);
        EXPECT_TRUE(decodeResult);
    }
}

// ============================================================================
// Data Pattern Tests
// ============================================================================

TEST_F(SteganographyEdgeCaseTest, Encode_AllZeroBytes_Success)
{
    QImage carrierImage = ImageGenerator::createRandomNoiseImage(200, 200);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    QByteArray zeroData = FileGenerator::createPatternData(1000, 0x00);
    QString secretPath = FileGenerator::createTempFile(zeroData, ".bin");
    
    QString outputPath = env->createTempPath("output.png");
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    ASSERT_TRUE(result);
    
    QString decodedPath = env->createTempPath("decoded.bin");
    bool decodeResult = stego->decodeFileFromImage(outputPath, decodedPath);
    ASSERT_TRUE(decodeResult);
    
    QFile decodedFile(decodedPath);
    ASSERT_TRUE(decodedFile.open(QIODevice::ReadOnly));
    QByteArray decodedData = decodedFile.readAll();
    
    EXPECT_TRUE(Validator::compareBytes(zeroData, decodedData));
}

TEST_F(SteganographyEdgeCaseTest, Encode_AllOnesBytes_Success)
{
    QImage carrierImage = ImageGenerator::createRandomNoiseImage(200, 200);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    QByteArray onesData = FileGenerator::createPatternData(1000, 0xFF);
    QString secretPath = FileGenerator::createTempFile(onesData, ".bin");
    
    QString outputPath = env->createTempPath("output.png");
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    ASSERT_TRUE(result);
    
    QString decodedPath = env->createTempPath("decoded.bin");
    bool decodeResult = stego->decodeFileFromImage(outputPath, decodedPath);
    ASSERT_TRUE(decodeResult);
    
    QFile decodedFile(decodedPath);
    ASSERT_TRUE(decodedFile.open(QIODevice::ReadOnly));
    QByteArray decodedData = decodedFile.readAll();
    
    EXPECT_TRUE(Validator::compareBytes(onesData, decodedData));
}

TEST_F(SteganographyEdgeCaseTest, Encode_AlternatingPattern_Success)
{
    QImage carrierImage = ImageGenerator::createCheckerboardImage(200, 200, 10);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    // Alternating 0xAA (10101010) and 0x55 (01010101)
    QByteArray alternatingData;
    for (int i = 0; i < 500; ++i) {
        alternatingData.append(static_cast<char>(i % 2 == 0 ? 0xAA : 0x55));
    }
    QString secretPath = FileGenerator::createTempFile(alternatingData, ".bin");
    
    QString outputPath = env->createTempPath("output.png");
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    ASSERT_TRUE(result);
    
    QString decodedPath = env->createTempPath("decoded.bin");
    bool decodeResult = stego->decodeFileFromImage(outputPath, decodedPath);
    ASSERT_TRUE(decodeResult);
    
    QFile decodedFile(decodedPath);
    ASSERT_TRUE(decodedFile.open(QIODevice::ReadOnly));
    QByteArray decodedData = decodedFile.readAll();
    
    EXPECT_TRUE(Validator::compareBytes(alternatingData, decodedData));
}

// ============================================================================
// Corrupted Data Tests
// ============================================================================

TEST_F(SteganographyEdgeCaseTest, Decode_CorruptedMagicNumber_Fails)
{
    // Create and encode normally
    QImage carrierImage = ImageGenerator::createGradientImage(200, 200);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    QByteArray testData = FileGenerator::createTextData("Test");
    QString secretPath = FileGenerator::createTempFile(testData, ".txt");
    QString outputPath = env->createTempPath("output.png");
    ASSERT_TRUE(stego->encodeFileInImage(carrierPath, secretPath, outputPath));
    
    // Load and corrupt the first few pixels (where magic number is stored)
    QImage corrupted(outputPath);
    ASSERT_FALSE(corrupted.isNull());
    
    // Change first pixel significantly (corrupt magic number)
    corrupted.setPixel(0, 0, qRgb(255, 255, 255));
    corrupted.setPixel(1, 0, qRgb(0, 0, 0));
    
    QString corruptedPath = env->createTempPath("corrupted.png");
    ASSERT_TRUE(corrupted.save(corruptedPath, "PNG"));
    
    // Try to decode corrupted image
    QString decodedPath = env->createTempPath("decoded.txt");
    bool result = stego->decodeFileFromImage(corruptedPath, decodedPath);
    
    EXPECT_FALSE(result);
}

TEST_F(SteganographyEdgeCaseTest, Decode_TruncatedImage_Fails)
{
    // Create encoded image
    QImage carrierImage = ImageGenerator::createGradientImage(100, 100);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    QByteArray testData = FileGenerator::createRandomData(1000);
    QString secretPath = FileGenerator::createTempFile(testData, ".bin");
    QString outputPath = env->createTempPath("output.png");
    ASSERT_TRUE(stego->encodeFileInImage(carrierPath, secretPath, outputPath));
    
    // Create truncated version (smaller image)
    QImage original(outputPath);
    QImage truncated = original.copy(0, 0, 50, 50); // Take only top-left quarter
    
    QString truncatedPath = env->createTempPath("truncated.png");
    ASSERT_TRUE(truncated.save(truncatedPath, "PNG"));
    
    // Try to decode truncated image
    QString decodedPath = env->createTempPath("decoded.bin");
    bool result = stego->decodeFileFromImage(truncatedPath, decodedPath);
    
    EXPECT_FALSE(result); // Should fail due to incomplete data
}

// ============================================================================
// Multiple Encode/Decode Cycles
// ============================================================================

TEST_F(SteganographyEdgeCaseTest, MultipleEncodeDecode_DataIntegrity_Maintained)
{
    // Original data
    QByteArray originalData = FileGenerator::createRandomData(500);
    QString secretPath1 = FileGenerator::createTempFile(originalData, ".bin");
    
    // First encode
    QImage carrier1 = ImageGenerator::createGradientImage(300, 300);
    QString carrierPath1 = env->createTempPath("carrier1.png");
    ASSERT_TRUE(carrier1.save(carrierPath1, "PNG"));
    
    QString encoded1Path = env->createTempPath("encoded1.png");
    ASSERT_TRUE(stego->encodeFileInImage(carrierPath1, secretPath1, encoded1Path));
    
    // First decode
    QString decoded1Path = env->createTempPath("decoded1.bin");
    ASSERT_TRUE(stego->decodeFileFromImage(encoded1Path, decoded1Path));
    
    // Second encode (re-encode the decoded file)
    QImage carrier2 = ImageGenerator::createRandomNoiseImage(300, 300);
    QString carrierPath2 = env->createTempPath("carrier2.png");
    ASSERT_TRUE(carrier2.save(carrierPath2, "PNG"));
    
    QString encoded2Path = env->createTempPath("encoded2.png");
    ASSERT_TRUE(stego->encodeFileInImage(carrierPath2, decoded1Path, encoded2Path));
    
    // Second decode
    QString decoded2Path = env->createTempPath("decoded2.bin");
    ASSERT_TRUE(stego->decodeFileFromImage(encoded2Path, decoded2Path));
    
    // Verify final data matches original
    QFile finalFile(decoded2Path);
    ASSERT_TRUE(finalFile.open(QIODevice::ReadOnly));
    QByteArray finalData = finalFile.readAll();
    
    EXPECT_TRUE(Validator::compareBytes(originalData, finalData));
}

// ============================================================================
// Extreme Image Dimensions
// ============================================================================

TEST_F(SteganographyEdgeCaseTest, Encode_VeryWideImage_Success)
{
    // Very wide but short image (1000x10)
    QImage wideImage = ImageGenerator::createGradientImage(1000, 10);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(wideImage.save(carrierPath, "PNG"));
    
    qint64 capacity = stego->calculateCapacity(carrierPath);
    ASSERT_GT(capacity, 100);
    
    QByteArray testData = FileGenerator::createRandomData(100);
    QString secretPath = FileGenerator::createTempFile(testData, ".bin");
    
    QString outputPath = env->createTempPath("output.png");
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    EXPECT_TRUE(result);
}

TEST_F(SteganographyEdgeCaseTest, Encode_VeryTallImage_Success)
{
    // Very tall but narrow image (10x1000)
    QImage tallImage = ImageGenerator::createGradientImage(10, 1000);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(tallImage.save(carrierPath, "PNG"));
    
    qint64 capacity = stego->calculateCapacity(carrierPath);
    ASSERT_GT(capacity, 100);
    
    QByteArray testData = FileGenerator::createRandomData(100);
    QString secretPath = FileGenerator::createTempFile(testData, ".bin");
    
    QString outputPath = env->createTempPath("output.png");
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    EXPECT_TRUE(result);
}
