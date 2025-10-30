#include "steganography_v2.h"
#include "borderheader.h"
#include "framemanager.h"
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QUrl>
#include <QDebug>
#include <QCryptographicHash>

SteganographyV2::SteganographyV2(QObject *parent)
    : QObject(parent)
{
    m_maxCapacity = BorderHeader::calculateDataCapacity();
}

qint64 SteganographyV2::getFrameCapacity() const
{
    return FrameManager::getFrameCapacity();
}

int SteganographyV2::calculateRequiredFrames(const QString &fileUrl)
{
    QUrl url(fileUrl);
    QString filePath = url.isLocalFile() ? url.toLocalFile() : fileUrl;
    
    QFileInfo fileInfo(filePath);
    if (!fileInfo.exists()) {
        return 0;
    }
    
    return FrameManager::calculateFrameCount(fileInfo.size());
}

QImage SteganographyV2::createBlankFrame()
{
    // Create 1000×1000 gradient image for carrier
    QImage frame(IMAGE_SIZE, IMAGE_SIZE, QImage::Format_RGB888);
    
    for (int y = 0; y < IMAGE_SIZE; ++y) {
        for (int x = 0; x < IMAGE_SIZE; ++x) {
            int r = (x * 255) / IMAGE_SIZE;
            int g = (y * 255) / IMAGE_SIZE;
            int b = ((x + y) * 255) / (IMAGE_SIZE * 2);
            frame.setPixel(x, y, qRgb(r, g, b));
        }
    }
    
    return frame;
}

bool SteganographyV2::embedDataInFrame(QImage &frame, const QByteArray &data)
{
    if (frame.width() != IMAGE_SIZE || frame.height() != IMAGE_SIZE) {
        setLastError("Frame must be 1000×1000 pixels");
        return false;
    }
    
    // Data area is 996×996 (excluding 2-pixel border)
    qint64 dataAreaPixels = DATA_AREA_SIZE * DATA_AREA_SIZE;
    qint64 maxBytes = (dataAreaPixels * BITS_PER_PIXEL) / 8;
    
    if (data.size() > maxBytes) {
        setLastError(QString("Data too large: %1 bytes, max: %2 bytes")
                     .arg(data.size()).arg(maxBytes));
        return false;
    }
    
    // Embed data sequentially: 6 bits per pixel (2 bits per channel)
    int bitPos = 0;  // Current bit position in data stream
    int totalBits = data.size() * 8;
    
    for (int y = BORDER_WIDTH; y < IMAGE_SIZE - BORDER_WIDTH && bitPos < totalBits; ++y) {
        for (int x = BORDER_WIDTH; x < IMAGE_SIZE - BORDER_WIDTH && bitPos < totalBits; ++x) {
            QRgb pixel = frame.pixel(x, y);
            quint8 r = qRed(pixel);
            quint8 g = qGreen(pixel);
            quint8 b = qBlue(pixel);
            
            // Embed 2 bits in R channel
            if (bitPos < totalBits) {
                int byteIdx = bitPos / 8;
                int bitIdx = bitPos % 8;
                quint8 byte = static_cast<quint8>(data[byteIdx]);
                quint8 bits = (byte >> (6 - bitIdx)) & 0b11;
                r = (r & 0b11111100) | bits;
                bitPos += 2;
            }
            
            // Embed 2 bits in G channel
            if (bitPos < totalBits) {
                int byteIdx = bitPos / 8;
                int bitIdx = bitPos % 8;
                quint8 byte = static_cast<quint8>(data[byteIdx]);
                quint8 bits = (byte >> (6 - bitIdx)) & 0b11;
                g = (g & 0b11111100) | bits;
                bitPos += 2;
            }
            
            // Embed 2 bits in B channel
            if (bitPos < totalBits) {
                int byteIdx = bitPos / 8;
                int bitIdx = bitPos % 8;
                quint8 byte = static_cast<quint8>(data[byteIdx]);
                quint8 bits = (byte >> (6 - bitIdx)) & 0b11;
                b = (b & 0b11111100) | bits;
                bitPos += 2;
            }
            
            frame.setPixel(x, y, qRgb(r, g, b));
        }
    }
    
    return true;
}

