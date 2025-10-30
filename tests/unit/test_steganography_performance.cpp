#include <gtest/gtest.h>
#include "steganography.h"
#include "../test_utils.h"
#include <QFile>

using namespace TestUtils;

/**
 * Performance benchmark tests for steganography operations
 */
class SteganographyPerformanceTest : public ::testing::Test {
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
    
    // Helper to measure encode/decode performance
    struct PerformanceMetrics {
        double encodeTimeMs;
        double decodeTimeMs;
        qint64 fileSize;
        int imageWidth;
        int imageHeight;
        double throughputMBps;
    };
    
    PerformanceMetrics measurePerformance(int width, int height, qint64 fileSize) {
        PerformanceMetrics metrics;
        metrics.imageWidth = width;
        metrics.imageHeight = height;
        metrics.fileSize = fileSize;
        
        // Create test data
        QImage carrierImage = ImageGenerator::createGradientImage(width, height);
        QString carrierPath = env->createTempPath("perf_carrier.png");
        carrierImage.save(carrierPath, "PNG");
        
        QByteArray testData = FileGenerator::createRandomData(fileSize);
        QString secretPath = FileGenerator::createTempFile(testData, ".bin");
        QString outputPath = env->createTempPath("perf_output.png");
        
        // Measure encode time
        PerformanceTimer encodeTimer;
        encodeTimer.start();
        bool encodeResult = stego->encodeFileInImage(carrierPath, secretPath, outputPath);
        metrics.encodeTimeMs = encodeTimer.elapsedMs();
        
        EXPECT_TRUE(encodeResult);
        
        // Measure decode time
        QString decodedPath = env->createTempPath("perf_decoded.bin");
        PerformanceTimer decodeTimer;
        decodeTimer.start();
        bool decodeResult = stego->decodeFileFromImage(outputPath, decodedPath);
        metrics.decodeTimeMs = decodeTimer.elapsedMs();
        
        EXPECT_TRUE(decodeResult);
        
        // Calculate throughput (MB/s)
        double totalTimeSeconds = (metrics.encodeTimeMs + metrics.decodeTimeMs) / 1000.0;
        double fileSizeMB = fileSize / (1024.0 * 1024.0);
        metrics.throughputMBps = (fileSizeMB * 2) / totalTimeSeconds; // 2x for encode + decode
        
        return metrics;
    }
};

// ============================================================================
// Performance Benchmarks
// ============================================================================

TEST_F(SteganographyPerformanceTest, Benchmark_SmallFile_100KB)
{
    int width = 400;
    int height = 400;
    qint64 fileSize = 100 * 1024; // 100 KB
    
    PerformanceMetrics metrics = measurePerformance(width, height, fileSize);
    
    std::cout << "\n=== Small File Benchmark (100 KB) ===" << std::endl;
    std::cout << "Image: " << width << "x" << height << std::endl;
    std::cout << "Encode time: " << metrics.encodeTimeMs << " ms" << std::endl;
    std::cout << "Decode time: " << metrics.decodeTimeMs << " ms" << std::endl;
    std::cout << "Total time: " << (metrics.encodeTimeMs + metrics.decodeTimeMs) << " ms" << std::endl;
    std::cout << "Throughput: " << metrics.throughputMBps << " MB/s" << std::endl;
    
    // Performance expectations (should complete in reasonable time)
    EXPECT_LT(metrics.encodeTimeMs, 2000); // Should encode in < 2 seconds
    EXPECT_LT(metrics.decodeTimeMs, 2000); // Should decode in < 2 seconds
}

TEST_F(SteganographyPerformanceTest, Benchmark_MediumFile_1MB)
{
    int width = 1000;
    int height = 1000;
    qint64 fileSize = 1024 * 1024; // 1 MB
    
    PerformanceMetrics metrics = measurePerformance(width, height, fileSize);
    
    std::cout << "\n=== Medium File Benchmark (1 MB) ===" << std::endl;
    std::cout << "Image: " << width << "x" << height << std::endl;
    std::cout << "Encode time: " << metrics.encodeTimeMs << " ms" << std::endl;
    std::cout << "Decode time: " << metrics.decodeTimeMs << " ms" << std::endl;
    std::cout << "Total time: " << (metrics.encodeTimeMs + metrics.decodeTimeMs) << " ms" << std::endl;
    std::cout << "Throughput: " << metrics.throughputMBps << " MB/s" << std::endl;
    
    EXPECT_LT(metrics.encodeTimeMs, 5000); // Should encode in < 5 seconds
    EXPECT_LT(metrics.decodeTimeMs, 5000); // Should decode in < 5 seconds
}

