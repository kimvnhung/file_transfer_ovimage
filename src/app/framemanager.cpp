#include "framemanager.h"
#include <QFileInfo>
#include <QDir>
#include <QDebug>
#include <QRegularExpression>
#include <cmath>

int FrameManager::calculateFrameCount(qint64 fileSize)
{
    if (fileSize <= 0) {
        return 0;
    }
    
    // Calculate frames needed
    int frames = static_cast<int>(std::ceil(static_cast<double>(fileSize) / FRAME_CAPACITY));
    
    qDebug() << "FrameManager: File size" << fileSize << "bytes requires" << frames << "frame(s)";
    return frames;
}

QList<QByteArray> FrameManager::splitIntoFrames(const QByteArray &fileData)
{
    QList<QByteArray> frames;
    
    if (fileData.isEmpty()) {
        qWarning() << "FrameManager: Cannot split empty data";
        return frames;
    }
    
    qint64 totalSize = fileData.size();
    int frameCount = calculateFrameCount(totalSize);
    
    qint64 offset = 0;
    for (int i = 0; i < frameCount; ++i) {
        qint64 chunkSize = qMin(FRAME_CAPACITY, totalSize - offset);
        QByteArray chunk = fileData.mid(offset, chunkSize);
        frames.append(chunk);
        
        qDebug() << "FrameManager: Frame" << (i + 1) << "/" << frameCount 
                 << "=" << chunk.size() << "bytes";
        
        offset += chunkSize;
    }
    
    qDebug() << "FrameManager: Split" << totalSize << "bytes into" << frames.size() << "frames";
    return frames;
}

QByteArray FrameManager::mergeFrames(const QList<QByteArray> &frameDataList)
{
    QByteArray result;
    
    if (frameDataList.isEmpty()) {
        qWarning() << "FrameManager: No frames to merge";
        return result;
    }
    
    // Calculate total size
    qint64 totalSize = 0;
    for (const QByteArray &frame : frameDataList) {
        totalSize += frame.size();
    }
    
    result.reserve(totalSize);
    
    // Merge all frames
    for (int i = 0; i < frameDataList.size(); ++i) {
        result.append(frameDataList[i]);
        qDebug() << "FrameManager: Merged frame" << (i + 1) << "/" << frameDataList.size()
                 << "(" << frameDataList[i].size() << "bytes)";
    }
    
    qDebug() << "FrameManager: Merged" << frameDataList.size() << "frames into" 
             << result.size() << "bytes";
    return result;
}

QString FrameManager::generateFrameFilename(const QString &originalName, int frameNum, int totalFrames)
{
    QFileInfo fileInfo(originalName);
    QString baseName = fileInfo.completeBaseName();  // Without extension
    
    if (totalFrames == 1) {
        // Single frame, use original name pattern
        return baseName + "_encoded.png";
    }
    
    // Multi-frame: basename_frame_N_of_M.png
    return QString("%1_frame_%2_of_%3.png")
        .arg(baseName)
        .arg(frameNum)
        .arg(totalFrames);
}

bool FrameManager::parseFrameFilename(const QString &frameFilename, 
                                     int &frameNum, 
                                     int &totalFrames, 
                                     QString &baseName)
{
    // Pattern: anything_frame_N_of_M.png
    QRegularExpression re("^(.+)_frame_(\\d+)_of_(\\d+)\\.png$");
    QRegularExpressionMatch match = re.match(frameFilename);
    
    if (!match.hasMatch()) {
        // Try single frame pattern: anything_encoded.png
        QRegularExpression singleRe("^(.+)_encoded\\.png$");
        QRegularExpressionMatch singleMatch = singleRe.match(frameFilename);
        
        if (singleMatch.hasMatch()) {
            baseName = singleMatch.captured(1);
            frameNum = 1;
            totalFrames = 1;
            return true;
        }
        
        return false;
    }
    
    baseName = match.captured(1);
    frameNum = match.captured(2).toInt();
    totalFrames = match.captured(3).toInt();
    
    qDebug() << "FrameManager: Parsed frame:" << baseName << "frame" << frameNum << "/" << totalFrames;
    return true;
}

QStringList FrameManager::findFrameSet(const QString &directory, const QString &baseName)
{
    QDir dir(directory);
    if (!dir.exists()) {
        qWarning() << "FrameManager: Directory does not exist:" << directory;
        return QStringList();
    }
    
    // Find all files matching pattern: baseName_frame_*_of_*.png
    QString pattern = baseName + "_frame_*_of_*.png";
    QStringList filters;
    filters << pattern;
    
    QStringList files = dir.entryList(filters, QDir::Files, QDir::Name);
    
    if (files.isEmpty()) {
        // Try single frame pattern
        QString singleFile = baseName + "_encoded.png";
        if (dir.exists(singleFile)) {
            QStringList result;
            result << dir.filePath(singleFile);
            return result;
        }
        
        qWarning() << "FrameManager: No frames found for base name:" << baseName;
        return QStringList();
    }
    
    // Convert to full paths
    QStringList fullPaths;
    for (const QString &file : files) {
        fullPaths << dir.filePath(file);
    }
    
    // Validate the set
    if (!validateFrameSet(fullPaths)) {
        qWarning() << "FrameManager: Frame set validation failed";
        return QStringList();
    }
    
    qDebug() << "FrameManager: Found complete frame set with" << fullPaths.size() << "frames";
    return fullPaths;
}

bool FrameManager::validateFrameSet(const QStringList &framePaths)
{
    if (framePaths.isEmpty()) {
        return false;
    }
    
    if (framePaths.size() == 1) {
        // Single frame is always valid
        return true;
    }
    
    // Parse all frame numbers
    QMap<int, QString> frameMap;  // frameNum -> path
    int expectedTotal = -1;
    QString expectedBase;
    
    for (const QString &path : framePaths) {
        QFileInfo fileInfo(path);
        QString filename = fileInfo.fileName();
        
        int frameNum, totalFrames;
        QString baseName;
        
        if (!parseFrameFilename(filename, frameNum, totalFrames, baseName)) {
            qWarning() << "FrameManager: Could not parse frame filename:" << filename;
            return false;
        }
        
        // Check consistency
        if (expectedTotal == -1) {
            expectedTotal = totalFrames;
            expectedBase = baseName;
        } else {
            if (totalFrames != expectedTotal) {
                qWarning() << "FrameManager: Inconsistent total frames:" << totalFrames << "vs" << expectedTotal;
                return false;
            }
            if (baseName != expectedBase) {
                qWarning() << "FrameManager: Inconsistent base name:" << baseName << "vs" << expectedBase;
                return false;
            }
        }
        
        frameMap[frameNum] = path;
    }
    
    // Check that all frames are present (1 to expectedTotal)
    if (frameMap.size() != expectedTotal) {
        qWarning() << "FrameManager: Missing frames, expected" << expectedTotal << "got" << frameMap.size();
        return false;
    }
    
    for (int i = 1; i <= expectedTotal; ++i) {
        if (!frameMap.contains(i)) {
            qWarning() << "FrameManager: Missing frame number" << i;
            return false;
        }
    }
    
    qDebug() << "FrameManager: Frame set validated:" << expectedTotal << "frames complete";
    return true;
}

qint64 FrameManager::getFrameCapacity()
{
    return FRAME_CAPACITY;
}
