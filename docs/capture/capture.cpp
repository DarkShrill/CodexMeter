#include <QCoreApplication>
#include <QFontDatabase>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickStyle>
#include <QResource>
#include <QtQuickTest/quicktest.h>
#include "PetLibrary.h"

class CaptureSetup : public QObject
{
    Q_OBJECT
public slots:
    void applicationAvailable() {
        QCoreApplication::setOrganizationName("ReadmeCapture");
        QCoreApplication::setApplicationName("ReadmeCapture");
        if (!QResource::registerResource(QCoreApplication::applicationDirPath() + "/../readme.rcc"))
            qFatal("Cannot load build/docs-capture/readme.rcc");
        QQuickStyle::setStyle("Basic");
        for (const auto *weight : {"Regular", "Medium", "SemiBold", "Bold"})
            QFontDatabase::addApplicationFont(QString(":/assets/fonts/Poppins-%1.ttf").arg(weight));
    }
    void qmlEngineAvailable(QQmlEngine *engine) {
        engine->rootContext()->setContextProperty("petLibrary", new PetLibrary(engine));
    }
};

QUICK_TEST_MAIN_WITH_SETUP(readme_capture, CaptureSetup)
#include "capture.moc"
