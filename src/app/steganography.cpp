#include "steganography.h"
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QUrl>
#include <QDebug>
#include <QDataStream>

Steganography::Steganography(QObject *parent)
    : QObject(parent)
{
}

qint64 Steganography::calculateCapacity(const QString &imageUrl)
{
    QUrl url(imageUrl);
    QString imagePath = url.isLocalFile() ? url.toLocalFile() : imageUrl;
    
    QImage image(imagePath);
    if (image.isNull()) {
        setLastError("Failed to load image");
        return 0;
    }
    
    // Calculate capacity: (width * height * 3 channels * 2 bits) / 8 bits per byte
    qint64 capacity = (image.width() * image.height() * BITS_PER_PIXEL * BITS_PER_CHANNEL) / 8;
    
    // Subtract header overhead (approximately 256 bytes for header)
    capacity -= 256;
    
    setMaxCapacity(capacity);
    return capacity;
}

bool Steganography::encodeFileInImage(const QString &imageUrl, const QString &fileUrl, const QString &outputUrl)
{
    m_isProcessing = true;
    emit isProcessingChanged();
    setProgress(0);
    
    // Load image
    QUrl imgUrl(imageUrl);
    QString imagePath = imgUrl.isLocalFile() ? imgUrl.toLocalFile() : imageUrl;
    QImage image(imagePath);
    
    if (image.isNull()) {
        setLastError("Failed to load image: " + imagePath);
        m_isProcessing = false;
        emit isProcessingChanged();
        emit encodeFailed(m_lastError);
        return false;
    }
    
    // Ensure RGB format
    if (image.format() != QImage::Format_RGB888 && 
        image.format() != QImage::Format_ARGB32) {
        image = image.convertToFormat(QImage::Format_RGB888);
    }
    
    setProgress(10);
    
    // Read file data
    QUrl fUrl(fileUrl);
    QString filePath = fUrl.isLocalFile() ? fUrl.toLocalFile() : fileUrl;
    QByteArray fileData = readFileData(filePath);
    
    if (fileData.isEmpty()) {
        setLastError("Failed to read file: " + filePath);
        m_isProcessing = false;
        emit isProcessingChanged();
        emit encodeFailed(m_lastError);
        return false;
    }
    
    setProgress(20);
    
    // Check capacity
    qint64 capacity = calculateCapacity(imageUrl);
    QFileInfo fileInfo(filePath);
    
    QByteArray header = createHeader(fileInfo.fileName(), fileData.size());
    QByteArray fullData = header + fileData;
    
    if (fullData.size() > capacity) {
        setLastError(QString("File too large. Need %1 bytes, capacity is %2 bytes")
                     .arg(fullData.size()).arg(capacity));
        m_isProcessing = false;
        emit isProcessingChanged();
        emit encodeFailed(m_lastError);
        return false;
    }
    
    setProgress(30);
    
    // Embed data
    if (!embedDataInImage(image, fullData)) {
        m_isProcessing = false;
        emit isProcessingChanged();
        emit encodeFailed(m_lastError);
        return false;
    }
    
    setProgress(80);
    
    // Save output image
    QUrl outUrl(outputUrl);
    QString outputPath = outUrl.isLocalFile() ? outUrl.toLocalFile() : outputUrl;
    
    if (!image.save(outputPath, "PNG")) {  // Use PNG to preserve data
        setLastError("Failed to save output image");
        m_isProcessing = false;
        emit isProcessingChanged();
        emit encodeFailed(m_lastError);
        return false;
    }
    
    setProgress(100);
    m_isProcessing = false;
    emit isProcessingChanged();
    emit encodeComplete(outputPath, fileData.size());
    
    qDebug() << "File encoded successfully:" << outputPath;
    return true;
}

bool Steganography::decodeFileFromImage(const QString &imageUrl, const QString &outputUrl)
{
    m_isProcessing = true;
    emit isProcessingChanged();
    setProgress(0);
    
    // Load image
    QUrl url(imageUrl);
    QString imagePath = url.isLocalFile() ? url.toLocalFile() : imageUrl;
    QImage image(imagePath);
    
    if (image.isNull()) {
        setLastError("Failed to load image");
        m_isProcessing = false;
        emit isProcessingChanged();
        emit decodeFailed(m_lastError);
        return false;
    }
    
    setProgress(20);
    
    // Extract data
    QByteArray extractedData = extractDataFromImage(image);
    
    if (extractedData.isEmpty()) {
        m_isProcessing = false;
        emit isProcessingChanged();
        emit decodeFailed(m_lastError);
        return false;
    }
    
    setProgress(60);
    
    // Parse header
    DataHeader header = parseHeader(extractedData);
    
    if (header.fileSize <= 0 || header.fileSize > extractedData.size()) {
        setLastError("Invalid header or corrupted data");
        m_isProcessing = false;
        emit isProcessingChanged();
        emit decodeFailed(m_lastError);
        return false;
    }
    
    setProgress(70);
    
    // Extract file data (skip header)
    int headerSize = 4 + 2 + 2 + header.filenameLength + 8; // magic + version + nameLen + name + size
    QByteArray fileData = extractedData.mid(headerSize, header.fileSize);
    
    // Save file
    QUrl outUrl(outputUrl);
    QString outputPath = outUrl.isLocalFile() ? outUrl.toLocalFile() : outputUrl;
    
    // If output path is a directory, use original filename
    QFileInfo outInfo(outputPath);
    if (outInfo.isDir() || outputPath.endsWith('/')) {
        outputPath = QDir(outputPath).filePath(header.filename);
    }
    
    if (!writeFileData(outputPath, fileData)) {
        m_isProcessing = false;
        emit isProcessingChanged();
        emit decodeFailed(m_lastError);
        return false;
    }
    
    setProgress(100);
    m_isProcessing = false;
    emit isProcessingChanged();
    emit decodeComplete(outputPath, fileData.size());
    
    qDebug() << "File decoded successfully:" << outputPath;
    return true;
}

