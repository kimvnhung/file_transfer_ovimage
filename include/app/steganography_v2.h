#ifndef STEGANOGRAPHY_V2_H
#define STEGANOGRAPHY_V2_H

#include <QObject>
#include <QImage>
#include <QByteArray>
#include <QString>
#include <QQmlEngine>
#include "borderheader.h"
#include "framemanager.h"

/**
 * Steganography V2 - Uses fixed 1000×1000 format with border headers
 * 
 * New features:
 * - Fixed 1000×1000 image size
 * - Header in 2-pixel border (visible, not LSB-encoded)
 * - Multi-frame support for large files
 * - Position-independent detection
 * - Fast header validation (no LSB scanning)
 */
class SteganographyV2 : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    
    Q_PROPERTY(bool isProcessing READ isProcessing NOTIFY isProcessingChanged)
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(qint64 maxCapacity READ maxCapacity NOTIFY maxCapacityChanged)
    
public:
    explicit SteganographyV2(QObject *parent = nullptr);
    
    bool isProcessing() const { return m_isProcessing; }
    int progress() const { return m_progress; }
    QString lastError() const { return m_lastError; }
    qint64 maxCapacity() const { return m_maxCapacity; }
    
    // Constants for new format
    static constexpr int IMAGE_SIZE = 1000;
    static constexpr int BORDER_WIDTH = 2;
    static constexpr int DATA_AREA_SIZE = 996;
    static constexpr int BITS_PER_PIXEL = 6;  // 2 bits per channel × 3 channels
    
    /**
     * Encode file into one or more 1000×1000 frames
     * @param fileUrl File to encode
     * @param outputDir Directory to save frame(s)
     * @param baseName Base name for output files (optional, uses original name if empty)
     * @return List of generated frame URLs, empty on failure
     */
    Q_INVOKABLE QStringList encodeFileInFrames(const QString &fileUrl, 
                                                const QString &outputDir,
                                                const QString &baseName = QString());
    
    /**
     * Decode file from one or more 1000×1000 frames
     * @param frameUrls List of frame URLs (can be single frame)
     * @param outputUrl Output file path
     * @return true if successful
     */
    Q_INVOKABLE bool decodeFileFromFrames(const QStringList &frameUrls, 
                                           const QString &outputUrl);
    
    /**
     * Extract all 1000×1000 encoded regions from a larger image
     * @param largerImageUrl URL of larger image containing encoded regions
     * @param outputDir Directory to save extracted frames
     * @return List of extracted frame URLs, empty on failure
     */
    Q_INVOKABLE QStringList extractEncodedFrames(const QString &largerImageUrl,
                                                  const QString &outputDir);
    
    /**
     * Get capacity for single frame (996×996 data area)
     * @return Maximum bytes per frame (~744 KB)
     */
    Q_INVOKABLE qint64 getFrameCapacity() const;
    
    /**
     * Calculate number of frames needed for file
     * @param fileUrl File to check
     * @return Number of frames required
     */
    Q_INVOKABLE int calculateRequiredFrames(const QString &fileUrl);
    
    /**
     * Check if image is a valid 1000×1000 encoded frame
     * @param imageUrl Image to check
     * @return true if valid frame detected
     */
    Q_INVOKABLE bool isValidFrame(const QString &imageUrl);
    
    /**
     * Check if QImage is a valid 1000×1000 encoded frame (direct image check)
     * @param image QImage to check
     * @return true if valid frame detected
     */
    Q_INVOKABLE bool isValidFrameImage(const QImage &image);
    
    /**
     * Get frame info without decoding
     * @param imageUrl Frame image URL
     * @return Frame information string
     */
    Q_INVOKABLE QString getFrameInfo(const QString &imageUrl);
    
    /**
     * Legacy compatibility: Encode single file (auto-determines frames)
     * @param imageUrl Ignored (always creates new frames)
     * @param fileUrl File to encode
     * @param outputUrl Output path (if single frame) or directory
     * @return true if successful
     */
    Q_INVOKABLE bool encodeFileInImage(const QString &imageUrl,
                                        const QString &fileUrl,
                                        const QString &outputUrl);
    
    /**
     * Legacy compatibility: Decode from single frame
     * @param imageUrl Frame image URL
     * @param outputUrl Output file path
     * @return true if successful
     */
    Q_INVOKABLE bool decodeFileFromImage(const QString &imageUrl,
                                          const QString &outputUrl);

signals:
    void isProcessingChanged();
    void progressChanged();
    void lastErrorChanged();
    void maxCapacityChanged();
    
    void encodeComplete(const QString &outputPath, qint64 fileSize);
    void encodeFailed(const QString &error);
    
    void decodeComplete(const QString &outputPath, qint64 fileSize);
    void decodeFailed(const QString &error);
    
    void frameGenerated(int frameNum, int totalFrames);
    void frameDecoded(int frameNum, int totalFrames);

private:
    bool m_isProcessing = false;
    int m_progress = 0;
    QString m_lastError;
    qint64 m_maxCapacity = 0;
    
    // LSB embedding/extraction methods
    bool embedDataInFrame(QImage &frame, const QByteArray &data);
    QByteArray extractDataFromFrame(const QImage &frame);
    
    // Frame creation
    QImage createBlankFrame();
    
    // Helper methods
    void setProgress(int progress);
    void setLastError(const QString &error);
    void setMaxCapacity(qint64 capacity);
    
    QByteArray readFileData(const QString &filePath);
    bool writeFileData(const QString &filePath, const QByteArray &data);
};

#endif // STEGANOGRAPHY_V2_H
