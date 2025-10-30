#ifndef LSBCODEC_H
#define LSBCODEC_H

#include <QImage>
#include <QByteArray>

/**
 * @brief LSB (Least Significant Bit) encoder/decoder
 * 
 * Handles the low-level bit manipulation for hiding data in images
 * using the Least Significant Bit steganography technique.
 */
class LSBCodec
{
public:
    LSBCodec();
    
    /**
     * @brief Embed data into image using LSB technique
     * @param image The carrier image (will be modified)
     * @param data The data to embed
     * @return true if successful, false otherwise
     */
    bool embedData(QImage &image, const QByteArray &data);
    
    /**
     * @brief Extract data from image using LSB technique
     * @param image The image containing hidden data
     * @return The extracted data
     */
    QByteArray extractData(const QImage &image);
    
    /**
     * @brief Calculate maximum capacity of an image
     * @param imageSize Size of the image (width * height)
     * @return Maximum bytes that can be hidden
     */
    static qint64 calculateCapacity(int imageSize);
    
    // Configuration constants
    static constexpr int BITS_PER_PIXEL = 3;      // RGB channels
    static constexpr int BITS_PER_CHANNEL = 2;    // Use 2 LSBs per channel
    
private:
    int m_progress = 0;
};

#endif // LSBCODEC_H
