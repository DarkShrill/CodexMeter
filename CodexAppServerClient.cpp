#include "CodexAppServerClient.h"
#include "CodexRateLimitModel.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

namespace {

QString existingFile(const QString &path)
{
    if (path.trimmed().isEmpty())
        return {};

    const QFileInfo info(QDir::cleanPath(path));
    if (!info.exists() || !info.isFile())
        return {};
    return info.absoluteFilePath();
}

#ifdef Q_OS_WIN
QString windowsCmdExe()
{
    const QString comspec = existingFile(qEnvironmentVariable("COMSPEC"));
    if (!comspec.isEmpty())
        return comspec;
    return QStandardPaths::findExecutable(QStringLiteral("cmd.exe"));
}
#endif

} // namespace

CodexAppServerClient::CodexAppServerClient(CodexRateLimitModel *model, QObject *parent)
    : QObject(parent), m_model(model)
{
    m_refreshTimer.setInterval(m_refreshSeconds * 1000);
    connect(&m_refreshTimer, &QTimer::timeout, this, &CodexAppServerClient::refresh);

    m_restartTimer.setSingleShot(true);
    m_restartTimer.setInterval(5000);
    connect(&m_restartTimer, &QTimer::timeout, this, &CodexAppServerClient::start);

    connect(&m_process, &QProcess::readyReadStandardOutput, this, &CodexAppServerClient::onReadyReadStdout);
    connect(&m_process, &QProcess::readyReadStandardError, this, &CodexAppServerClient::onReadyReadStderr);
    connect(&m_process, &QProcess::errorOccurred, this, &CodexAppServerClient::onProcessError);
    connect(&m_process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this, &CodexAppServerClient::onProcessFinished);
}

void CodexAppServerClient::setRefreshSeconds(int seconds)
{
    seconds = qBound(15, seconds, 3600);
    if (m_refreshSeconds == seconds)
        return;
    m_refreshSeconds = seconds;
    m_refreshTimer.setInterval(m_refreshSeconds * 1000);
    emit refreshSecondsChanged();
}

QString CodexAppServerClient::resolveCodexProgram(QStringList &arguments) const
{
#ifdef Q_OS_WIN
    // 1. Explicit override used by current Codex Windows setups and useful
    //    when Qt Creator was started before PATH was updated.
    const QString explicitCli = existingFile(qEnvironmentVariable("CODEX_CLI_PATH"));
    if (!explicitCli.isEmpty()) {
        arguments = {QStringLiteral("app-server")};
        return explicitCli;
    }

    // 2. Normal PATH lookup.
    const QString pathExe = QStandardPaths::findExecutable(QStringLiteral("codex.exe"));
    if (!pathExe.isEmpty()) {
        arguments = {QStringLiteral("app-server")};
        return pathExe;
    }

    // 3. Known Windows installation locations. The first entry is the
    //    location used by the official standalone Windows installer.
    const QString localAppData = qEnvironmentVariable("LOCALAPPDATA");
    const QString userProfile = qEnvironmentVariable("USERPROFILE");
    const QString appData = qEnvironmentVariable("APPDATA");

    const QStringList exeCandidates = {
        QDir(localAppData).filePath(QStringLiteral("Programs/OpenAI/Codex/bin/codex.exe")),
        QDir(userProfile).filePath(QStringLiteral(".codex/packages/standalone/current/bin/codex.exe")),
        QDir(localAppData).filePath(QStringLiteral("OpenAI/Codex/bin/codex.exe")),
        QDir(localAppData).filePath(QStringLiteral("Packages/OpenAI.Codex_2p2nqsd0c76g0/LocalCache/Local/OpenAI/Codex/bin/codex.exe"))
    };

    for (const QString &candidate : exeCandidates) {
        const QString codexExe = existingFile(candidate);
        if (!codexExe.isEmpty()) {
            arguments = {QStringLiteral("app-server")};
            return codexExe;
        }
    }

    // 4. npm global installs commonly expose a codex.cmd shim. A .cmd file
    //    must be launched through cmd.exe on Windows.
    QString codexCmd = QStandardPaths::findExecutable(QStringLiteral("codex.cmd"));
    if (codexCmd.isEmpty())
        codexCmd = existingFile(QDir(appData).filePath(QStringLiteral("npm/codex.cmd")));

    if (!codexCmd.isEmpty()) {
        const QString cmd = windowsCmdExe();
        if (!cmd.isEmpty()) {
            arguments = {
                QStringLiteral("/D"),
                QStringLiteral("/S"),
                QStringLiteral("/C"),
                QStringLiteral("call \"") + QDir::toNativeSeparators(codexCmd) + QStringLiteral("\" app-server")
            };
            return cmd;
        }
    }
#endif
    const QString codex = QStandardPaths::findExecutable(QStringLiteral("codex"));
    if (!codex.isEmpty()) {
        arguments = {QStringLiteral("app-server")};
        return codex;
    }
    return {};
}