QByteArray SteganographyV2::extractDataFromFrame(const QImage &frame)
{
    if (frame.width() != IMAGE_SIZE || frame.height() != IMAGE_SIZE) {
        qWarning() << "Frame must be 1000×1000 pixels";
        return QByteArray();
    }
    
    QByteArray result;
    qint64 dataAreaPixels = DATA_AREA_SIZE * DATA_AREA_SIZE;
    qint64 maxBytes = (dataAreaPixels * BITS_PER_PIXEL) / 8;
    result.reserve(maxBytes);
    
    // Extract bits sequentially
    QVector<bool> bits;
    bits.reserve(maxBytes * 8);
    
    for (int y = BORDER_WIDTH; y < IMAGE_SIZE - BORDER_WIDTH; ++y) {
        for (int x = BORDER_WIDTH; x < IMAGE_SIZE - BORDER_WIDTH; ++x) {
            QRgb pixel = frame.pixel(x, y);
            
            // Extract 2 bits from each channel
            quint8 rBits = qRed(pixel) & 0b11;
            quint8 gBits = qGreen(pixel) & 0b11;
            quint8 bBits = qBlue(pixel) & 0b11;
            
            // Add bits to stream
            bits.append((rBits & 0b10) != 0);
            bits.append((rBits & 0b01) != 0);
            bits.append((gBits & 0b10) != 0);
            bits.append((gBits & 0b01) != 0);
            bits.append((bBits & 0b10) != 0);
            bits.append((bBits & 0b01) != 0);
        }
    }
    
    // Convert bits to bytes
    for (int i = 0; i < bits.size(); i += 8) {
        if (i + 7 >= bits.size()) break;
        
        quint8 byte = 0;
        for (int j = 0; j < 8; ++j) {
            byte = (byte << 1) | (bits[i + j] ? 1 : 0);
        }
        result.append(static_cast<char>(byte));
    }
    
    return result;
}