bool Steganography::hasHiddenData(const QString &imageUrl)
{
    QUrl url(imageUrl);
    QString imagePath = url.isLocalFile() ? url.toLocalFile() : imageUrl;
    QImage image(imagePath);
    
    if (image.isNull()) {
        return false;
    }
    
    // Read first 4 bytes to check magic number
    QByteArray data = extractDataFromImage(image);
    if (data.size() < 4) {
        return false;
    }
    
    return (data[0] == 'S' && data[1] == 'T' && data[2] == 'E' && data[3] == 'G');
}

QString Steganography::getHiddenFileInfo(const QString &imageUrl)
{
    QUrl url(imageUrl);
    QString imagePath = url.isLocalFile() ? url.toLocalFile() : imageUrl;
    QImage image(imagePath);
    
    if (image.isNull()) {
        return "Error: Could not load image";
    }
    
    QByteArray data = extractDataFromImage(image);
    DataHeader header = parseHeader(data);
    
    if (header.fileSize <= 0) {
        return "No hidden data found";
    }
    
    return QString("Filename: %1\nSize: %2 bytes")
        .arg(header.filename)
        .arg(header.fileSize);
}

// Private helper methods

bool Steganography::embedDataInImage(QImage &image, const QByteArray &data)
{
    int dataIndex = 0;
    int bitIndex = 0;
    int width = image.width();
    int height = image.height();
    
    // Embed data length first (8 bytes)
    qint64 dataSize = data.size();
    QByteArray sizeData;
    QDataStream sizeStream(&sizeData, QIODevice::WriteOnly);
    sizeStream << dataSize;
    
    QByteArray fullData = sizeData + data;
    
    for (int y = 0; y < height && dataIndex < fullData.size(); ++y) {
        for (int x = 0; x < width && dataIndex < fullData.size(); ++x) {
            QRgb pixel = image.pixel(x, y);
            int r = qRed(pixel);
            int g = qGreen(pixel);
            int b = qBlue(pixel);
            
            // Embed 2 bits in each channel
            for (int channel = 0; channel < 3 && dataIndex < fullData.size(); ++channel) {
                for (int bit = 0; bit < BITS_PER_CHANNEL && dataIndex < fullData.size(); ++bit) {
                    int dataBit = (fullData[dataIndex] >> bitIndex) & 1;
                    
                    switch (channel) {
                    case 0: // Red
                        r = (r & ~(1 << bit)) | (dataBit << bit);
                        break;
                    case 1: // Green
                        g = (g & ~(1 << bit)) | (dataBit << bit);
                        break;
                    case 2: // Blue
                        b = (b & ~(1 << bit)) | (dataBit << bit);
                        break;
                    }
                    
                    bitIndex++;
                    if (bitIndex >= 8) {
                        bitIndex = 0;
                        dataIndex++;
                        if (dataIndex >= fullData.size()) {
                            break;
                        }
                    }
                }
            }
            
            image.setPixel(x, y, qRgb(r, g, b));
        }
        
        // Update progress
        int newProgress = 30 + (50 * y / height);
        if (newProgress != m_progress) {
            setProgress(newProgress);
        }
    }
    
    return true;
}

