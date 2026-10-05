#include <QtTest>
#include <QApplication>
#include <QSettings>
#include <QSignalSpy>
#include <QScreen>
#include "../AppSettings.h"
#include "../CodexRateLimitModel.h"
#include "../TaskbarMonitor.h"
#include <windows.h>
class TaskbarTests : public QObject {
    Q_OBJECT
private slots:
    void initTestCase() {
        QCoreApplication::setOrganizationName("CodexMeterTests");
        QCoreApplication::setApplicationName("TaskbarTests");
        QSettings::setDefaultFormat(QSettings::IniFormat);
        QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, QDir::currentPath() + "/settings");
        QSettings().clear();
    }
    void gaps() {
        QRect bounds(0,0,1000,48);
        const QRect slot=TaskbarMonitor::freeSlot(bounds,{QRect(400,0,200,48),QRect(800,0,200,48)},QSize(132,40));
        QVERIFY(bounds.contains(slot));
        QVERIFY(!slot.intersects(QRect(800,0,200,48)));
        QVERIFY(!slot.intersects(QRect(400,0,200,48)));
        QVERIFY(TaskbarMonitor::freeSlot(bounds,{bounds},QSize(132,40)).isEmpty());
        const QRect vertical=TaskbarMonitor::freeSlot(QRect(0,0,60,800),{QRect(0,500,60,300)},QSize(56,64));
        QVERIFY(!vertical.isEmpty());
        QVERIFY(vertical.bottom()<500);
        QVERIFY(TaskbarMonitor::freeSlot(bounds,{},QSize(1200,40)).isEmpty());
    }
    void settingsAndModel() {
        AppSettings settings;
        settings.setTaskbarMonitor(false);
        QSignalSpy spy(&settings,&AppSettings::taskbarMonitorChanged);
        settings.setTaskbarMonitor(true);
        settings.setTaskbarMonitor(true);
        QCOMPARE(spy.count(),1);
        AppSettings reloaded;
        QVERIFY(reloaded.taskbarMonitor());
        settings.setTaskbarMonitor(false);
        CodexRateLimitModel model;
        TaskbarMonitor monitor(&settings,&model);
        QVERIFY(monitor.summary().contains("In attesa"));
        model.updateFromRateLimitsResult(QJsonObject{{"rateLimits",QJsonObject{
            {"primary",QJsonObject{{"usedPercent",27},{"windowDurationMins",300}}},
            {"secondary",QJsonObject{{"usedPercent",40},{"windowDurationMins",10080}}}}}});
        QVERIFY(monitor.summary().contains("73%"));
        QVERIFY(monitor.summary().contains("60%"));
    }
    void petInfoPreference() {
        QSettings().remove("ui/petInfoStyle");
        AppSettings settings;
        QCOMPARE(settings.petInfoStyle(), QString("minimal"));
        QSignalSpy spy(&settings, &AppSettings::petInfoStyleChanged);
        settings.setPetInfoStyle("bubble");
        settings.setPetInfoStyle("bubble");
        settings.setPetInfoStyle("invalid");
        QCOMPARE(spy.count(), 1);
        AppSettings reloaded;
        QCOMPARE(reloaded.petInfoStyle(), QString("bubble"));
        settings.setPetInfoStyle("minimal");
        QCOMPARE(spy.count(), 2);
        QCOMPARE(reloaded.petInfoStyle(), QString("minimal"));
    }
    void petBubbleSizePreference() {
        QSettings().remove("ui/petBubbleScale");
        AppSettings settings;
        QCOMPARE(settings.petBubbleScale(), 1.0);
        QSignalSpy spy(&settings, &AppSettings::petBubbleScaleChanged);
        settings.setPetBubbleScale(1.4);
        settings.setPetBubbleScale(1.4);
        QCOMPARE(spy.count(), 1);
        AppSettings reloaded;
        QCOMPARE(reloaded.petBubbleScale(), 1.4);
        settings.setPetBubbleScale(3);
        QCOMPARE(settings.petBubbleScale(), 1.8);
        settings.setPetBubbleScale(0.1);
        QCOMPARE(settings.petBubbleScale(), 0.6);
        settings.setPetBubbleScale(qQNaN());
        QCOMPARE(settings.petBubbleScale(), 0.6);
        settings.setPetBubbleScale(1);
    }
    void petLayoutPreference() {
        AppSettings settings;
        settings.setPetExpression(5);
        settings.resetPetLayout();
        settings.setPetLayoutOffset("bubble", -40, 75);
        settings.setPetLayoutOffset("tasksPopup", 90, -15);
        settings.setPetLayoutOffset("invalid", 1, 2);
        settings.setPetLayoutOffset("status", qQNaN(), 2);
        AppSettings reloaded;
        QCOMPARE(reloaded.petLayout().value("bubble").toMap().value("x").toDouble(), -40.0);
        QCOMPARE(reloaded.petLayout().size(), 2);
        settings.setPetExpression(6);
        settings.resetPetLayout();
        QVERIFY(settings.petLayout().isEmpty());
        settings.setPetExpression(5);
        QCOMPARE(settings.petLayout().size(), 2);
        settings.resetPetLayout();
        QVERIFY(settings.petLayout().isEmpty());
    }
    void nativeLifecycle() {
        AppSettings settings;
        settings.setTaskbarMonitor(false);
        CodexRateLimitModel model;
        TaskbarMonitor monitor(&settings,&model);
        QCOMPARE(monitor.nativeHandle(),quintptr(0));
        model.updateFromRateLimitsResult(QJsonObject{{"rateLimits",QJsonObject{
            {"primary",QJsonObject{{"usedPercent",27},{"windowDurationMins",300}}},
            {"secondary",QJsonObject{{"usedPercent",40},{"windowDurationMins",10080}}}}}});
        settings.setTaskbarMonitor(true);
        QTRY_VERIFY_WITH_TIMEOUT(monitor.nativeHandle() != 0, 15000);
        auto window=reinterpret_cast<HWND>(monitor.nativeHandle());
        QVERIFY2(window && IsWindow(window),"No free taskbar slot or native surface creation failed");
        QCOMPARE(GetParent(window), HWND(nullptr));
        QVERIFY(IsWindowVisible(window));
        QTest::qWait(200);
        RECT geometry{}; GetWindowRect(window,&geometry);
        QVERIFY(QApplication::primaryScreen()->grabWindow(0,geometry.left-4,geometry.top-4,
            geometry.right-geometry.left+8,geometry.bottom-geometry.top+8).save("taskbar-preview.png"));
        QSignalSpy clicked(&monitor,&TaskbarMonitor::activated);
        SendMessageW(window,WM_LBUTTONUP,0,0);
        QCOMPARE(clicked.count(),1);
        DestroyWindow(window); // Simulate Explorer losing our child surface.
        monitor.refresh();
        QTRY_VERIFY_WITH_TIMEOUT(IsWindow(reinterpret_cast<HWND>(monitor.nativeHandle())), 15000);
        settings.setTaskbarMonitor(false);
        QCOMPARE(monitor.nativeHandle(),quintptr(0));
    }
    void reserveFollowsOrdinaryWindows() {
        CodexRateLimitModel model;
        model.updateFromRateLimitsResult(QJsonObject{{"rateLimitsByLimitId", QJsonObject{
            {"codex", QJsonObject{{"primary", QJsonObject{{"usedPercent", 10}, {"windowDurationMins", 300}}},
                                 {"secondary", QJsonObject{{"usedPercent", 20}, {"windowDurationMins", 10080}}}}},
            {"gpt-reserve", QJsonObject{{"primary", QJsonObject{{"usedPercent", 0}, {"windowDurationMins", 300}}}}}
        }}});
        QCOMPARE(model.get(0).value("bucket").toString(), QString("5h"));
        QCOMPARE(model.get(1).value("bucket").toString(), QString("Week"));
        QCOMPARE(model.get(2).value("limitId").toString(), QString("gpt-reserve"));
    }
    void reserveWithOpaqueId() {
        CodexRateLimitModel model;
        model.updateFromRateLimitsResult(QJsonObject{{"rateLimitsByLimitId", QJsonObject{
            {"codex", QJsonObject{{"primary", QJsonObject{{"usedPercent", 23}, {"windowDurationMins", 300}}},
                                 {"secondary", QJsonObject{{"usedPercent", 4}, {"windowDurationMins", 10080}}}}},
            {"a-pool", QJsonObject{{"limitId", "opaque-id"}, {"limitName", "GPT-Reserve"},
                                 {"primary", QJsonObject{{"usedPercent", 0}, {"windowDurationMins", 10080}}}}}
        }}});
        QCOMPARE(model.get(0).value("remainingPercent").toInt(), 77);
        QCOMPARE(model.get(1).value("remainingPercent").toInt(), 96);
        QCOMPARE(model.get(2).value("remainingPercent").toInt(), 100);
        QVERIFY(model.get(2).value("isReserve").toBool());
    }
    void cleanupTestCase() { QSettings().clear(); }
};
QTEST_MAIN(TaskbarTests)
#include "tst_taskbar.moc"
