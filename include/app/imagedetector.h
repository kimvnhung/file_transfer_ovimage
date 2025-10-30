#ifndef IMAGEDETECTOR_H
#define IMAGEDETECTOR_H

#include <QImage>
#include <QRect>

/**
 * @brief Detects encoded regions within larger images
 * 
 * Provides methods to find encoded steganography images embedded
 * in larger carrier images using border patterns and header detection.
 */
class ImageDetector
{
public:
    ImageDetector();
    
    /**
     * @brief Find encoded region within a larger image
     * @param image The larger image to search
     * @return Rectangle containing the encoded region, or empty if not found
     */
    QRect findEncodedRegion(const QImage &image);
    
    /**
     * @brief Detect border pattern at specific position
     * @param image The image to check
     * @param x Starting X coordinate
     * @param y Starting Y coordinate
     * @param width Output: detected width
     * @param height Output: detected height
     * @return true if border pattern detected
     */
    bool detectBorderPattern(const QImage &image, int x, int y, int &width, int &height);
    
    /**
     * @brief Check if there's a valid steganography header at position
     * @param image The image to check
     * @param startX Starting X coordinate
     * @param startY Starting Y coordinate
     * @param width Output: detected width
     * @param height Output: detected height
     * @return true if valid header found
     */
    bool hasValidHeaderAt(const QImage &image, int startX, int startY, int &width, int &height);
    
    /**
     * @brief Add detectable border to an encoded image
     * @param image The image to add border to (will be modified)
     */
    static void addDetectableBorder(QImage &image);
    
private:
    int m_progress = 0;
};

#endif // IMAGEDETECTOR_H