void CodexAppServerClient::start()
{
    if (m_process.state() != QProcess::NotRunning)
        return;

    m_stopping = false;
    m_initialized = false;
    m_stdoutBuffer.clear();
    m_pending.clear();
    emit connectedChanged();

    QStringList args;
    const QString program = resolveCodexProgram(args);
    if (program.isEmpty()) {
        setStatus(QStringLiteral("Codex non trovato"));
        setError(QStringLiteral(
            "Codex CLI non trovato. Verifica da PowerShell con 'where.exe codex' e 'codex --version'. "
            "Se lo hai appena installato, riavvia Qt Creator/Codex Meter per aggiornare il PATH."));
        scheduleRestart();
        return;
    }

    setError({});
    setStatus(QStringLiteral("Avvio Codex app-server…"));
    qInfo().noquote() << "[CodexMeter] Codex launcher:" << program << args.join(' ');
    m_process.setProgram(program);
    m_process.setArguments(args);
    m_process.setProcessChannelMode(QProcess::SeparateChannels);
    m_process.start();

    if (!m_process.waitForStarted(3000)) {
        setError(m_process.errorString());
        setStatus(QStringLiteral("Avvio fallito"));
        scheduleRestart();
        return;
    }

    QJsonObject params;
    params.insert("clientInfo", QJsonObject{
        {"name", QStringLiteral("codex-meter")},
        {"title", QStringLiteral("Codex Meter")},
        {"version", QCoreApplication::applicationVersion()}
    });
    params.insert("capabilities", QJsonObject{});

    const qint64 id = sendRequest(QStringLiteral("initialize"), params, true);
    m_pending.insert(id, RequestKind::Initialize);
}

void CodexAppServerClient::stop()
{
    m_stopping = true;
    m_restartTimer.stop();
    m_refreshTimer.stop();
    if (m_process.state() != QProcess::NotRunning) {
        m_process.closeWriteChannel();
        m_process.terminate();
        if (!m_process.waitForFinished(1200))
            m_process.kill();
    }
    m_initialized = false;
    setStatus(QStringLiteral("Stopped"));
    emit connectedChanged();
}

qint64 CodexAppServerClient::sendRequest(const QString &method, const QJsonObject &params, bool includeParams)
{
    const qint64 id = m_nextId++;
    QJsonObject obj{{"jsonrpc", QStringLiteral("2.0")}, {"id", id}, {"method", method}};
    if (includeParams)
        obj.insert("params", params);
    writeJsonLine(obj);
    return id;
}

void CodexAppServerClient::sendNotification(const QString &method, const QJsonObject &params, bool includeParams)
{
    QJsonObject obj{{"jsonrpc", QStringLiteral("2.0")}, {"method", method}};
    if (includeParams)
        obj.insert("params", params);
    writeJsonLine(obj);
}

void CodexAppServerClient::writeJsonLine(const QJsonObject &object)
{
    if (m_process.state() != QProcess::Running)
        return;
    QByteArray data = QJsonDocument(object).toJson(QJsonDocument::Compact);
    data.append('\n');
    m_process.write(data);
}

void CodexAppServerClient::refresh()
{
    if (!m_initialized || m_process.state() != QProcess::Running)
        return;
    const qint64 id = sendRequest(QStringLiteral("account/rateLimits/read"));
    m_pending.insert(id, RequestKind::RateLimits);
}

