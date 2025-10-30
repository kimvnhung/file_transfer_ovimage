#include "stegoheader.h"
#include <QDataStream>
#include <QIODevice>
#include <QDebug>

StegoHeader::StegoHeader()
{
}

QByteArray StegoHeader::create(const QString &filename, qint64 fileSize)
{
    QByteArray header;
    QDataStream stream(&header, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    
    // Magic bytes
    stream.writeRawData("STEG", MAGIC_SIZE);
    
    // Version
    quint16 version = 1;
    stream << version;
    
    // Filename
    QByteArray filenameBytes = filename.toUtf8();
    quint16 filenameLength = static_cast<quint16>(filenameBytes.size());
    stream << filenameLength;
    stream.writeRawData(filenameBytes.data(), filenameLength);
    
    // File size
    stream << fileSize;
    
    qDebug() << "Created header: magic=STEG, version=1, filename=" << filename 
             << "(" << filenameLength << "bytes), fileSize=" << fileSize;
    
    return header;
}

StegoHeader::Data StegoHeader::parse(const QByteArray &data)
{
    Data header;
    
    if (data.size() < MAGIC_SIZE + VERSION_SIZE + LENGTH_SIZE + FILESIZE_SIZE) {
        qDebug() << "Data too small for header";
        return header;
    }
    
    QDataStream stream(data);
    stream.setByteOrder(QDataStream::LittleEndian);
    
    // Magic bytes
    char magic[5] = {0};
    stream.readRawData(magic, MAGIC_SIZE);
    memcpy(header.magic, magic, MAGIC_SIZE);
    
    if (!hasValidMagic(data)) {
        qDebug() << "Invalid magic bytes";
        header.fileSize = -1;
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
    
    qDebug() << "Parsed header: filename=" << header.filename 
             << ", fileSize=" << header.fileSize;
    
    return header;
}

bool StegoHeader::hasValidMagic(const QByteArray &data)
{
    if (data.size() < MAGIC_SIZE) {
        return false;
    }
    
    return (data[0] == 'S' && data[1] == 'T' && data[2] == 'E' && data[3] == 'G');
}

int StegoHeader::estimateSize(const QString &filename)
{
    // MAGIC + VERSION + LENGTH + FILENAME + FILESIZE
    return MAGIC_SIZE + VERSION_SIZE + LENGTH_SIZE + filename.toUtf8().size() + FILESIZE_SIZE;
}
