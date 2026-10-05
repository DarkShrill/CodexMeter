#pragma once
#include <QObject>
#include <QTimer>
#include <QHash>
#include <QJsonObject>
#include <QDateTime>
#include <QVariantList>

// Observe existing desktop sessions; never start or modify a Codex task.
class TaskActivity : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool working READ working NOTIFY workingChanged)
    Q_PROPERTY(QString state READ state NOTIFY stateChanged)
    Q_PROPERTY(int taskCount READ taskCount NOTIFY activeTasksChanged)
    Q_PROPERTY(QVariantList activeTasks READ activeTasks NOTIFY activeTasksChanged)
public:
    explicit TaskActivity(QObject *parent = nullptr, const QString &sessionRoot = {}, bool startTimer = true);
    bool working() const;
    QString state() const { return m_state; }
    int taskCount() const { return m_activeTasks.size(); }
    QVariantList activeTasks() const { return m_activeTasks; }
    void poll();
signals:
    void workingChanged();
    void stateChanged();
    void taskCompleted();
    void activeTasksChanged();
private:
    struct Session {
        qint64 offset = 0;
        bool active = false;
        bool ignored = false;
        bool reviewing = false;
        bool inferTailActivity = false;
        QString state = "idle";
        QString id;
        QString title;
        QString workspace;
        QDateTime changed;
        QHash<QString, bool> inputCalls; // value: asynchronous request
    };
    void consume(Session &session, const QJsonObject &record, bool notify);
    void setState(const QString &state);
    void readTaskNames();
    void updateActiveTasks();
    QTimer m_timer;
    QTimer m_settle;
    QString m_sessionRoot;
    QString m_state = "idle";
    QString m_outcome;
    QDateTime m_outcomeAt;
    QDateTime m_startedAt = QDateTime::currentDateTimeUtc();
    QHash<QString, Session> m_sessions;
    bool m_initial = true;
    qint64 m_indexOffset = 0;
    QHash<QString, QString> m_taskNames;
    QVariantList m_activeTasks;
};
