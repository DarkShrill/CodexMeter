#include <QApplication>
#include <QFont>
#include <QFontDatabase>
#include <QFileInfo>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#ifdef CODEXMETER_PREVIEWS
#include <QQmlDebuggingEnabler>
#endif
#include <QQuickStyle>

#include "AppSettings.h"
#include "Localization.h"
#include "TaskActivity.h"
#include "CodexAppServerClient.h"
#include "CodexRateLimitModel.h"
#include "PetLibrary.h"
#include "TrayController.h"
#include "TaskbarMonitor.h"

int main(int argc, char *argv[])
{
    bool qmlLivePreview = false;
    for (int index = 1; index < argc; ++index) {
        const QByteArray argument(argv[index]);
        if (argument.startsWith("-qmljsdebugger=")
                && argument.contains("services:QmlPreview")) {
            qmlLivePreview = true;
            break;
        }
    }

    QApplication app(argc, argv);
    // Configure Controls before either the application or a preview loads QML.
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QFontDatabase::addApplicationFont(QStringLiteral(":/assets/fonts/Poppins-Regular.ttf"));
    QFontDatabase::addApplicationFont(QStringLiteral(":/assets/fonts/Poppins-Medium.ttf"));
    QFontDatabase::addApplicationFont(QStringLiteral(":/assets/fonts/Poppins-SemiBold.ttf"));
    QFontDatabase::addApplicationFont(QStringLiteral(":/assets/fonts/Poppins-Bold.ttf"));
#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
    QFontDatabase::addApplicationFallbackFontFamily(QChar::Script_Han, QStringLiteral("Microsoft YaHei"));
    QFontDatabase::addApplicationFallbackFontFamily(QChar::Script_Cyrillic, QStringLiteral("Segoe UI"));
#endif
    QApplication::setFont(QFont(QStringLiteral("Poppins"), 10));

    const QStringList arguments = app.arguments();
    const int previewOption = arguments.indexOf(QStringLiteral("--preview"));
    if (previewOption >= 0 || qmlLivePreview) {
#ifdef CODEXMETER_PREVIEWS
        qInfo() << "CodexMeter QML Preview mode";
        QQmlApplicationEngine previewEngine;

        // Qt Creator carica direttamente il file selezionato in questo engine.
        // Una finestra bootstrap interferirebbe con dimensioni e posizione.
        if (qmlLivePreview && previewOption < 0)
            return app.exec();

        const QString previewFile = previewOption + 1 < arguments.size()
                ? arguments.at(previewOption + 1) : QString();
        if (previewFile.endsWith(QStringLiteral("Preview.qml"))) {
            const QFileInfo file(previewFile);
            if (file.isAbsolute() && !file.isFile()) {
                qCritical() << "Preview file does not exist:" << previewFile;
                return 1;
            }
            const QUrl source = file.isFile()
                    ? QUrl::fromLocalFile(file.absoluteFilePath())
                    : QUrl(QStringLiteral("qrc:/qml/previews/") + previewFile);
            previewEngine.rootContext()->setContextProperty(QStringLiteral("previewSource"), source);
            previewEngine.load(QUrl(QStringLiteral("qrc:/qml/previews/PreviewWindow.qml")));
        } else {
            previewEngine.load(QUrl(QStringLiteral("qrc:/qml/previews/PreviewGallery.qml")));
        }

        return previewEngine.rootObjects().isEmpty() ? 1 : app.exec();
#else
        qCritical() << "QML previews are available only in Debug builds.";
        return 1;
#endif
    }

    QApplication::setQuitOnLastWindowClosed(false);
    QCoreApplication::setOrganizationName(QStringLiteral("LocalTools"));
    QCoreApplication::setApplicationName(QStringLiteral("CodexMeter"));
    QCoreApplication::setApplicationVersion(QStringLiteral("0.2.0"));
    QApplication::setWindowIcon(QIcon(QStringLiteral(":/assets/darkshrill-icon.png")));

    TaskActivity taskActivity;
    AppSettings settings;
    Localization localization;
    localization.setLanguage(settings.language());
    PetLibrary petLibrary;
    CodexRateLimitModel rateLimitModel;
    CodexAppServerClient codexClient(&rateLimitModel);
    codexClient.setRefreshSeconds(settings.refreshSeconds());

    QObject::connect(&settings, &AppSettings::refreshSecondsChanged, &codexClient, [&] {
        codexClient.setRefreshSeconds(settings.refreshSeconds());
    });

    TrayController tray(&settings, &codexClient);
    TaskbarMonitor taskbarMonitor(&settings, &rateLimitModel);
    QObject::connect(&taskbarMonitor, &TaskbarMonitor::activated, &tray, &TrayController::showRequested);

    QQmlApplicationEngine engine;
    QObject::connect(&settings, &AppSettings::languageChanged, &engine, [&] {
        localization.setLanguage(settings.language());
        engine.retranslate();
        tray.retranslate();
        rateLimitModel.retranslate();
        emit codexClient.statusChanged();
        emit codexClient.lastErrorChanged();
        taskbarMonitor.refresh();
    });
    engine.rootContext()->setContextProperty(QStringLiteral("taskActivity"), &taskActivity);
    engine.rootContext()->setContextProperty(QStringLiteral("appSettings"), &settings);
    engine.rootContext()->setContextProperty(QStringLiteral("petLibrary"), &petLibrary);
    engine.rootContext()->setContextProperty(QStringLiteral("rateLimitModel"), &rateLimitModel);
    engine.rootContext()->setContextProperty(QStringLiteral("codexClient"), &codexClient);
    engine.rootContext()->setContextProperty(QStringLiteral("trayController"), &tray);

    const QUrl mainUrl(QStringLiteral("qrc:/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [mainUrl](QObject *object, const QUrl &url) {
        if (!object && url == mainUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(mainUrl);
    if (engine.rootObjects().isEmpty())
        return -1;

    codexClient.start();
    return app.exec();
}