QStringList SteganographyV2::encodeFileInFrames(const QString &fileUrl, 
                                                 const QString &outputDir,
                                                 const QString &baseName)
{
    m_isProcessing = true;
    emit isProcessingChanged();
    setProgress(0);
    
    QStringList generatedFrames;
    
    // Get file info first
    QUrl url(fileUrl);
    QString filePath = url.isLocalFile() ? url.toLocalFile() : fileUrl;
    QFileInfo fileInfo(filePath);
    
    if (!fileInfo.exists()) {
        setLastError("File does not exist: " + filePath);
        m_isProcessing = false;
        emit isProcessingChanged();
        emit encodeFailed(m_lastError);
        return generatedFrames;
    }
    
    qint64 fileSize = fileInfo.size();
    QString filename = fileInfo.fileName();
    QString extension = "." + fileInfo.suffix();
    
    // Calculate frame count without loading file
    int totalFrames = FrameManager::calculateFrameCount(fileSize);
    qint64 frameCapacity = FrameManager::getFrameCapacity();
    
    qDebug() << "SteganographyV2: Encoding" << fileSize << "bytes into" << totalFrames << "frame(s)";
    
    // Open file for reading
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        setLastError("Failed to open file: " + filePath);
        m_isProcessing = false;
        emit isProcessingChanged();
        emit encodeFailed(m_lastError);
        return generatedFrames;
    }
    
    setProgress(5);
    
    // Calculate checksum in chunks to avoid memory issues
    QCryptographicHash hash(QCryptographicHash::Md5);
    const qint64 chunkSize = 1024 * 1024; // 1MB chunks for hashing
    while (!file.atEnd()) {
        QByteArray chunk = file.read(chunkSize);
        hash.addData(chunk);
    }
    QByteArray checksum = hash.result();
    file.seek(0); // Reset to beginning
    
    setProgress(10);
    
    // Prepare output directory
    QUrl outDirUrl(outputDir);
    QString outDirPath = outDirUrl.isLocalFile() ? outDirUrl.toLocalFile() : outputDir;
    QDir dir(outDirPath);
    if (!dir.exists()) {
        if (!dir.mkpath(".")) {
            setLastError("Failed to create output directory: " + outDirPath);
            file.close();
            m_isProcessing = false;
            emit isProcessingChanged();
            emit encodeFailed(m_lastError);
            return generatedFrames;
        }
    }
    
    // Determine base name
    QString useBaseName = baseName.isEmpty() ? fileInfo.completeBaseName() : baseName;
    
    // Generate each frame by reading chunks from file
    for (int i = 0; i < totalFrames; ++i) {
        int progressStart = 10 + (i * 85 / totalFrames);
        setProgress(progressStart);
        
        // Read chunk for this frame (avoiding loading entire file)
        qint64 bytesToRead = qMin(frameCapacity, fileSize - file.pos());
        QByteArray frameData = file.read(bytesToRead);
        
        if (frameData.isEmpty() && bytesToRead > 0) {
            setLastError(QString("Failed to read data for frame %1").arg(i + 1));
            file.close();
            m_isProcessing = false;
            emit isProcessingChanged();
            emit encodeFailed(m_lastError);
            return QStringList();
        }
        
        // Create header
        BorderHeader::Data header = BorderHeader::createHeader(
            filename,
            extension,
            fileSize,
            i + 1,
            totalFrames,
            checksum
        );
        
        // Create blank frame
        QImage frame = createBlankFrame();
        
        // Encode header in border
        if (!BorderHeader::encodeToBorder(frame, header)) {
            setLastError(QString("Failed to encode header for frame %1").arg(i + 1));
            file.close();
            m_isProcessing = false;
            emit isProcessingChanged();
            emit encodeFailed(m_lastError);
            return QStringList();
        }
        
        // Embed data in frame
        if (!embedDataInFrame(frame, frameData)) {
            setLastError(QString("Failed to embed data in frame %1").arg(i + 1));
            file.close();
            m_isProcessing = false;
            emit isProcessingChanged();
            emit encodeFailed(m_lastError);
            return QStringList();
        }
        
        // Generate frame filename
        QString frameFilename = FrameManager::generateFrameFilename(useBaseName, i + 1, totalFrames);
        QString framePath = dir.filePath(frameFilename);
        
        // Save frame
        if (!frame.save(framePath, "PNG")) {
            setLastError(QString("Failed to save frame %1 to: %2").arg(i + 1).arg(framePath));
            file.close();
            m_isProcessing = false;
            emit isProcessingChanged();
            emit encodeFailed(m_lastError);
            return QStringList();
        }
        
        generatedFrames.append(framePath);
        emit frameGenerated(i + 1, totalFrames);
        
        qDebug() << "SteganographyV2: Generated frame" << (i + 1) << "/" << totalFrames 
                 << "(" << frameData.size() << "bytes):" << framePath;
    }
    
    file.close();
    
    setProgress(100);
    m_isProcessing = false;
    emit isProcessingChanged();
    emit encodeComplete(generatedFrames.join(", "), fileSize);
    
    return generatedFrames;
}

