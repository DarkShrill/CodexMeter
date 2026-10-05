#include <QtTest>
#include <QTemporaryDir>
#include <QFile>
#include <QJsonDocument>
#include "../TaskActivity.h"
class ActivityTest : public QObject {
    Q_OBJECT
    void append(const QString &path, const QString &recordType, QJsonObject payload) {
        QFile f(path); QVERIFY(f.open(QIODevice::WriteOnly | QIODevice::Append));
        QJsonObject r{{"timestamp", QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs)}, {"type",recordType}, {"payload",payload}};
        f.write(QJsonDocument(r).toJson(QJsonDocument::Compact)+"\n");
    }
private slots:
    void lifecycleAndAsyncInput() {
        QTemporaryDir dir; QVERIFY(dir.isValid());
        TaskActivity activity(nullptr,dir.path(),false);
        QSignalSpy done(&activity,&TaskActivity::taskCompleted);
        const QString log=dir.path()+"/session.jsonl";
        append(log,"event_msg",{{"type","task_started"}}); activity.poll();
        QVERIFY(activity.working()); QCOMPARE(activity.state(),QString("thinking"));
        append(log,"response_item",{{"type","function_call"},{"name","exec_command"},{"call_id","cmd"}});activity.poll();
        QCOMPARE(activity.state(),QString("working"));
        append(log,"response_item",{{"type","function_call"},{"name","request_user_input_async"},{"call_id","ask"}});activity.poll();
        QCOMPARE(activity.state(),QString("waiting"));
        append(log,"response_item",{{"type","function_call_output"},{"call_id","ask"},{"output","accepted"}});activity.poll();
        QCOMPARE(activity.state(),QString("waiting"));
        append(log,"response_item",{{"type","reasoning"}});activity.poll();
        QCOMPARE(activity.state(),QString("waiting"));
        append(log,"response_item",{{"type","message"},{"role","user"}});activity.poll();
        QCOMPARE(activity.state(),QString("thinking"));
        append(log,"event_msg",{{"type","entered_review_mode"}});activity.poll();
        QCOMPARE(activity.state(),QString("review"));
        append(log,"response_item",{{"type","function_call"},{"name","exec_command"},{"call_id","reviewTool"}});activity.poll();
        QCOMPARE(activity.state(),QString("review"));
        append(log,"response_item",{{"type","function_call_output"},{"call_id","reviewTool"}});activity.poll();
        QCOMPARE(activity.state(),QString("review"));
        append(log,"event_msg",{{"type","task_complete"}});activity.poll();
        QCOMPARE(done.count(),1); QCOMPARE(activity.state(),QString("completed")); QVERIFY(!activity.working());
        QTRY_COMPARE_WITH_TIMEOUT(activity.state(),QString("idle"),2500);
    }
    void historicalAndNewCompletion() {
        QTemporaryDir dir; const QString log=dir.path()+"/history.jsonl";
        append(log,"event_msg",{{"type","task_started"}});
        append(log,"event_msg",{{"type","task_complete"}});
        TaskActivity activity(nullptr,dir.path(),false);
        QSignalSpy done(&activity,&TaskActivity::taskCompleted);
        QCOMPARE(activity.state(),QString("idle"));activity.poll(); QCOMPARE(done.count(),0);
        const QString fresh=dir.path()+"/new.jsonl";
        append(fresh,"event_msg",{{"type","task_started"}});
        append(fresh,"event_msg",{{"type","task_complete"}});activity.poll();
        QCOMPARE(done.count(),1); QCOMPARE(activity.state(),QString("completed"));
    }
    void partialLineAndTruncation() {
        QTemporaryDir dir; TaskActivity activity(nullptr,dir.path(),false);
        const QString log=dir.path()+"/partial.jsonl";
        { QFile f(log); QVERIFY(f.open(QIODevice::WriteOnly)); f.write("{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_started\"}}"); }
        activity.poll(); QVERIFY(!activity.working());
        { QFile f(log); QVERIFY(f.open(QIODevice::WriteOnly|QIODevice::Append)); f.write("\n"); }
        activity.poll(); QVERIFY(activity.working());
        { QFile f(log); QVERIFY(f.open(QIODevice::WriteOnly|QIODevice::Truncate)); }
        activity.poll(); QVERIFY(!activity.working()); QCOMPARE(activity.state(),QString("idle"));
    }
    void interruptedAndToolError() {
        QTemporaryDir dir; TaskActivity activity(nullptr,dir.path(),false);
        QSignalSpy done(&activity,&TaskActivity::taskCompleted);
        const QString log=dir.path()+"/session.jsonl";
        append(log,"event_msg",{{"type","task_started"}}); activity.poll();
        append(log,"event_msg",{{"type","item_completed"},{"item",QJsonObject{{"type","CommandExecution"},{"exit_code",1},{"status","completed"}}}});activity.poll();
        QCOMPARE(activity.state(),QString("failed")); QVERIFY(activity.working());
        append(log,"response_item",{{"type","reasoning"}});activity.poll();
        QCOMPARE(activity.state(),QString("thinking"));
        append(log,"event_msg",{{"type","turn_aborted"}});activity.poll();
        QCOMPARE(done.count(),0); QCOMPARE(activity.state(),QString("failed")); QVERIFY(!activity.working());
    }
    void parallelTasksAndNames() {
        QTemporaryDir dir;
        QVERIFY(QDir(dir.path()).mkdir("sessions"));
        const QString sessions = dir.path() + "/sessions";
        const QString index = dir.path() + "/session_index.jsonl";
        { QFile file(index); QVERIFY(file.open(QIODevice::WriteOnly));
          file.write("{\"id\":\"a\",\"thread_name\":\"Grafica pet\"}\n{\"id\":\"b\",\"thread_name\":\"Test monitor\"}\n"); }
        TaskActivity activity(nullptr, sessions, false);
        QSignalSpy changed(&activity, &TaskActivity::activeTasksChanged);
        const QString first = sessions + "/a.jsonl", second = sessions + "/b.jsonl";
        append(first, "session_meta", {{"id", "a"}, {"cwd", "C:/Project"}});
        append(first, "event_msg", {{"type", "task_started"}});
        append(second, "session_meta", {{"id", "b"}});
        append(second, "event_msg", {{"type", "task_started"}});
        activity.poll();
        QCOMPARE(activity.taskCount(), 2);
        QCOMPARE(activity.activeTasks()[0].toMap().value("title").toString(), QString("Grafica pet"));
        QCOMPARE(activity.activeTasks()[1].toMap().value("title").toString(), QString("Test monitor"));
        QCOMPARE(changed.count(), 1);
        activity.poll(); QCOMPARE(changed.count(), 1);
        const QString child = sessions + "/child.jsonl";
        append(child, "session_meta", {{"id", "child"}, {"source", QJsonObject{{"subagent", QJsonObject{}}}}});
        append(child, "event_msg", {{"type", "task_started"}});
        activity.poll(); QCOMPARE(activity.taskCount(), 2);
        { QFile file(index); QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Append));
          file.write("{\"id\":\"a\",\"thread_name\":\"Nuova grafica\"}\n"); }
        activity.poll();
        QCOMPARE(activity.activeTasks()[0].toMap().value("title").toString(), QString("Nuova grafica"));
        append(first, "event_msg", {{"type", "task_complete"}});
        activity.poll(); QCOMPARE(activity.taskCount(), 1);
        QCOMPARE(activity.activeTasks()[0].toMap().value("id").toString(), QString("b"));
        QVERIFY(QFile::remove(second));
        activity.poll(); QCOMPARE(activity.taskCount(), 0);
    }
    void activeTurnBeforeRecentTail() {
        QTemporaryDir dir;
        const QString log = dir.path() + "/long.jsonl";
        append(log, "session_meta", {{"id", "long"}, {"title", "Task lungo"}});
        append(log, "event_msg", {{"type", "task_started"}});
        { QFile file(log); QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Append));
          file.write(QByteArray(300000, ' ') + "\n"); }
        append(log, "response_item", {{"type", "reasoning"}});
        TaskActivity activity(nullptr, dir.path(), false);
        QCOMPARE(activity.taskCount(), 1);
        QCOMPARE(activity.state(), QString("thinking"));
        append(log, "event_msg", {{"type", "task_complete"}});
        activity.poll(); QCOMPARE(activity.taskCount(), 0);
        TaskActivity reloaded(nullptr, dir.path(), false);
        QCOMPARE(reloaded.taskCount(), 0);
    }
    void ignoreSubagentCompletion() {
        QTemporaryDir dir; TaskActivity activity(nullptr,dir.path(),false);
        QSignalSpy done(&activity,&TaskActivity::taskCompleted);
        const QString log=dir.path()+"/parent.jsonl";
        append(log,"event_msg",{{"type","task_started"}});activity.poll();
        const QString child=dir.path()+"/child.jsonl";
        append(child,"session_meta",{{"source",QJsonObject{{"subagent",QJsonObject{{"other","guardian"}}}}}});
        append(child,"event_msg",{{"type","task_started"}});
        append(child,"event_msg",{{"type","task_complete"}});activity.poll();
        QCOMPARE(done.count(),0); QVERIFY(activity.working()); QCOMPARE(activity.state(),QString("thinking"));
    }
};
QTEST_GUILESS_MAIN(ActivityTest)
#include "tst_activity.moc"
