#ifndef TEST_UTILS_H
#define TEST_UTILS_H

#include <QImage>
#include <QByteArray>
#include <QString>
#include <QTemporaryFile>
#include <QTemporaryDir>
#include <opencv2/opencv.hpp>

namespace TestUtils {

/**
 * Generate a test image with specified dimensions and pattern
 */
class ImageGenerator {
public:
    static QImage createSolidColorImage(int width, int height, QRgb color);
    static QImage createGradientImage(int width, int height);
    static QImage createRandomNoiseImage(int width, int height);
    static QImage createCheckerboardImage(int width, int height, int squareSize);
    
    // Create images of specific sizes for capacity testing
    static QImage createImageForCapacity(int bytesCapacity);
};

/**
 * Generate test files with various content
 */
class FileGenerator {
public:
    static QByteArray createRandomData(int size);
    static QByteArray createTextData(const QString &text);
    static QByteArray createPatternData(int size, unsigned char pattern);
    static QByteArray createSequentialData(int size); // 0,1,2,3...255,0,1,2...
    
    // Create temporary file and return path
    static QString createTempFile(const QByteArray &data, const QString &suffix = ".bin");
};

/**
 * Comparison and validation utilities
 */
class Validator {
public:
    // Compare two byte arrays
    static bool compareBytes(const QByteArray &a, const QByteArray &b);
    
    // Check if two images are visually similar (allow small LSB differences)
    static bool imagesVisuallySimilar(const QImage &a, const QImage &b, double threshold = 0.01);
    
    // Calculate PSNR (Peak Signal-to-Noise Ratio) between images
    static double calculatePSNR(const QImage &original, const QImage &modified);
    
    // Validate image format and properties
    static bool isValidImage(const QImage &image);
    static bool hasExpectedDimensions(const QImage &image, int width, int height);
};

/**
 * Test fixture helper for temporary directories
 */
class TestEnvironment {
public:
    TestEnvironment();
    ~TestEnvironment();
    
    QString getTempDir() const { return m_tempDir->path(); }
    QString createTempPath(const QString &filename) const;
    
private:
    QTemporaryDir *m_tempDir;
};

/**
 * Performance measurement utilities
 */
class PerformanceTimer {
public:
    PerformanceTimer();
    void start();
    double elapsedMs() const;
    double elapsedSeconds() const;
    
private:
    qint64 m_startTime;
};

} // namespace TestUtils

#endif // TEST_UTILS_H
