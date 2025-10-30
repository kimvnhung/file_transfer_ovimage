#include <gtest/gtest.h>
#include "steganography.h"
#include "../test_utils.h"
#include <QFile>
#include <QFileInfo>
#include <QSignalSpy>

using namespace TestUtils;

/**
 * Test fixture for Steganography class
 */
class SteganographyTest : public ::testing::Test {
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
// Basic Functionality Tests
// ============================================================================

TEST_F(SteganographyTest, CalculateCapacity_ValidImage_ReturnsCorrectCapacity)
{
    // Create a 100x100 image
    QImage image = ImageGenerator::createSolidColorImage(100, 100, qRgb(128, 128, 128));
    QString imagePath = env->createTempPath("test_image.png");
    ASSERT_TRUE(image.save(imagePath, "PNG"));
    
    // Calculate capacity
    qint64 capacity = stego->calculateCapacity(imagePath);
    
    // Expected: (100 * 100 * 3 channels * 2 bits) / 8 - 256 (header)
    // = (100 * 100 * 6) / 8 - 256 = 7500 - 256 = 7244
    EXPECT_EQ(capacity, 7244);
    EXPECT_EQ(stego->maxCapacity(), 7244);
}

TEST_F(SteganographyTest, CalculateCapacity_InvalidImage_ReturnsZero)
{
    QString invalidPath = "/nonexistent/image.png";
    
    qint64 capacity = stego->calculateCapacity(invalidPath);
    
    EXPECT_EQ(capacity, 0);
    EXPECT_FALSE(stego->lastError().isEmpty());
}

TEST_F(SteganographyTest, EncodeAndDecode_SmallTextFile_Success)
{
    // Create test image
    QImage carrierImage = ImageGenerator::createGradientImage(200, 200);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    // Create test file
    QString testText = "Hello, Steganography! This is a test message.";
    QByteArray testData = FileGenerator::createTextData(testText);
    QString secretPath = FileGenerator::createTempFile(testData, ".txt");
    
    // Encode
    QString outputPath = env->createTempPath("output.png");
    QSignalSpy encodeSpy(stego, &Steganography::encodeComplete);
    
    bool encodeResult = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    
    ASSERT_TRUE(encodeResult);
    EXPECT_TRUE(QFile::exists(outputPath));
    EXPECT_EQ(encodeSpy.count(), 1);
    
    // Decode
    QString decodedPath = env->createTempPath("decoded.txt");
    QSignalSpy decodeSpy(stego, &Steganography::decodeComplete);
    
    bool decodeResult = stego->decodeFileFromImage(outputPath, decodedPath);
    
    ASSERT_TRUE(decodeResult);
    EXPECT_TRUE(QFile::exists(decodedPath));
    EXPECT_EQ(decodeSpy.count(), 1);
    
    // Verify decoded data matches original
    QFile decodedFile(decodedPath);
    ASSERT_TRUE(decodedFile.open(QIODevice::ReadOnly));
    QByteArray decodedData = decodedFile.readAll();
    
    EXPECT_TRUE(Validator::compareBytes(testData, decodedData));
}

TEST_F(SteganographyTest, EncodeAndDecode_BinaryData_Success)
{
    // Create test image
    QImage carrierImage = ImageGenerator::createRandomNoiseImage(300, 300);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    // Create binary test file (1KB of random data)
    QByteArray testData = FileGenerator::createRandomData(1024);
    QString secretPath = FileGenerator::createTempFile(testData, ".bin");
    
    // Encode
    QString outputPath = env->createTempPath("output.png");
    bool encodeResult = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    ASSERT_TRUE(encodeResult);
    
    // Decode
    QString decodedPath = env->createTempPath("decoded.bin");
    bool decodeResult = stego->decodeFileFromImage(outputPath, decodedPath);
    ASSERT_TRUE(decodeResult);
    
    // Verify exact binary match
    QFile decodedFile(decodedPath);
    ASSERT_TRUE(decodedFile.open(QIODevice::ReadOnly));
    QByteArray decodedData = decodedFile.readAll();
    
    EXPECT_EQ(testData.size(), decodedData.size());
    EXPECT_TRUE(Validator::compareBytes(testData, decodedData));
}

TEST_F(SteganographyTest, EncodeAndDecode_LargeFile_Success)
{
    // Create larger image for capacity
    QImage carrierImage = ImageGenerator::createGradientImage(800, 600);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    qint64 capacity = stego->calculateCapacity(carrierPath);
    ASSERT_GT(capacity, 10000);
    
    // Create 10KB file
    QByteArray testData = FileGenerator::createSequentialData(10240);
    QString secretPath = FileGenerator::createTempFile(testData, ".dat");
    
    // Encode
    QString outputPath = env->createTempPath("output.png");
    bool encodeResult = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    ASSERT_TRUE(encodeResult);
    
    // Decode
    QString decodedPath = env->createTempPath("decoded.dat");
    bool decodeResult = stego->decodeFileFromImage(outputPath, decodedPath);
    ASSERT_TRUE(decodeResult);
    
    // Verify
    QFile decodedFile(decodedPath);
    ASSERT_TRUE(decodedFile.open(QIODevice::ReadOnly));
    QByteArray decodedData = decodedFile.readAll();
    
    EXPECT_TRUE(Validator::compareBytes(testData, decodedData));
}

// ============================================================================
// Image Quality Tests
// ============================================================================

TEST_F(SteganographyTest, Encode_ImageQuality_ImperceptibleChanges)
{
    // Create test image
    QImage original = ImageGenerator::createGradientImage(400, 400);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(original.save(carrierPath, "PNG"));
    
    // Create small test file
    QByteArray testData = FileGenerator::createRandomData(500);
    QString secretPath = FileGenerator::createTempFile(testData, ".bin");
    
    // Encode
    QString outputPath = env->createTempPath("output.png");
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    ASSERT_TRUE(result);
    
    // Load encoded image
    QImage encoded(outputPath);
    ASSERT_FALSE(encoded.isNull());
    
    // Check visual similarity (should be >99% similar)
    bool similar = Validator::imagesVisuallySimilar(original, encoded, 0.01);
    EXPECT_TRUE(similar);
    
    // Calculate PSNR (should be >40 dB for imperceptible changes)
    double psnr = Validator::calculatePSNR(original, encoded);
    EXPECT_GT(psnr, 40.0);
}

// ============================================================================
// Header and Metadata Tests
// ============================================================================

TEST_F(SteganographyTest, HasHiddenData_EncodedImage_ReturnsTrue)
{
    // Create and encode
    QImage carrierImage = ImageGenerator::createSolidColorImage(200, 200, qRgb(100, 150, 200));
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    QByteArray testData = FileGenerator::createTextData("Hidden data");
    QString secretPath = FileGenerator::createTempFile(testData, ".txt");
    
    QString outputPath = env->createTempPath("output.png");
    ASSERT_TRUE(stego->encodeFileInImage(carrierPath, secretPath, outputPath));
    
    // Check for hidden data
    bool hasData = stego->hasHiddenData(outputPath);
    EXPECT_TRUE(hasData);
}

TEST_F(SteganographyTest, HasHiddenData_PlainImage_ReturnsFalse)
{
    QImage plainImage = ImageGenerator::createSolidColorImage(200, 200, qRgb(50, 100, 150));
    QString plainPath = env->createTempPath("plain.png");
    ASSERT_TRUE(plainImage.save(plainPath, "PNG"));
    
    bool hasData = stego->hasHiddenData(plainPath);
    EXPECT_FALSE(hasData);
}

TEST_F(SteganographyTest, GetHiddenFileInfo_EncodedImage_ReturnsCorrectInfo)
{
    // Create and encode
    QImage carrierImage = ImageGenerator::createGradientImage(300, 300);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    QByteArray testData = FileGenerator::createRandomData(1234);
    QString secretPath = FileGenerator::createTempFile(testData, ".dat");
    QFileInfo secretInfo(secretPath);
    
    QString outputPath = env->createTempPath("output.png");
    ASSERT_TRUE(stego->encodeFileInImage(carrierPath, secretPath, outputPath));
    
    // Get file info
    QString info = stego->getHiddenFileInfo(outputPath);
    
    EXPECT_FALSE(info.isEmpty());
    EXPECT_TRUE(info.contains(secretInfo.fileName()));
    EXPECT_TRUE(info.contains("1234"));
}

// ============================================================================
// Error Handling Tests
// ============================================================================

TEST_F(SteganographyTest, Encode_FileTooLarge_Fails)
{
    // Create small image
    QImage smallImage = ImageGenerator::createSolidColorImage(50, 50, qRgb(128, 128, 128));
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(smallImage.save(carrierPath, "PNG"));
    
    qint64 capacity = stego->calculateCapacity(carrierPath);
    
    // Create file larger than capacity
    QByteArray largeData = FileGenerator::createRandomData(capacity + 1000);
    QString secretPath = FileGenerator::createTempFile(largeData, ".bin");
    
    QString outputPath = env->createTempPath("output.png");
    QSignalSpy failSpy(stego, &Steganography::encodeFailed);
    
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    
    EXPECT_FALSE(result);
    EXPECT_EQ(failSpy.count(), 1);
    EXPECT_FALSE(stego->lastError().isEmpty());
    EXPECT_TRUE(stego->lastError().contains("too large"));
}

TEST_F(SteganographyTest, Encode_InvalidCarrierImage_Fails)
{
    QString invalidPath = "/nonexistent/image.png";
    QByteArray testData = FileGenerator::createTextData("Test");
    QString secretPath = FileGenerator::createTempFile(testData, ".txt");
    QString outputPath = env->createTempPath("output.png");
    
    QSignalSpy failSpy(stego, &Steganography::encodeFailed);
    
    bool result = stego->encodeFileInImage(invalidPath, secretPath, outputPath);
    
    EXPECT_FALSE(result);
    EXPECT_EQ(failSpy.count(), 1);
}

TEST_F(SteganographyTest, Encode_InvalidSecretFile_Fails)
{
    QImage carrierImage = ImageGenerator::createSolidColorImage(200, 200, qRgb(128, 128, 128));
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    QString invalidPath = "/nonexistent/secret.txt";
    QString outputPath = env->createTempPath("output.png");
    
    QSignalSpy failSpy(stego, &Steganography::encodeFailed);
    
    bool result = stego->encodeFileInImage(carrierPath, invalidPath, outputPath);
    
    EXPECT_FALSE(result);
    EXPECT_EQ(failSpy.count(), 1);
}

TEST_F(SteganographyTest, Decode_InvalidImage_Fails)
{
    QString invalidPath = "/nonexistent/image.png";
    QString outputPath = env->createTempPath("decoded.txt");
    
    QSignalSpy failSpy(stego, &Steganography::decodeFailed);
    
    bool result = stego->decodeFileFromImage(invalidPath, outputPath);
    
    EXPECT_FALSE(result);
    EXPECT_EQ(failSpy.count(), 1);
}

TEST_F(SteganographyTest, Decode_ImageWithoutHiddenData_Fails)
{
    QImage plainImage = ImageGenerator::createSolidColorImage(200, 200, qRgb(128, 128, 128));
    QString plainPath = env->createTempPath("plain.png");
    ASSERT_TRUE(plainImage.save(plainPath, "PNG"));
    
    QString outputPath = env->createTempPath("decoded.txt");
    QSignalSpy failSpy(stego, &Steganography::decodeFailed);
    
    bool result = stego->decodeFileFromImage(plainPath, outputPath);
    
    EXPECT_FALSE(result);
    EXPECT_EQ(failSpy.count(), 1);
}

// ============================================================================
// Progress Tracking Tests
// ============================================================================

TEST_F(SteganographyTest, Encode_ProgressSignals_EmittedCorrectly)
{
    QImage carrierImage = ImageGenerator::createGradientImage(400, 400);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    QByteArray testData = FileGenerator::createRandomData(5000);
    QString secretPath = FileGenerator::createTempFile(testData, ".bin");
    QString outputPath = env->createTempPath("output.png");
    
    QSignalSpy progressSpy(stego, &Steganography::progressChanged);
    
    bool result = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
    
    ASSERT_TRUE(result);
    EXPECT_GT(progressSpy.count(), 3); // Should emit multiple progress updates
    EXPECT_EQ(stego->progress(), 100); // Should end at 100%
}

TEST_F(SteganographyTest, Decode_ProgressSignals_EmittedCorrectly)
{
    // First encode
    QImage carrierImage = ImageGenerator::createGradientImage(400, 400);
    QString carrierPath = env->createTempPath("carrier.png");
    ASSERT_TRUE(carrierImage.save(carrierPath, "PNG"));
    
    QByteArray testData = FileGenerator::createRandomData(5000);
    QString secretPath = FileGenerator::createTempFile(testData, ".bin");
    QString outputPath = env->createTempPath("output.png");
    ASSERT_TRUE(stego->encodeFileInImage(carrierPath, secretPath, outputPath));
    
    // Now decode and track progress
    QSignalSpy progressSpy(stego, &Steganography::progressChanged);
    QString decodedPath = env->createTempPath("decoded.bin");
    
    bool result = stego->decodeFileFromImage(outputPath, decodedPath);
    
    ASSERT_TRUE(result);
    EXPECT_GT(progressSpy.count(), 2);
    EXPECT_EQ(stego->progress(), 100);
}

// ============================================================================
// Different Image Format Tests
// ============================================================================

TEST_F(SteganographyTest, Encode_DifferentColorPatterns_AllWork)
{
    std::vector<std::pair<QString, QImage>> testImages = {
        {"solid", ImageGenerator::createSolidColorImage(200, 200, qRgb(128, 128, 128))},
        {"gradient", ImageGenerator::createGradientImage(200, 200)},
        {"noise", ImageGenerator::createRandomNoiseImage(200, 200)},
        {"checkerboard", ImageGenerator::createCheckerboardImage(200, 200, 10)}
    };
    
    QByteArray testData = FileGenerator::createTextData("Test message for all patterns");
    QString secretPath = FileGenerator::createTempFile(testData, ".txt");
    
    for (const auto &testCase : testImages) {
        QString carrierPath = env->createTempPath("carrier_" + testCase.first + ".png");
        ASSERT_TRUE(testCase.second.save(carrierPath, "PNG"));
        
        QString outputPath = env->createTempPath("output_" + testCase.first + ".png");
        bool encodeResult = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
        EXPECT_TRUE(encodeResult) << "Failed for pattern: " << testCase.first.toStdString();
        
        if (encodeResult) {
            QString decodedPath = env->createTempPath("decoded_" + testCase.first + ".txt");
            bool decodeResult = stego->decodeFileFromImage(outputPath, decodedPath);
            EXPECT_TRUE(decodeResult) << "Decode failed for pattern: " << testCase.first.toStdString();
            
            if (decodeResult) {
                QFile decodedFile(decodedPath);
                ASSERT_TRUE(decodedFile.open(QIODevice::ReadOnly));
                QByteArray decodedData = decodedFile.readAll();
                EXPECT_TRUE(Validator::compareBytes(testData, decodedData))
                    << "Data mismatch for pattern: " << testCase.first.toStdString();
            }
        }
    }
}