void CodexAppServerClient::onReadyReadStdout()
{
    m_stdoutBuffer += m_process.readAllStandardOutput();
    while (true) {
        const int newline = m_stdoutBuffer.indexOf('\n');
        if (newline < 0)
            break;
        const QByteArray line = m_stdoutBuffer.left(newline).trimmed();
        m_stdoutBuffer.remove(0, newline + 1);
        if (!line.isEmpty())
            processLine(line);
    }
}

void CodexAppServerClient::onReadyReadStderr()
{
    const QByteArray err = m_process.readAllStandardError();
    if (!err.trimmed().isEmpty())
        qWarning().noquote() << "[codex app-server]" << QString::fromUtf8(err).trimmed();
}

void CodexAppServerClient::processLine(const QByteArray &line)
{
    QJsonParseError error;
    const QJsonDocument doc = QJsonDocument::fromJson(line, &error);
    if (error.error != QJsonParseError::NoError || !doc.isObject()) {
        qWarning().noquote() << "Ignoro stdout non JSON da app-server:" << QString::fromUtf8(line.left(300));
        return;
    }
    processMessage(doc.object());
}

void CodexAppServerClient::processMessage(const QJsonObject &message)
{
    if (message.contains("id") && !message.value("id").isNull()) {
        handleResponse(static_cast<qint64>(message.value("id").toDouble()), message);
        return;
    }
    const QString method = message.value("method").toString();
    if (!method.isEmpty())
        handleNotification(method, message.value("params").toObject());
}

void CodexAppServerClient::handleResponse(qint64 id, const QJsonObject &message)
{
    if (!m_pending.contains(id))
        return;
    const RequestKind kind = m_pending.take(id);

    if (message.value("error").isObject()) {
        const QJsonObject error = message.value("error").toObject();
        setError(error.value("message").toString(QStringLiteral("JSON-RPC error")));
        setStatus(QStringLiteral("Errore Codex"));
        return;
    }

    const QJsonObject result = message.value("result").toObject();
    if (kind == RequestKind::Initialize) {
        sendNotification(QStringLiteral("initialized"));
        m_initialized = true;
        setStatus(QStringLiteral("Connesso"));
        emit connectedChanged();
        m_refreshTimer.start();
        refresh();
        return;
    }

    if (kind == RequestKind::RateLimits) {
        m_model->updateFromRateLimitsResult(result);
        m_lastUpdated = QDateTime::currentDateTime();
        emit lastUpdatedChanged();
        setStatus(QStringLiteral("Aggiornato"));
        setError({});
    }
}

void CodexAppServerClient::handleNotification(const QString &method, const QJsonObject &)
{
    // The app-server can emit sparse rolling rate-limit updates. A fresh read is safer
    // than trying to merge partial windows in the UI client.
    if (method == QStringLiteral("account/rateLimits/updated"))
        QTimer::singleShot(250, this, &CodexAppServerClient::refresh);
}

void CodexAppServerClient::onProcessError(QProcess::ProcessError)
{
    setError(m_process.errorString());
    setStatus(QStringLiteral("Errore processo"));
}

void CodexAppServerClient::onProcessFinished(int exitCode, QProcess::ExitStatus)
{
    m_refreshTimer.stop();
    m_initialized = false;
    emit connectedChanged();
    if (!m_stopping) {
        m_exitCode = exitCode;
        setStatus(QStringLiteral("Codex app-server terminato (%1)"));
        scheduleRestart();
    }
}

void CodexAppServerClient::setStatus(const QString &status)
{
    if (m_status == status)
        return;
    m_status = status;
    emit statusChanged();
}

QString CodexAppServerClient::status() const
{
    const auto translated = tr(m_status.toUtf8().constData());
    return m_status == QStringLiteral("Codex app-server terminato (%1)")
        ? translated.arg(m_exitCode) : translated;
}

void CodexAppServerClient::setError(const QString &error)
{
    if (m_lastError == error)
        return;
    m_lastError = error;
    emit lastErrorChanged();
}

void CodexAppServerClient::scheduleRestart()
{
    if (!m_stopping && !m_restartTimer.isActive())
        m_restartTimer.start();
}