bool SteganographyV2::decodeFileFromFrames(const QStringList &frameUrls, const QString &outputUrl)
{
    m_isProcessing = true;
    emit isProcessingChanged();
    setProgress(0);
    
    if (frameUrls.isEmpty()) {
        setLastError("No frames provided");
        m_isProcessing = false;
        emit isProcessingChanged();
        emit decodeFailed(m_lastError);
        return false;
    }
    
    // Load and validate all frames
    QList<QImage> frames;
    QList<BorderHeader::Data> headers;
    
    for (int i = 0; i < frameUrls.size(); ++i) {
        QUrl url(frameUrls[i]);
        QString framePath = url.isLocalFile() ? url.toLocalFile() : frameUrls[i];
        
        QImage frame(framePath);
        if (frame.isNull()) {
            setLastError(QString("Failed to load frame %1: %2").arg(i + 1).arg(framePath));
            m_isProcessing = false;
            emit isProcessingChanged();
            emit decodeFailed(m_lastError);
            return false;
        }
        
        if (frame.width() != IMAGE_SIZE || frame.height() != IMAGE_SIZE) {
            setLastError(QString("Frame %1 is not 1000×1000: %2×%3")
                         .arg(i + 1).arg(frame.width()).arg(frame.height()));
            m_isProcessing = false;
            emit isProcessingChanged();
            emit decodeFailed(m_lastError);
            return false;
        }
        
        // Read header
        if (!BorderHeader::hasValidHeader(frame)) {
            setLastError(QString("Frame %1 does not have valid header").arg(i + 1));
            m_isProcessing = false;
            emit isProcessingChanged();
            emit decodeFailed(m_lastError);
            return false;
        }
        
        BorderHeader::Data header = BorderHeader::readFromBorder(frame);
        
        frames.append(frame);
        headers.append(header);
        
        qDebug() << "SteganographyV2: Loaded frame" << (i + 1) << ":" << header.filename 
                 << "frame" << header.currentFrame << "/" << header.totalFrames;
    }
    
    setProgress(20);
    
    // Validate frame consistency
    if (headers.size() != headers[0].totalFrames) {
        qWarning() << "SteganographyV2: Frame count mismatch: got" << headers.size() 
                   << "expected" << headers[0].totalFrames;
    }
    
    // Extract data from each frame
    QList<QByteArray> frameData;
    for (int i = 0; i < frames.size(); ++i) {
        int progressStart = 20 + (i * 60 / frames.size());
        setProgress(progressStart);
        
        QByteArray data = extractDataFromFrame(frames[i]);
        
        // Trim to expected size for this frame
        qint64 expectedSize = headers[i].totalDataLength;
        qint64 remainingBytes = expectedSize;
        
        for (int j = 0; j < i; ++j) {
            remainingBytes -= frameData[j].size();
        }
        
        qint64 frameSize = qMin(remainingBytes, (qint64)FrameManager::getFrameCapacity());
        data = data.left(frameSize);
        
        frameData.append(data);
        emit frameDecoded(i + 1, frames.size());
        
        qDebug() << "SteganographyV2: Extracted" << data.size() << "bytes from frame" << (i + 1);
    }
    
    setProgress(80);
    
    // Merge frames
    QByteArray completeData = FrameManager::mergeFrames(frameData);
    
    // Verify checksum if available
    if (headers[0].checksum.size() == 16) {
        QByteArray actualChecksum = QCryptographicHash::hash(completeData, QCryptographicHash::Md5);
        if (actualChecksum != headers[0].checksum) {
            qWarning() << "SteganographyV2: Checksum mismatch! Data may be corrupted";
            qWarning() << "Expected:" << headers[0].checksum.toHex();
            qWarning() << "Actual:" << actualChecksum.toHex();
        } else {
            qDebug() << "SteganographyV2: Checksum verified OK";
        }
    }
    
    setProgress(90);
    
    // Save output file
    QUrl outUrl(outputUrl);
    QString outputPath = outUrl.isLocalFile() ? outUrl.toLocalFile() : outputUrl;
    
    if (!writeFileData(outputPath, completeData)) {
        m_isProcessing = false;
        emit isProcessingChanged();
        emit decodeFailed(m_lastError);
        return false;
    }
    
    setProgress(100);
    m_isProcessing = false;
    emit isProcessingChanged();
    emit decodeComplete(outputPath, completeData.size());
    
    qDebug() << "SteganographyV2: Decoded" << completeData.size() << "bytes to:" << outputPath;
    return true;
}

