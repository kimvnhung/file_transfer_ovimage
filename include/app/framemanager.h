#ifndef FRAMEMANAGER_H
#define FRAMEMANAGER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QByteArray>
#include "borderheader.h"

/**
 * FrameManager - Handles splitting/merging files across multiple 1000×1000 encoded frames
 * 
 * For files larger than ~726 KB, splits data into multiple frames.
 * Each frame is a separate 1000×1000 PNG with frame numbering in border header.
 */
class FrameManager
{
public:
    /**
     * Calculate number of frames needed for file
     * @param fileSize Total file size in bytes
     * @return Number of 1000×1000 frames required
     */
    static int calculateFrameCount(qint64 fileSize);
    
    /**
     * Split file data into frame chunks
     * @param fileData Complete file data
     * @return List of byte arrays, one per frame
     */
    static QList<QByteArray> splitIntoFrames(const QByteArray &fileData);
    
    /**
     * Merge frame data back into complete file
     * @param frameDataList List of data from each frame (in order)
     * @return Complete reassembled file data
     */
    static QByteArray mergeFrames(const QList<QByteArray> &frameDataList);
    
    /**
     * Generate output filename for a frame
     * @param originalName Original filename (e.g., "document.pdf")
     * @param frameNum Current frame number (1-based)
     * @param totalFrames Total number of frames
     * @return Frame filename (e.g., "document_frame_1_of_3.png")
     */
    static QString generateFrameFilename(const QString &originalName, int frameNum, int totalFrames);
    
    /**
     * Parse frame information from filename
     * @param frameFilename Filename like "document_frame_2_of_3.png"
     * @param frameNum Output: extracted frame number
     * @param totalFrames Output: extracted total frames
     * @param baseName Output: extracted base name
     * @return true if parsing succeeded
     */
    static bool parseFrameFilename(const QString &frameFilename, 
                                   int &frameNum, 
                                   int &totalFrames, 
                                   QString &baseName);
    
    /**
     * Find all frames for a multi-frame file in directory
     * @param directory Directory to search
     * @param baseName Base filename (without _frame_X_of_Y suffix)
     * @return List of frame files in order, or empty if incomplete
     */
    static QStringList findFrameSet(const QString &directory, const QString &baseName);
    
    /**
     * Validate that frame set is complete and in order
     * @param framePaths List of frame file paths
     * @return true if all frames present and sequential
     */
    static bool validateFrameSet(const QStringList &framePaths);
    
    /**
     * Get chunk size for frame data (capacity per frame)
     * @return Maximum bytes per frame (~744,000)
     */
    static qint64 getFrameCapacity();

private:
    static constexpr qint64 FRAME_CAPACITY = 744000;  // ~726 KB per frame (conservative)
};

#endif // FRAMEMANAGER_H
