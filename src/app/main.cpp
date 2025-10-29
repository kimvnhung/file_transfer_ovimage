// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QGuiApplication>
#include <QQmlEngine>
#include <QQuickView>
#include <QQmlContext>
#include "tesseractocr.h"

#if QT_CONFIG(permissions)
  #include <QPermission>
#endif

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    // Create TesseractOCR instance
    TesseractOCR tesseractOCR;
    
    QQuickView view;
    view.setResizeMode(QQuickView::SizeRootObjectToView);
    
    // Expose TesseractOCR to QML
    view.rootContext()->setContextProperty("tesseractOCR", &tesseractOCR);

    auto setupView = [&view](const QUrl &viewSource) {
        // Qt.quit() called in embedded .qml by default only emits
        // quit() signal, so do this (optionally use Qt.exit()).
        QObject::connect(view.engine(), &QQmlEngine::quit, qApp, &QGuiApplication::quit);
        view.setSource(viewSource);
        view.show();
    };

#if QT_CONFIG(permissions)
    QCameraPermission cameraPermission;
    qApp->requestPermission(cameraPermission, [&setupView](const QPermission &permission) {
        if (permission.status() == Qt::PermissionStatus::Denied)
            setupView(QUrl("qrc:/qml/views/PermissionDenied.qml"));
        else
            setupView(QUrl("qrc:/qml/views/MainView.qml"));
    });
#else
    setupView(QUrl("qrc:/qml/views/MainView.qml"));
#endif

    return app.exec();
}