TEST_F(SteganographyPerformanceTest, Benchmark_LargeFile_5MB)
{
    int width = 2000;
    int height = 2000;
    qint64 fileSize = 5 * 1024 * 1024; // 5 MB
    
    PerformanceMetrics metrics = measurePerformance(width, height, fileSize);
    
    std::cout << "\n=== Large File Benchmark (5 MB) ===" << std::endl;
    std::cout << "Image: " << width << "x" << height << std::endl;
    std::cout << "Encode time: " << metrics.encodeTimeMs << " ms" << std::endl;
    std::cout << "Decode time: " << metrics.decodeTimeMs << " ms" << std::endl;
    std::cout << "Total time: " << (metrics.encodeTimeMs + metrics.decodeTimeMs) << " ms" << std::endl;
    std::cout << "Throughput: " << metrics.throughputMBps << " MB/s" << std::endl;
    
    EXPECT_LT(metrics.encodeTimeMs, 15000); // Should encode in < 15 seconds
    EXPECT_LT(metrics.decodeTimeMs, 15000); // Should decode in < 15 seconds
}

TEST_F(SteganographyPerformanceTest, Benchmark_TinyFile_1KB)
{
    int width = 100;
    int height = 100;
    qint64 fileSize = 1024; // 1 KB
    
    PerformanceMetrics metrics = measurePerformance(width, height, fileSize);
    
    std::cout << "\n=== Tiny File Benchmark (1 KB) ===" << std::endl;
    std::cout << "Image: " << width << "x" << height << std::endl;
    std::cout << "Encode time: " << metrics.encodeTimeMs << " ms" << std::endl;
    std::cout << "Decode time: " << metrics.decodeTimeMs << " ms" << std::endl;
    std::cout << "Total time: " << (metrics.encodeTimeMs + metrics.decodeTimeMs) << " ms" << std::endl;
    std::cout << "Throughput: " << metrics.throughputMBps << " MB/s" << std::endl;
    
    EXPECT_LT(metrics.encodeTimeMs, 500); // Very small file should be fast
    EXPECT_LT(metrics.decodeTimeMs, 500);
}

// ============================================================================
// Capacity vs Performance Tests
// ============================================================================

TEST_F(SteganographyPerformanceTest, Performance_ScalesWithImageSize)
{
    struct TestCase {
        int width;
        int height;
        qint64 fileSize;
    };
    
    std::vector<TestCase> testCases = {
        {200, 200, 10 * 1024},      // 200x200, 10KB
        {400, 400, 40 * 1024},      // 400x400, 40KB
        {800, 800, 160 * 1024},     // 800x800, 160KB
    };
    
    std::cout << "\n=== Performance Scaling Test ===" << std::endl;
    std::cout << "Image Size | File Size | Encode (ms) | Decode (ms) | Total (ms)" << std::endl;
    std::cout << "-----------|-----------|-------------|-------------|------------" << std::endl;
    
    double prevTotalTime = 0;
    for (const auto& testCase : testCases) {
        PerformanceMetrics metrics = measurePerformance(
            testCase.width, testCase.height, testCase.fileSize);
        
        double totalTime = metrics.encodeTimeMs + metrics.decodeTimeMs;
        
        std::cout << testCase.width << "x" << testCase.height << " | "
                  << (testCase.fileSize / 1024) << " KB | "
                  << metrics.encodeTimeMs << " | "
                  << metrics.decodeTimeMs << " | "
                  << totalTime << std::endl;
        
        // Performance should scale somewhat linearly with image size
        if (prevTotalTime > 0) {
            double scaleFactor = totalTime / prevTotalTime;
            // Allow for some variance, but should be roughly 4x (image is 4x larger)
            EXPECT_GT(scaleFactor, 2.0);  // At least 2x slower
            EXPECT_LT(scaleFactor, 8.0);  // But not more than 8x slower
        }
        
        prevTotalTime = totalTime;
    }
}

// ============================================================================
// Memory Efficiency Tests
// ============================================================================

