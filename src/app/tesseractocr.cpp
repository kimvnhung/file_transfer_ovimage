#include "tesseractocr.h"
#include <QDebug>
#include <QFile>

TesseractOCR::TesseractOCR(QObject *parent)
    : QObject(parent)
#ifdef USE_TESSERACT
    , m_tesseract(nullptr)
#endif
    , m_language("eng")
    , m_initialized(false)
{
#ifdef USE_TESSERACT
    m_tesseract = new tesseract::TessBaseAPI();
#else
    qWarning() << "Tesseract OCR is not available in this build";
#endif
}

TesseractOCR::~TesseractOCR()
{
#ifdef USE_TESSERACT
    if (m_tesseract) {
        m_tesseract->End();
        delete m_tesseract;
    }
#endif
}

void TesseractOCR::setLanguage(const QString &lang)
{
    if (m_language != lang) {
        m_language = lang;
        emit languageChanged();
        
        // Reinitialize if already initialized
        if (m_initialized) {
            initialize();
        }
    }
}

bool TesseractOCR::initialize()
{
#ifdef USE_TESSERACT
    // Set tessdata path
    const char* tessdata_path = "/usr/share/tesseract-ocr/5/tessdata";
    
    if (m_tesseract->Init(tessdata_path, m_language.toStdString().c_str())) {
        setLastError("Failed to initialize Tesseract with language: " + m_language);
        m_initialized = false;
        emit isInitializedChanged();
        return false;
    }
    
    // Set page segmentation mode for better text detection
    m_tesseract->SetPageSegMode(tesseract::PSM_AUTO);
    
    m_initialized = true;
    emit isInitializedChanged();
    setLastError("");
#else
    setLastError("Tesseract OCR is not available in this build");
    m_initialized = false;
    emit isInitializedChanged();
    return false;
#endif
    
    qDebug() << "Tesseract initialized with language:" << m_language;
    return true;
}

QString TesseractOCR::recognizeText(const QImage &image)
{
#ifdef USE_TESSERACT
    if (!m_initialized) {
        setLastError("Tesseract not initialized");
        return QString();
    }
    
    if (image.isNull()) {
        setLastError("Invalid image");
        return QString();
    }
    
    // Convert QImage to PIX
    PIX *pix = qImageToPix(image);
    if (!pix) {
        setLastError("Failed to convert image");
        return QString();
    }
    
    // Set image
    m_tesseract->SetImage(pix);
    
    // Perform OCR
    char *outText = m_tesseract->GetUTF8Text();
    QString result = QString::fromUtf8(outText);
    
    // Cleanup
    delete[] outText;
    pixDestroy(&pix);
    
    emit textRecognized(result);
    setLastError("");
    
    return result;
#else
    setLastError("Tesseract OCR is not available in this build");
    return QString();
#endif
}

QString TesseractOCR::recognizeFromFile(const QString &filePath)
{
    QImage image(filePath);
    if (image.isNull()) {
        setLastError("Failed to load image from: " + filePath);
        return QString();
    }
    
    return recognizeText(image);
}

void TesseractOCR::setLastError(const QString &error)
{
    if (m_lastError != error) {
        m_lastError = error;
        emit lastErrorChanged();
        
        if (!error.isEmpty()) {
            qWarning() << "Tesseract OCR Error:" << error;
        }
    }
}

#ifdef USE_TESSERACT
PIX* TesseractOCR::qImageToPix(const QImage &image)
{
    // Convert QImage to 32-bit RGBA format
    QImage img = image.convertToFormat(QImage::Format_RGBA8888);
    
    int width = img.width();
    int height = img.height();
    int depth = 32;
    
    // Create PIX
    PIX *pix = pixCreate(width, height, depth);
    if (!pix) {
        return nullptr;
    }
    
    // Copy pixel data
    for (int y = 0; y < height; ++y) {
        const uchar *line = img.constScanLine(y);
        for (int x = 0; x < width; ++x) {
            const uchar *pixel = line + (x * 4);
            l_uint32 pixelValue = (pixel[0] << 24) | (pixel[1] << 16) | (pixel[2] << 8) | pixel[3];
            pixSetPixel(pix, x, y, pixelValue);
        }
    }
    
    return pix;
}
#endif
