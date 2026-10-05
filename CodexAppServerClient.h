#pragma once

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QHash>
#include <QDateTime>
#include <QJsonObject>

class CodexRateLimitModel;

class CodexAppServerClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(QDateTime lastUpdated READ lastUpdated NOTIFY lastUpdatedChanged)
    Q_PROPERTY(int refreshSeconds READ refreshSeconds WRITE setRefreshSeconds NOTIFY refreshSecondsChanged)

public:
    explicit CodexAppServerClient(CodexRateLimitModel *model, QObject *parent = nullptr);

    QString status() const;
    QString lastError() const { return tr(m_lastError.toUtf8().constData()); }
    bool connected() const { return m_initialized && m_process.state() == QProcess::Running; }
    QDateTime lastUpdated() const { return m_lastUpdated; }
    int refreshSeconds() const { return m_refreshSeconds; }

    void setRefreshSeconds(int seconds);

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void refresh();

signals:
    void statusChanged();
    void lastErrorChanged();
    void connectedChanged();
    void lastUpdatedChanged();
    void refreshSecondsChanged();

private slots:
    void onReadyReadStdout();
    void onReadyReadStderr();
    void onProcessError(QProcess::ProcessError error);
    void onProcessFinished(int exitCode, QProcess::ExitStatus status);

private:
    enum class RequestKind { Initialize, RateLimits };

    qint64 sendRequest(const QString &method, const QJsonObject &params = {}, bool includeParams = false);
    void sendNotification(const QString &method, const QJsonObject &params = {}, bool includeParams = false);
    void writeJsonLine(const QJsonObject &object);
    void processLine(const QByteArray &line);
    void processMessage(const QJsonObject &message);
    void handleResponse(qint64 id, const QJsonObject &message);
    void handleNotification(const QString &method, const QJsonObject &params);
    void setStatus(const QString &status);
    void setError(const QString &error);
    QString resolveCodexProgram(QStringList &arguments) const;
    void scheduleRestart();

    CodexRateLimitModel *m_model = nullptr;
    QProcess m_process;
    QTimer m_refreshTimer;
    QTimer m_restartTimer;
    QByteArray m_stdoutBuffer;
    QHash<qint64, RequestKind> m_pending;
    qint64 m_nextId = 1;
    bool m_initialized = false;
    bool m_stopping = false;
    int m_refreshSeconds = 60;
    QString m_status = QStringLiteral("Idle");
    QString m_lastError;
    int m_exitCode = 0;
    QDateTime m_lastUpdated;
};