QStringList SteganographyV2::extractEncodedFrames(const QString &largerImageUrl, const QString &outputDir)
{
    m_isProcessing = true;
    emit isProcessingChanged();
    setProgress(0);
    
    QStringList extractedFrames;
    
    // Load larger image
    QUrl url(largerImageUrl);
    QString imagePath = url.isLocalFile() ? url.toLocalFile() : largerImageUrl;
    QImage largeImage(imagePath);
    
    if (largeImage.isNull()) {
        setLastError("Failed to load image: " + imagePath);
        m_isProcessing = false;
        emit isProcessingChanged();
        return extractedFrames;
    }
    
    setProgress(10);
    
    // Prepare output directory
    QUrl outDirUrl(outputDir);
    QString outDirPath = outDirUrl.isLocalFile() ? outDirUrl.toLocalFile() : outputDir;
    QDir dir(outDirPath);
    if (!dir.exists()) {
        if (!dir.mkpath(".")) {
            setLastError("Failed to create output directory: " + outDirPath);
            m_isProcessing = false;
            emit isProcessingChanged();
            return extractedFrames;
        }
    }
    
    setProgress(20);
    
    // Scan for 1000×1000 regions with 1000px stride
    int frameCount = 0;
    int maxY = largeImage.height() - IMAGE_SIZE + 1;
    int maxX = largeImage.width() - IMAGE_SIZE + 1;
    int totalPositions = (maxY / IMAGE_SIZE + 1) * (maxX / IMAGE_SIZE + 1);
    int positionIndex = 0;
    
    qDebug() << "SteganographyV2: Scanning" << largeImage.width() << "×" << largeImage.height() 
             << "image for 1000×1000 frames";
    
    for (int y = 0; y <= maxY; y += IMAGE_SIZE) {
        for (int x = 0; x <= maxX; x += IMAGE_SIZE) {
            positionIndex++;
            int scanProgress = 20 + (positionIndex * 70 / totalPositions);
            setProgress(scanProgress);
            
            // Extract 1000×1000 region
            QImage region = largeImage.copy(x, y, IMAGE_SIZE, IMAGE_SIZE);
            
            // Check if it has valid header
            if (BorderHeader::hasValidHeader(region)) {
                BorderHeader::Data header = BorderHeader::readFromBorder(region);
                
                qDebug() << "SteganographyV2: Found encoded frame at (" << x << "," << y << "):"
                         << header.filename << "frame" << header.currentFrame << "/" << header.totalFrames;
                
                // Generate output filename
                QString outputFilename = QString("extracted_frame_%1_at_%2_%3.png")
                    .arg(++frameCount)
                    .arg(x)
                    .arg(y);
                QString outputPath = dir.filePath(outputFilename);
                
                // Save extracted frame
                if (region.save(outputPath, "PNG")) {
                    extractedFrames.append(outputPath);
                    qDebug() << "SteganographyV2: Extracted frame to:" << outputPath;
                } else {
                    qWarning() << "SteganographyV2: Failed to save frame to:" << outputPath;
                }
            }
        }
    }
    
    setProgress(100);
    m_isProcessing = false;
    emit isProcessingChanged();
    
    if (extractedFrames.isEmpty()) {
        setLastError("No encoded frames found in image");
    } else {
        qDebug() << "SteganographyV2: Extracted" << extractedFrames.size() << "frame(s)";
    }
    
    return extractedFrames;
}

bool SteganographyV2::isValidFrame(const QString &imageUrl)
{
    QUrl url(imageUrl);
    QString imagePath = url.isLocalFile() ? url.toLocalFile() : imageUrl;
    QImage image(imagePath);
    
    if (image.isNull()) {
        return false;
    }
    
    if (image.width() != IMAGE_SIZE || image.height() != IMAGE_SIZE) {
        return false;
    }
    
    return BorderHeader::hasValidHeader(image);
}

bool SteganographyV2::isValidFrameImage(const QImage &image)
{
    if (image.isNull()) {
        return false;
    }
    
    if (image.width() != IMAGE_SIZE || image.height() != IMAGE_SIZE) {
        return false;
    }
    
    return BorderHeader::hasValidHeader(image);
}

