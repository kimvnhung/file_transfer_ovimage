#include "test_utils.h"
#include <QRandomGenerator>
#include <QFile>
#include <QDateTime>
#include <QElapsedTimer>
#include <cmath>

namespace TestUtils {

// ============================================================================
// ImageGenerator Implementation
// ============================================================================

QImage ImageGenerator::createSolidColorImage(int width, int height, QRgb color)
{
    QImage image(width, height, QImage::Format_RGB888);
    image.fill(color);
    return image;
}

QImage ImageGenerator::createGradientImage(int width, int height)
{
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

QImage ImageGenerator::createRandomNoiseImage(int width, int height)
{
    QImage image(width, height, QImage::Format_RGB888);
    auto *rng = QRandomGenerator::global();
    
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            int r = rng->bounded(256);
            int g = rng->bounded(256);
            int b = rng->bounded(256);
            image.setPixel(x, y, qRgb(r, g, b));
        }
    }
    
    return image;
}

QImage ImageGenerator::createCheckerboardImage(int width, int height, int squareSize)
{
    QImage image(width, height, QImage::Format_RGB888);
    
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            bool isBlack = ((x / squareSize) + (y / squareSize)) % 2 == 0;
            image.setPixel(x, y, isBlack ? qRgb(0, 0, 0) : qRgb(255, 255, 255));
        }
    }
    
    return image;
}

QImage ImageGenerator::createImageForCapacity(int bytesCapacity)
{
    // Calculate dimensions needed
    // capacity = (width * height * 3 * 2) / 8
    // capacity * 8 / 6 = width * height
    int pixels = (bytesCapacity * 8 + 256 * 8) / 6; // Add header overhead
    int width = static_cast<int>(std::sqrt(pixels));
    int height = (pixels + width - 1) / width; // Round up
    
    return createGradientImage(width, height);
}

// ============================================================================
// FileGenerator Implementation
// ============================================================================

QByteArray FileGenerator::createRandomData(int size)
{
    QByteArray data;
    data.resize(size);
    auto *rng = QRandomGenerator::global();
    
    for (int i = 0; i < size; ++i) {
        data[i] = static_cast<char>(rng->bounded(256));
    }
    
    return data;
}

QByteArray FileGenerator::createTextData(const QString &text)
{
    return text.toUtf8();
}

QByteArray FileGenerator::createPatternData(int size, unsigned char pattern)
{
    QByteArray data;
    data.resize(size);
    data.fill(static_cast<char>(pattern));
    return data;
}

QByteArray FileGenerator::createSequentialData(int size)
{
    QByteArray data;
    data.resize(size);
    
    for (int i = 0; i < size; ++i) {
        data[i] = static_cast<char>(i % 256);
    }
    
    return data;
}

QString FileGenerator::createTempFile(const QByteArray &data, const QString &suffix)
{
    QTemporaryFile tempFile(QDir::tempPath() + "/test_XXXXXX" + suffix);
    tempFile.setAutoRemove(false); // Keep file for test
    
    if (tempFile.open()) {
        tempFile.write(data);
        tempFile.close();
        return tempFile.fileName();
    }
    
    return QString();
}

// ============================================================================
// Validator Implementation
// ============================================================================

bool Validator::compareBytes(const QByteArray &a, const QByteArray &b)
{
    if (a.size() != b.size()) {
        return false;
    }
    
    return a == b;
}

bool Validator::imagesVisuallySimilar(const QImage &a, const QImage &b, double threshold)
{
    if (a.size() != b.size()) {
        return false;
    }
    
    int width = a.width();
    int height = a.height();
    long long totalDiff = 0;
    long long maxDiff = 255LL * 3 * width * height; // Max possible difference
    
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            QRgb pixelA = a.pixel(x, y);
            QRgb pixelB = b.pixel(x, y);
            
            int diffR = std::abs(qRed(pixelA) - qRed(pixelB));
            int diffG = std::abs(qGreen(pixelA) - qGreen(pixelB));
            int diffB = std::abs(qBlue(pixelA) - qBlue(pixelB));
            
            totalDiff += diffR + diffG + diffB;
        }
    }
    
    double normalizedDiff = static_cast<double>(totalDiff) / maxDiff;
    return normalizedDiff <= threshold;
}

double Validator::calculatePSNR(const QImage &original, const QImage &modified)
{
    if (original.size() != modified.size()) {
        return 0.0;
    }
    
    int width = original.width();
    int height = original.height();
    double mse = 0.0;
    
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            QRgb pixelOrig = original.pixel(x, y);
            QRgb pixelMod = modified.pixel(x, y);
            
            int diffR = qRed(pixelOrig) - qRed(pixelMod);
            int diffG = qGreen(pixelOrig) - qGreen(pixelMod);
            int diffB = qBlue(pixelOrig) - qBlue(pixelMod);
            
            mse += diffR * diffR + diffG * diffG + diffB * diffB;
        }
    }
    
    mse /= (width * height * 3.0);
    
    if (mse == 0.0) {
        return 100.0; // Perfect match
    }
    
    double psnr = 10.0 * std::log10((255.0 * 255.0) / mse);
    return psnr;
}

bool Validator::isValidImage(const QImage &image)
{
    return !image.isNull() && image.width() > 0 && image.height() > 0;
}

bool Validator::hasExpectedDimensions(const QImage &image, int width, int height)
{
    return image.width() == width && image.height() == height;
}

// ============================================================================
// TestEnvironment Implementation
// ============================================================================

TestEnvironment::TestEnvironment()
{
    m_tempDir = new QTemporaryDir();
}

TestEnvironment::~TestEnvironment()
{
    delete m_tempDir;
}

QString TestEnvironment::createTempPath(const QString &filename) const
{
    return m_tempDir->filePath(filename);
}

// ============================================================================
// PerformanceTimer Implementation
// ============================================================================

PerformanceTimer::PerformanceTimer()
    : m_startTime(0)
{
}

void PerformanceTimer::start()
{
    m_startTime = QDateTime::currentMSecsSinceEpoch();
}

double PerformanceTimer::elapsedMs() const
{
    return static_cast<double>(QDateTime::currentMSecsSinceEpoch() - m_startTime);
}

double PerformanceTimer::elapsedSeconds() const
{
    return elapsedMs() / 1000.0;
}

} // namespace TestUtils