TEST_F(SteganographyPerformanceTest, MemoryEfficiency_LargeFileHandling)
{
    // Test that we can handle relatively large files without issues
    int width = 1500;
    int height = 1500;
    
    qint64 capacity = stego->calculateCapacity(
        [&]() {
            QImage img = ImageGenerator::createGradientImage(width, height);
            QString path = env->createTempPath("capacity_test.png");
            img.save(path, "PNG");
            return path;
        }()
    );
    
    // Use 80% of capacity
    qint64 fileSize = static_cast<qint64>(capacity * 0.8);
    
    std::cout << "\n=== Memory Efficiency Test ===" << std::endl;
    std::cout << "Image capacity: " << (capacity / 1024) << " KB" << std::endl;
    std::cout << "File size: " << (fileSize / 1024) << " KB (80% of capacity)" << std::endl;
    
    PerformanceMetrics metrics = measurePerformance(width, height, fileSize);
    
    std::cout << "Encode time: " << metrics.encodeTimeMs << " ms" << std::endl;
    std::cout << "Decode time: " << metrics.decodeTimeMs << " ms" << std::endl;
    
    // Should complete without hanging or crashing
    EXPECT_TRUE(metrics.encodeTimeMs > 0);
    EXPECT_TRUE(metrics.decodeTimeMs > 0);
    EXPECT_LT(metrics.encodeTimeMs, 30000); // 30 second timeout
    EXPECT_LT(metrics.decodeTimeMs, 30000);
}

// ============================================================================
// Repeated Operations Test
// ============================================================================

TEST_F(SteganographyPerformanceTest, RepeatedOperations_ConsistentPerformance)
{
    int width = 300;
    int height = 300;
    qint64 fileSize = 50 * 1024; // 50 KB
    
    std::vector<double> encodeTimes;
    std::vector<double> decodeTimes;
    
    std::cout << "\n=== Repeated Operations Test (10 iterations) ===" << std::endl;
    
    for (int i = 0; i < 10; ++i) {
        PerformanceMetrics metrics = measurePerformance(width, height, fileSize);
        encodeTimes.push_back(metrics.encodeTimeMs);
        decodeTimes.push_back(metrics.decodeTimeMs);
    }
    
    // Calculate statistics
    double avgEncode = 0, avgDecode = 0;
    for (size_t i = 0; i < encodeTimes.size(); ++i) {
        avgEncode += encodeTimes[i];
        avgDecode += decodeTimes[i];
    }
    avgEncode /= encodeTimes.size();
    avgDecode /= decodeTimes.size();
    
    double maxEncode = *std::max_element(encodeTimes.begin(), encodeTimes.end());
    double minEncode = *std::min_element(encodeTimes.begin(), encodeTimes.end());
    double maxDecode = *std::max_element(decodeTimes.begin(), decodeTimes.end());
    double minDecode = *std::min_element(decodeTimes.begin(), decodeTimes.end());
    
    std::cout << "Encode - Avg: " << avgEncode << " ms, Min: " << minEncode 
              << " ms, Max: " << maxEncode << " ms" << std::endl;
    std::cout << "Decode - Avg: " << avgDecode << " ms, Min: " << minDecode 
              << " ms, Max: " << maxDecode << " ms" << std::endl;
    
    // Performance should be consistent (variation within 50%)
    EXPECT_LT(maxEncode, avgEncode * 1.5);
    EXPECT_GT(minEncode, avgEncode * 0.5);
    EXPECT_LT(maxDecode, avgDecode * 1.5);
    EXPECT_GT(minDecode, avgDecode * 0.5);
}

// ============================================================================
// Capacity Calculation Performance
// ============================================================================

TEST_F(SteganographyPerformanceTest, CapacityCalculation_FastOperation)
{
    std::vector<std::pair<int, int>> imageSizes = {
        {100, 100},
        {500, 500},
        {1000, 1000},
        {2000, 2000}
    };
    
    std::cout << "\n=== Capacity Calculation Performance ===" << std::endl;
    std::cout << "Image Size | Calculation Time (ms)" << std::endl;
    std::cout << "-----------|----------------------" << std::endl;
    
    for (const auto& size : imageSizes) {
        QImage image = ImageGenerator::createGradientImage(size.first, size.second);
        QString imagePath = env->createTempPath("capacity_test.png");
        image.save(imagePath, "PNG");
        
        PerformanceTimer timer;
        timer.start();
        qint64 capacity = stego->calculateCapacity(imagePath);
        double elapsed = timer.elapsedMs();
        
        std::cout << size.first << "x" << size.second << " | " << elapsed << std::endl;
        
        // Capacity calculation should be very fast (< 100ms even for large images)
        EXPECT_LT(elapsed, 100);
        EXPECT_GT(capacity, 0);
    }
}