QByteArray Steganography::extractDataFromImage(const QImage &image)
{
    // First extract data size
    QByteArray sizeData;
    int dataIndex = 0;
    int bitIndex = 0;
    int width = image.width();
    int height = image.height();
    
    // Extract 8 bytes for size
    while (sizeData.size() < 8) {
        int x = dataIndex % width;
        int y = dataIndex / width;
        
        if (y >= height) {
            setLastError("Invalid image format");
            return QByteArray();
        }
        
        QRgb pixel = image.pixel(x, y);
        int r = qRed(pixel);
        int g = qGreen(pixel);
        int b = qBlue(pixel);
        
        uchar byte = 0;
        for (int channel = 0; channel < 3 && sizeData.size() < 8; ++channel) {
            for (int bit = 0; bit < BITS_PER_CHANNEL && sizeData.size() < 8; ++bit) {
                int value = 0;
                switch (channel) {
                case 0: value = (r >> bit) & 1; break;
                case 1: value = (g >> bit) & 1; break;
                case 2: value = (b >> bit) & 1; break;
                }
                
                byte |= (value << bitIndex);
                bitIndex++;
                
                if (bitIndex >= 8) {
                    sizeData.append(byte);
                    byte = 0;
                    bitIndex = 0;
                }
            }
        }
        dataIndex++;
    }
    
    // Parse data size
    QDataStream sizeStream(sizeData);
    qint64 dataSize;
    sizeStream >> dataSize;
    
    if (dataSize <= 0 || dataSize > 1024 * 1024 * 100) {  // Max 100MB
        setLastError("Invalid data size");
        return QByteArray();
    }
    
    // Extract actual data
    QByteArray result;
    result.reserve(dataSize);
    bitIndex = 0;
    uchar byte = 0;
    
    while (result.size() < dataSize) {
        int x = dataIndex % width;
        int y = dataIndex / width;
        
        if (y >= height) {
            setLastError("Incomplete data in image");
            return QByteArray();
        }
        
        QRgb pixel = image.pixel(x, y);
        int r = qRed(pixel);
        int g = qGreen(pixel);
        int b = qBlue(pixel);
        
        for (int channel = 0; channel < 3 && result.size() < dataSize; ++channel) {
            for (int bit = 0; bit < BITS_PER_CHANNEL && result.size() < dataSize; ++bit) {
                int value = 0;
                switch (channel) {
                case 0: value = (r >> bit) & 1; break;
                case 1: value = (g >> bit) & 1; break;
                case 2: value = (b >> bit) & 1; break;
                }
                
                byte |= (value << bitIndex);
                bitIndex++;
                
                if (bitIndex >= 8) {
                    result.append(byte);
                    byte = 0;
                    bitIndex = 0;
                }
            }
        }
        
        dataIndex++;
        
        // Update progress
        if (result.size() % 1024 == 0) {
            int newProgress = 20 + (40 * result.size() / dataSize);
            if (newProgress != m_progress) {
                setProgress(newProgress);
            }
        }
    }
    
    return result;
}

QByteArray Steganography::createHeader(const QString &filename, qint64 fileSize)
{
    QByteArray header;
    QDataStream stream(&header, QIODevice::WriteOnly);
    
    // Magic number
    stream.writeRawData("STEG", 4);
    
    // Version
    quint16 version = 1;
    stream << version;
    
    // Filename
    QByteArray filenameBytes = filename.toUtf8();
    quint16 filenameLength = filenameBytes.size();
    stream << filenameLength;
    stream.writeRawData(filenameBytes.constData(), filenameLength);
    
    // File size
    stream << fileSize;
    
    return header;
}

Steganography::DataHeader Steganography::parseHeader(const QByteArray &data)
{
    DataHeader header;
    
    if (data.size() < 16) {  // Minimum header size
        return header;
    }
    
    QDataStream stream(data);
    
    // Magic number
    char magic[4];
    stream.readRawData(magic, 4);
    if (magic[0] != 'S' || magic[1] != 'T' || magic[2] != 'E' || magic[3] != 'G') {
        header.fileSize = -1;  // Invalid
        return header;
    }
    
    // Version
    stream >> header.version;
    
    // Filename
    stream >> header.filenameLength;
    if (header.filenameLength > 0 && header.filenameLength < 256) {
        QByteArray filenameBytes;
        filenameBytes.resize(header.filenameLength);
        stream.readRawData(filenameBytes.data(), header.filenameLength);
        header.filename = QString::fromUtf8(filenameBytes);
    }
    
    // File size
    stream >> header.fileSize;
    
    return header;
}

QByteArray Steganography::readFileData(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        setLastError("Could not open file: " + filePath);
        return QByteArray();
    }
    
    return file.readAll();
}

bool Steganography::writeFileData(const QString &filePath, const QByteArray &data)
{
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        setLastError("Could not create output file: " + filePath);
        return false;
    }
    
    qint64 written = file.write(data);
    if (written != data.size()) {
        setLastError("Failed to write all data to file");
        return false;
    }
    
    return true;
}

void Steganography::setProgress(int value)
{
    if (m_progress != value) {
        m_progress = value;
        emit progressChanged();
    }
}

void Steganography::setLastError(const QString &error)
{
    m_lastError = error;
    emit lastErrorChanged();
    qWarning() << "Steganography error:" << error;
}

void Steganography::setMaxCapacity(qint64 capacity)
{
    if (m_maxCapacity != capacity) {
        m_maxCapacity = capacity;
        emit maxCapacityChanged();
    }
}