QString SteganographyV2::getFrameInfo(const QString &imageUrl)
{
    QUrl url(imageUrl);
    QString imagePath = url.isLocalFile() ? url.toLocalFile() : imageUrl;
    QImage image(imagePath);
    
    if (image.isNull()) {
        return "Error: Could not load image";
    }
    
    if (image.width() != IMAGE_SIZE || image.height() != IMAGE_SIZE) {
        return "Error: Image is not 1000×1000 pixels";
    }
    
    if (!BorderHeader::hasValidHeader(image)) {
        return "No valid frame header found";
    }
    
    BorderHeader::Data header = BorderHeader::readFromBorder(image);
    
    return QString("Filename: %1\n"
                   "Extension: %2\n"
                   "Total Size: %3 bytes\n"
                   "Frame: %4 of %5\n"
                   "Version: %6")
        .arg(header.filename)
        .arg(header.extension)
        .arg(header.totalDataLength)
        .arg(header.currentFrame)
        .arg(header.totalFrames)
        .arg(header.version);
}

// Legacy compatibility methods
bool SteganographyV2::encodeFileInImage(const QString &imageUrl, const QString &fileUrl, const QString &outputUrl)
{
    Q_UNUSED(imageUrl);  // Ignored in V2, always creates new frames
    
    // Determine output directory
    QUrl outUrl(outputUrl);
    QString outputPath = outUrl.isLocalFile() ? outUrl.toLocalFile() : outputUrl;
    QFileInfo outInfo(outputPath);
    
    QString outputDir;
    QString baseName;
    
    if (outInfo.isDir()) {
        outputDir = outputPath;
        QUrl fileUrl2(fileUrl);
        QString filePath = fileUrl2.isLocalFile() ? fileUrl2.toLocalFile() : fileUrl;
        baseName = QFileInfo(filePath).completeBaseName();
    } else {
        outputDir = outInfo.dir().path();
        baseName = outInfo.completeBaseName();
    }
    
    QStringList frames = encodeFileInFrames(fileUrl, outputDir, baseName);
    return !frames.isEmpty();
}

bool SteganographyV2::decodeFileFromImage(const QString &imageUrl, const QString &outputUrl)
{
    QStringList frameUrls;
    frameUrls << imageUrl;
    return decodeFileFromFrames(frameUrls, outputUrl);
}

// Helper methods
void SteganographyV2::setProgress(int progress)
{
    if (m_progress != progress) {
        m_progress = progress;
        emit progressChanged();
    }
}

void SteganographyV2::setLastError(const QString &error)
{
    if (m_lastError != error) {
        m_lastError = error;
        emit lastErrorChanged();
        qWarning() << "SteganographyV2 Error:" << error;
    }
}

void SteganographyV2::setMaxCapacity(qint64 capacity)
{
    if (m_maxCapacity != capacity) {
        m_maxCapacity = capacity;
        emit maxCapacityChanged();
    }
}

QByteArray SteganographyV2::readFileData(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        setLastError("Failed to open file: " + filePath);
        return QByteArray();
    }
    
    QByteArray data = file.readAll();
    file.close();
    
    return data;
}

bool SteganographyV2::writeFileData(const QString &filePath, const QByteArray &data)
{
    // Ensure directory exists
    QFileInfo fileInfo(filePath);
    QDir dir = fileInfo.dir();
    if (!dir.exists()) {
        if (!dir.mkpath(".")) {
            setLastError("Failed to create output directory: " + dir.path());
            return false;
        }
    }
    
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        setLastError("Failed to create file: " + filePath);
        return false;
    }
    
    qint64 written = file.write(data);
    file.close();
    
    if (written != data.size()) {
        setLastError(QString("Failed to write complete data: %1 of %2 bytes")
                     .arg(written).arg(data.size()));
        return false;
    }
    
    return true;
}
