#ifndef STEGANOGRAPHY_H
#define STEGANOGRAPHY_H

#include <QObject>
#include <QImage>
#include <QByteArray>
#include <QString>
#include <QQmlEngine>

/**
 * Steganography class for hiding and extracting data in/from images
 * Uses LSB (Least Significant Bit) technique for data hiding
 */
class Steganography : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    
    Q_PROPERTY(bool isProcessing READ isProcessing NOTIFY isProcessingChanged)
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(qint64 maxCapacity READ maxCapacity NOTIFY maxCapacityChanged)
    
public:
    explicit Steganography(QObject *parent = nullptr);
    
    bool isProcessing() const { return m_isProcessing; }
    int progress() const { return m_progress; }
    QString lastError() const { return m_lastError; }
    qint64 maxCapacity() const { return m_maxCapacity; }
    
    // Encode: Hide file data in image
    Q_INVOKABLE bool encodeFileInImage(const QString &imageUrl, 
                                       const QString &fileUrl, 
                                       const QString &outputUrl);
    
    // Decode: Extract hidden data from image
    Q_INVOKABLE bool decodeFileFromImage(const QString &imageUrl, 
                                         const QString &outputUrl);
    
    // Calculate maximum bytes that can be hidden in an image
    Q_INVOKABLE qint64 calculateCapacity(const QString &imageUrl);
    
    // Check if image contains hidden data
    Q_INVOKABLE bool hasHiddenData(const QString &imageUrl);
    
    // Get info about hidden data without extracting
    Q_INVOKABLE QString getHiddenFileInfo(const QString &imageUrl);
    
signals:
    void isProcessingChanged();
    void progressChanged();
    void lastErrorChanged();
    void maxCapacityChanged();
    void encodeComplete(const QString &outputPath, qint64 fileSize);
    void decodeComplete(const QString &outputPath, qint64 fileSize);
    void encodeFailed(const QString &error);
    void decodeFailed(const QString &error);
    
private:
    // LSB encoding/decoding helpers
    bool embedDataInImage(QImage &image, const QByteArray &data);
    QByteArray extractDataFromImage(const QImage &image);
    
    // File operations
    QByteArray readFileData(const QString &filePath);
    bool writeFileData(const QString &filePath, const QByteArray &data);
    
    // Header format: MAGIC(4) + VERSION(2) + FILENAME_LENGTH(2) + FILENAME + FILE_SIZE(8) + DATA
    struct DataHeader {
        char magic[4] = {'S', 'T', 'E', 'G'};  // Magic number
        quint16 version = 1;
        quint16 filenameLength = 0;
        QString filename;
        qint64 fileSize = 0;
    };
    
    QByteArray createHeader(const QString &filename, qint64 fileSize);
    DataHeader parseHeader(const QByteArray &data);
    
    void setProgress(int value);
    void setLastError(const QString &error);
    void setMaxCapacity(qint64 capacity);
    
    bool m_isProcessing = false;
    int m_progress = 0;
    QString m_lastError;
    qint64 m_maxCapacity = 0;
    
    static constexpr int BITS_PER_PIXEL = 3;  // RGB channels
    static constexpr int BITS_PER_CHANNEL = 2; // Use 2 LSBs per channel for better capacity
};

#endif // STEGANOGRAPHY_H
