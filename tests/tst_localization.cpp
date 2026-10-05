#include <QtTest>
#include <QApplication>
#include <QTemporaryDir>
#include <QSettings>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QFontDatabase>
#include <QMenu>
#include <QAction>
#include <QFile>
#include <QJsonDocument>
#include "Localization.h"
#include "AppSettings.h"
#include "CodexAppServerClient.h"
#include "CodexRateLimitModel.h"
#include "PetLibrary.h"
#include "TrayController.h"

class LocalizationTests : public QObject
{
    Q_OBJECT
private slots:
    void languagesAndPersistence()
    {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        QSettings::setDefaultFormat(QSettings::IniFormat);
        QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, dir.path());
        QCoreApplication::setOrganizationName("CodexMeterTests");
        QCoreApplication::setApplicationName("Localization");
        AppSettings settings;
        Localization localization;
        CodexRateLimitModel model;
        model.updateFromRateLimitsResult(QJsonObject{{"rateLimits", QJsonObject{
            {"primary", QJsonObject{{"usedPercent", 25}, {"windowDurationMins", 300}, {"resetsAt", 2000000000}}}}}});
        CodexAppServerClient client(&model);
        PetLibrary pets;
        TrayController tray(&settings, &client);
        QQmlApplicationEngine engine;
        engine.rootContext()->setContextProperty("petLibrary", &pets);
        QQmlComponent component(&engine, QUrl::fromLocalFile(QFINDTESTDATA("../qml/SettingsWindow.qml")));
        QScopedPointer<QObject> window(component.createWithInitialProperties({
            {"settings", QVariant::fromValue(&settings)},
            {"client", QVariant::fromValue(&client)},
            {"rateModel", QVariant::fromValue(&model)}}));
        QVERIFY2(window, qPrintable(component.errorString()));
        QMenu *languageMenu = nullptr;
        for (auto *widget : QApplication::topLevelWidgets()) {
            auto *menu = qobject_cast<QMenu *>(widget);
            if (menu && menu->actions().size() == 11) languageMenu = menu;
        }
        QVERIFY(languageMenu);
        connect(&settings, &AppSettings::languageChanged, &engine, [&] {
            QVERIFY(localization.setLanguage(settings.language()));
            engine.retranslate();
            tray.retranslate();
            model.retranslate();
        });
        // Ensure the initial language is applied even if the first selection matches it.
        QVERIFY(localization.setLanguage(settings.language()));
        engine.retranslate();
        for (const auto &code : AppSettings::languageCodes()) {
            QAction *choice = nullptr;
            for (auto *action : languageMenu->actions())
                if (action->data().toString() == code) choice = action;
            QVERIFY(choice);
            choice->trigger();
            QCOMPARE(settings.language(), code);
            AppSettings restored;
            QCOMPARE(restored.language(), code);
            QFile file(":/translations/" + code + ".json");
            QVERIFY(file.open(QIODevice::ReadOnly));
            const auto catalog = QJsonDocument::fromJson(file.readAll()).object();
            QCOMPARE(window->property("title").toString(), catalog.value("Codex Meter - Impostazioni").toString());
            QCOMPARE(languageMenu->title(), catalog.value("Lingua").toString());
            QCOMPARE(client.status(), catalog.value("Idle").toString());
            QCOMPARE(model.get(0).value("displayBucket").toString(), catalog.value("5 ore").toString());
            QCOMPARE(CodexRateLimitModel::displayBucket("2h", 120), catalog.value("%1 h").toString().arg(2));
            int checked = 0;
            for (auto *action : languageMenu->actions()) checked += action->isChecked();
            QCOMPARE(checked, 1);
            QVERIFY(choice->isChecked());
            for (auto it = catalog.begin(); it != catalog.end(); ++it)
                QCOMPARE(QCoreApplication::translate("AnyContext", it.key().toUtf8().constData()), it.value().toString());
            if (qEnvironmentVariableIsSet("CODEXMETER_TRANSLATION_SCREENSHOTS")) {
                auto *quickWindow = qobject_cast<QQuickWindow *>(window.data());
                QVERIFY(quickWindow);
                quickWindow->show();
                QTest::qWait(100);
                QVERIFY(quickWindow->grabWindow().save("settings-" + code + ".png"));
                quickWindow->hide();
            }
        }
        settings.setLanguage("invalid");
        QCOMPARE(settings.language(), QString("tr"));
        QVERIFY(!localization.setLanguage("invalid"));
        QCOMPARE(QCoreApplication::translate("Test", "Lingua"), QString::fromUtf8("Dil"));
        QCOMPARE(QCoreApplication::translate("Test", "Unknown server message"), QString("Unknown server message"));
        QSettings().setValue("ui/language", "corrupt");
        QCOMPARE(settings.language(), QString("en"));
    }
};

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    QQuickStyle::setStyle("Basic");
    QFontDatabase::addApplicationFont(QFINDTESTDATA("../assets/fonts/Poppins-Regular.ttf"));
    QFontDatabase::addApplicationFont(QFINDTESTDATA("../assets/fonts/Poppins-SemiBold.ttf"));
    // The offscreen platform does not discover Windows fonts automatically.
    if (qEnvironmentVariable("QT_QPA_PLATFORM") == "offscreen") {
        const QString fonts = qEnvironmentVariable("WINDIR") + "/Fonts/";
        QFontDatabase::addApplicationFont(fonts + "msyh.ttc");
        QFontDatabase::addApplicationFont(fonts + "segoeui.ttf");
    }
#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
    QFontDatabase::addApplicationFallbackFontFamily(QChar::Script_Han, "Microsoft YaHei");
    QFontDatabase::addApplicationFallbackFontFamily(QChar::Script_Cyrillic, "Segoe UI");
#endif
    LocalizationTests tests;
    return QTest::qExec(&tests, argc, argv);
}
#include "tst_localization.moc"
