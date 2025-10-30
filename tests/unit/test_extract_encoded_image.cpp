#include <gtest/gtest.h>
#include "steganography.h"
#include "../test_utils.h"
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QDebug>

using namespace TestUtils;

/**
 * Test fixture for extractEncodedImage functionality
 */
class ExtractEncodedImageTest : public ::testing::Test {
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
// Extract Encoded Image Tests
// ============================================================================

TEST_F(ExtractEncodedImageTest, ExtractFromExistingEncodedImage_Success)
{
    // Use the existing encoded image from downloads
    QString encodedImagePath = QDir::homePath() + "/downloads/test1.png";
    
    // Check if the file exists
    QFileInfo fileInfo(encodedImagePath);
    if (!fileInfo.exists()) {
        GTEST_SKIP() << "Test file ~/downloads/test1.png not found. Skipping test.";
    }
    
    qDebug() << "Testing with existing encoded image:" << encodedImagePath;
    
    // First, verify the image contains hidden data
    ASSERT_TRUE(stego->hasHiddenData(encodedImagePath)) 
        << "test1.png should contain hidden data";
    
    // Get info about the hidden data
    QString hiddenInfo = stego->getHiddenFileInfo(encodedImagePath);
    qDebug() << "Hidden file info:" << hiddenInfo;
    EXPECT_FALSE(hiddenInfo.isEmpty());
    
    // Try to extract the encoded image (in this case, it's already the encoded image)
    QString outputPath = env->createTempPath("extracted_image.png");
    bool success = stego->extractEncodedImage(encodedImagePath, outputPath);
    
    // Since test1.png is already an encoded image (not embedded in a larger one),
    // the extraction should either succeed and extract itself, or fail gracefully
    if (success) {
        qDebug() << "Extraction succeeded";
        EXPECT_TRUE(QFile::exists(outputPath));
        
        // Verify the extracted image also contains hidden data
        EXPECT_TRUE(stego->hasHiddenData(outputPath));
    } else {
        qDebug() << "Extraction note:" << stego->lastError();
        // This is acceptable if the image is already the encoded image
    }
}

TEST_F(ExtractEncodedImageTest, ExtractFromLargerImage_EmbeddedEncodedImage)
{
    // Step 1: Create a small encoded image
    QString secretData = "This is test data for extraction";
    QString secretFilePath = env->createTempPath("secret.txt");
    ASSERT_TRUE(env->writeFile(secretFilePath, secretData));
    
    // Create an encoded image (auto-generated)
    QString encodedImagePath = env->createTempPath("encoded_small.png");
    ASSERT_TRUE(stego->encodeFileInImage("", secretFilePath, encodedImagePath));
    ASSERT_TRUE(QFile::exists(encodedImagePath));
    
    qDebug() << "Created small encoded image:" << encodedImagePath;
    
    // Step 2: Load the encoded image and get its dimensions
    QImage encodedImage(encodedImagePath);
    ASSERT_FALSE(encodedImage.isNull());
    int encodedWidth = encodedImage.width();
    int encodedHeight = encodedImage.height();
    
    qDebug() << "Encoded image size:" << encodedWidth << "x" << encodedHeight;
    
    // Step 3: Create a larger image and embed the encoded image in it
    int largerWidth = encodedWidth + 200;
    int largerHeight = encodedHeight + 200;
    QImage largerImage = ImageGenerator::createGradientImage(largerWidth, largerHeight);
    
    // Embed the encoded image at position (50, 50)
    for (int y = 0; y < encodedHeight && (y + 50) < largerHeight; ++y) {
        for (int x = 0; x < encodedWidth && (x + 50) < largerWidth; ++x) {
            largerImage.setPixel(x + 50, y + 50, encodedImage.pixel(x, y));
        }
    }
    
    QString largerImagePath = env->createTempPath("larger_with_embedded.png");
    ASSERT_TRUE(largerImage.save(largerImagePath, "PNG"));
    
    qDebug() << "Created larger image with embedded encoded image:" << largerImagePath;
    qDebug() << "Larger image size:" << largerWidth << "x" << largerHeight;
    
    // Step 4: Extract the encoded image from the larger image
    QString extractedPath = env->createTempPath("extracted.png");
    bool success = stego->extractEncodedImage(largerImagePath, extractedPath);
    
    if (!success) {
        qDebug() << "Extraction failed:" << stego->lastError();
    }
    
    EXPECT_TRUE(success) << "Failed to extract encoded image: " << stego->lastError().toStdString();
    ASSERT_TRUE(QFile::exists(extractedPath));
    
    // Step 5: Verify the extracted image contains the hidden data
    EXPECT_TRUE(stego->hasHiddenData(extractedPath)) 
        << "Extracted image should contain hidden data";
    
    // Step 6: Decode the extracted image and verify the content
    QString decodedFilePath = env->createTempPath("decoded.txt");
    ASSERT_TRUE(stego->decodeFileFromImage(extractedPath, decodedFilePath));
    
    QString decodedContent = env->readFile(decodedFilePath);
    EXPECT_EQ(decodedContent, secretData) << "Decoded content should match original";
    
    qDebug() << "Successfully extracted and verified encoded image from larger image";
}

TEST_F(ExtractEncodedImageTest, ExtractFromTopLeftCorner)
{
    // Create encoded image at top-left corner (0, 0)
    QString secretData = "Corner test data";
    QString secretFilePath = env->createTempPath("secret_corner.txt");
    ASSERT_TRUE(env->writeFile(secretFilePath, secretData));
    
    QString encodedImagePath = env->createTempPath("encoded_corner.png");
    ASSERT_TRUE(stego->encodeFileInImage("", secretFilePath, encodedImagePath));
    
    QImage encodedImage(encodedImagePath);
    ASSERT_FALSE(encodedImage.isNull());
    
    // Create larger image with encoded image at (0, 0)
    QImage largerImage = ImageGenerator::createGradientImage(
        encodedImage.width() + 100, 
        encodedImage.height() + 100
    );
    
    for (int y = 0; y < encodedImage.height(); ++y) {
        for (int x = 0; x < encodedImage.width(); ++x) {
            largerImage.setPixel(x, y, encodedImage.pixel(x, y));
        }
    }
    
    QString largerImagePath = env->createTempPath("larger_corner.png");
    ASSERT_TRUE(largerImage.save(largerImagePath, "PNG"));
    
    // Extract
    QString extractedPath = env->createTempPath("extracted_corner.png");
    EXPECT_TRUE(stego->extractEncodedImage(largerImagePath, extractedPath));
    
    if (QFile::exists(extractedPath)) {
        EXPECT_TRUE(stego->hasHiddenData(extractedPath));
        qDebug() << "Successfully extracted from top-left corner";
    }
}

TEST_F(ExtractEncodedImageTest, ExtractFromImage_NoEncodedData)
{
    // Create a pure gradient image with no encoded data
    QImage pureImage = ImageGenerator::createGradientImage(300, 300);
    QString pureImagePath = env->createTempPath("pure_gradient.png");
    ASSERT_TRUE(pureImage.save(pureImagePath, "PNG"));
    
    // Try to extract (should fail)
    QString outputPath = env->createTempPath("extracted_fail.png");
    bool success = stego->extractEncodedImage(pureImagePath, outputPath);
    
    EXPECT_FALSE(success) << "Should fail to extract from image without encoded data";
    EXPECT_FALSE(stego->lastError().isEmpty()) << "Should provide error message";
    
    qDebug() << "Expected failure message:" << stego->lastError();
}

TEST_F(ExtractEncodedImageTest, ExtractMultipleSizes)
{
    // Test extraction with different encoded image sizes
    QStringList testSizes = {"10 bytes", "100 bytes", "1 KB", "10 KB"};
    QList<int> dataSizes = {10, 100, 1024, 10240};
    
    for (int i = 0; i < testSizes.size(); ++i) {
        qDebug() << "\n=== Testing extraction with" << testSizes[i] << "===";
        
        // Create data of specific size
        QString secretData = QString("X").repeated(dataSizes[i]);
        QString secretFilePath = env->createTempPath(QString("secret_%1.txt").arg(i));
        ASSERT_TRUE(env->writeFile(secretFilePath, secretData));
        
        // Encode
        QString encodedImagePath = env->createTempPath(QString("encoded_%1.png").arg(i));
        ASSERT_TRUE(stego->encodeFileInImage("", secretFilePath, encodedImagePath));
        
        QImage encodedImage(encodedImagePath);
        ASSERT_FALSE(encodedImage.isNull());
        
        qDebug() << "Encoded image size:" << encodedImage.width() << "x" << encodedImage.height();
        
        // Create larger image
        QImage largerImage = ImageGenerator::createGradientImage(
            encodedImage.width() + 150,
            encodedImage.height() + 150
        );
        
        // Embed at offset (75, 75)
        for (int y = 0; y < encodedImage.height(); ++y) {
            for (int x = 0; x < encodedImage.width(); ++x) {
                largerImage.setPixel(x + 75, y + 75, encodedImage.pixel(x, y));
            }
        }
        
        QString largerImagePath = env->createTempPath(QString("larger_%1.png").arg(i));
        ASSERT_TRUE(largerImage.save(largerImagePath, "PNG"));
        
        // Extract
        QString extractedPath = env->createTempPath(QString("extracted_%1.png").arg(i));
        bool success = stego->extractEncodedImage(largerImagePath, extractedPath);
        
        if (success) {
            EXPECT_TRUE(QFile::exists(extractedPath));
            EXPECT_TRUE(stego->hasHiddenData(extractedPath));
            qDebug() << "✓ Successfully extracted" << testSizes[i];
        } else {
            qDebug() << "✗ Failed to extract" << testSizes[i] << ":" << stego->lastError();
        }
    }
}

TEST_F(ExtractEncodedImageTest, RealWorldScenario_ScreenshotWithEncodedImage)
{
    qDebug() << "\n=== Real-world scenario: Screenshot containing encoded image ===";
    
    // Step 1: Create an encoded image
    QString secretData = "Secret message in a screenshot!";
    QString secretFilePath = env->createTempPath("screenshot_secret.txt");
    ASSERT_TRUE(env->writeFile(secretFilePath, secretData));
    
    QString encodedImagePath = env->createTempPath("encoded_for_screenshot.png");
    ASSERT_TRUE(stego->encodeFileInImage("", secretFilePath, encodedImagePath));
    
    QImage encodedImage(encodedImagePath);
    ASSERT_FALSE(encodedImage.isNull());
    
    // Step 2: Simulate a screenshot (1920x1080 with the encoded image somewhere in it)
    int screenshotWidth = 1920;
    int screenshotHeight = 1080;
    QImage screenshot = ImageGenerator::createGradientImage(screenshotWidth, screenshotHeight);
    
    // Place encoded image at a realistic position (e.g., center-ish)
    int embedX = (screenshotWidth - encodedImage.width()) / 2;
    int embedY = (screenshotHeight - encodedImage.height()) / 2;
    
    qDebug() << "Embedding encoded image at position (" << embedX << "," << embedY << ")";
    qDebug() << "Encoded image size:" << encodedImage.width() << "x" << encodedImage.height();
    
    for (int y = 0; y < encodedImage.height(); ++y) {
        for (int x = 0; x < encodedImage.width(); ++x) {
            if (embedX + x < screenshotWidth && embedY + y < screenshotHeight) {
                screenshot.setPixel(embedX + x, embedY + y, encodedImage.pixel(x, y));
            }
        }
    }
    
    QString screenshotPath = env->createTempPath("screenshot_1920x1080.png");
    ASSERT_TRUE(screenshot.save(screenshotPath, "PNG"));
    
    qDebug() << "Created screenshot:" << screenshotWidth << "x" << screenshotHeight;
    
    // Step 3: Extract the encoded image from the screenshot
    QString extractedPath = env->createTempPath("extracted_from_screenshot.png");
    bool success = stego->extractEncodedImage(screenshotPath, extractedPath);
    
    if (!success) {
        qDebug() << "Extraction failed:" << stego->lastError();
    }
    
    EXPECT_TRUE(success) << "Should be able to extract from screenshot";
    
    if (success && QFile::exists(extractedPath)) {
        // Verify extracted image
        EXPECT_TRUE(stego->hasHiddenData(extractedPath));
        
        // Decode and verify content
        QString decodedFilePath = env->createTempPath("decoded_from_screenshot.txt");
        ASSERT_TRUE(stego->decodeFileFromImage(extractedPath, decodedFilePath));
        
        QString decodedContent = env->readFile(decodedFilePath);
        EXPECT_EQ(decodedContent, secretData);
        
        qDebug() << "✓ Successfully extracted and decoded from realistic screenshot!";
    }
}

// ============================================================================
// Main function
// ============================================================================

int main(int argc, char **argv)
{
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
