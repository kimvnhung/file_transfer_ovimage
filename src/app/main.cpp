// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "tesseractocr.h"
#include "steganography.h"

// QPermission is available from Qt 6.5+
#if QT_VERSION >= QT_VERSION_CHECK(6, 5, 0)
  #include <QPermission>
  #define HAS_QPERMISSION
#endif

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    // Create TesseractOCR instance
    TesseractOCR tesseractOCR;
    
    // Create Steganography instance
    Steganography steganography;
    
    QQmlApplicationEngine engine;
    
    // Add QML import path for opencv_player module
    engine.addImportPath(QCoreApplication::applicationDirPath() + "/qml");
    
    // Expose TesseractOCR to QML
    engine.rootContext()->setContextProperty("tesseractOCR", &tesseractOCR);
    
    // Expose Steganography to QML
    engine.rootContext()->setContextProperty("steganography", &steganography);

#ifdef DESKTOP_MODE
    // Desktop Test Mode - Load simplified UI
    qDebug() << "=== DESKTOP TEST MODE ===";
    qDebug() << "Loading simplified test UI...";
    
    auto setupView = [&engine](const QUrl &viewSource) {
        QObject::connect(&engine, &QQmlApplicationEngine::quit, qApp, &QGuiApplication::quit);
        engine.load(viewSource);
    };
    
    setupView(QUrl("qrc:/qml/views/DesktopTestView.qml"));
    
#else
    // Mobile Mode - Load full application UI with permissions
    qDebug() << "=== MOBILE MODE ===";
    qDebug() << "Loading full mobile UI...";
    
    auto setupView = [&engine](const QUrl &viewSource) {
        // Qt.quit() called in embedded .qml by default only emits
        // quit() signal, so do this (optionally use Qt.exit()).
        QObject::connect(&engine, &QQmlApplicationEngine::quit, qApp, &QGuiApplication::quit);
        engine.load(viewSource);
    };

#ifdef HAS_QPERMISSION
    QCameraPermission cameraPermission;
    qApp->requestPermission(cameraPermission, [&setupView](const QPermission &permission) {
        if (permission.status() == Qt::PermissionStatus::Denied)
            setupView(QUrl("qrc:/qml/views/PermissionDenied.qml"));
        else
            setupView(QUrl("qrc:/qml/views/AppMain.qml"));
    });
#else
    setupView(QUrl("qrc:/qml/views/AppMain.qml"));
#endif

#endif

    return app.exec();
}
