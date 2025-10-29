#ifndef TESSERACTOCR_H
#define TESSERACTOCR_H

#include <QObject>
#include <QImage>
#include <QString>
#include <QQmlEngine>

#ifdef USE_TESSERACT
#include <tesseract/baseapi.h>
#include <leptonica/allheaders.h>
#endif

class TesseractOCR : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(bool isInitialized READ isInitialized NOTIFY isInitializedChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit TesseractOCR(QObject *parent = nullptr);
    ~TesseractOCR();

    QString language() const { return m_language; }
    void setLanguage(const QString &lang);
    
    bool isInitialized() const { return m_initialized; }
    QString lastError() const { return m_lastError; }

    Q_INVOKABLE bool initialize();
    Q_INVOKABLE QString recognizeText(const QImage &image);
    Q_INVOKABLE QString recognizeFromFile(const QString &filePath);

signals:
    void languageChanged();
    void isInitializedChanged();
    void lastErrorChanged();
    void textRecognized(const QString &text);
    void recognitionProgress(int progress);

private:
#ifdef USE_TESSERACT
    tesseract::TessBaseAPI *m_tesseract;
    PIX* qImageToPix(const QImage &image);
#endif
    QString m_language;
    bool m_initialized;
    QString m_lastError;
    
    void setLastError(const QString &error);
};

#endif // TESSERACTOCR_H
