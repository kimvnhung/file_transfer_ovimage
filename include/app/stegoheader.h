#ifndef STEGOHEADER_H
#define STEGOHEADER_H

#include <QString>
#include <QByteArray>

/**
 * @brief Handles steganography file header creation and parsing
 * 
 * Manages the header format that stores metadata about hidden files:
 * MAGIC(4) + VERSION(2) + FILENAME_LENGTH(2) + FILENAME + FILE_SIZE(8) + DATA
 */
class StegoHeader
{
public:
    /**
     * @brief Data structure representing a steganography header
     */
    struct Data {
        char magic[4] = {'S', 'T', 'E', 'G'};  // Magic number
        quint16 version = 1;
        quint16 filenameLength = 0;
        QString filename;
        qint64 fileSize = 0;
    };
    
    StegoHeader();
    
    /**
     * @brief Create header bytes from file information
     * @param filename Name of the file being hidden
     * @param fileSize Size of the file in bytes
     * @return Serialized header data
     */
    static QByteArray create(const QString &filename, qint64 fileSize);
    
    /**
     * @brief Parse header from byte array
     * @param data The data containing the header
     * @return Parsed header structure
     */
    static Data parse(const QByteArray &data);
    
    /**
     * @brief Check if data starts with valid magic bytes
     * @param data The data to check
     * @return true if magic bytes match "STEG"
     */
    static bool hasValidMagic(const QByteArray &data);
    
    /**
     * @brief Get approximate header size for a given filename
     * @param filename The filename
     * @return Estimated header size in bytes
     */
    static int estimateSize(const QString &filename);
    
private:
    static constexpr int MAGIC_SIZE = 4;
    static constexpr int VERSION_SIZE = 2;
    static constexpr int LENGTH_SIZE = 2;
    static constexpr int FILESIZE_SIZE = 8;
};

#endif // STEGOHEADER_H
