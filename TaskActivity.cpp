#include "TaskActivity.h"
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <algorithm>

TaskActivity::TaskActivity(QObject *parent, const QString &sessionRoot, bool startTimer)
    : QObject(parent), m_sessionRoot(sessionRoot) {
    if (m_sessionRoot.isEmpty()) {
        QString home = qEnvironmentVariable("CODEX_HOME");
        if (home.isEmpty()) home = QDir::homePath() + "/.codex";
        m_sessionRoot = home + "/sessions";
    }
    connect(&m_timer, &QTimer::timeout, this, &TaskActivity::poll);
    m_settle.setSingleShot(true);
    m_settle.setInterval(2000);
    connect(&m_settle, &QTimer::timeout, this, [this] {
        m_outcome.clear();
        poll();
    });
    if (startTimer) m_timer.start(750);
    poll();
}

bool TaskActivity::working() const {
    for (const auto &session : m_sessions)
        if (session.active && !session.ignored) return true;
    return false;
}

void TaskActivity::setState(const QString &state) {
    if (m_state == state) return;
    m_state = state;
    emit stateChanged();
}

void TaskActivity::consume(Session &s, const QJsonObject &record, bool notify) {
    const QString recordType = record.value("type").toString();
    const auto payload = record.value("payload").toObject();
    const QString type = payload.value("type").toString();
    if (recordType == "session_meta") {
        s.ignored = payload.value("source").toObject().contains("subagent");
        s.id = payload.value("id").toString();
        s.title = payload.value("thread_name").toString(payload.value("title").toString());
        s.workspace = payload.value("cwd").toString();
        return;
    }
    if (s.ignored) return;
    QDateTime timestamp = QDateTime::fromString(record.value("timestamp").toString(), Qt::ISODateWithMs);
    if (!timestamp.isValid()) timestamp = QDateTime::currentDateTimeUtc();
    if (!s.lastEventAt.isValid() || timestamp > s.lastEventAt) s.lastEventAt = timestamp;
    auto update = [&](const QString &state) { s.state = state; s.changed = timestamp; };
    // A long running turn can start before the recent tail read at startup.
    // Fresh reasoning/tool events still identify it until a lifecycle marker is seen.
    if (s.inferTailActivity && !s.active && timestamp.secsTo(QDateTime::currentDateTimeUtc()) < 3600
            && ((recordType == "response_item" && (type == "reasoning" || type == "function_call" || type == "custom_tool_call"))
                || (recordType == "event_msg" && type == "item_completed")))
        s.active = true;
    if (recordType == "event_msg") {
        if (type == "task_started") {
            s.inferTailActivity = false;
            s.active = true;
            s.reviewing = false;
            s.inputCalls.clear();
            update("thinking");
        } else if (type == "task_complete" || type == "task_completed" || type == "turn_aborted") {
            s.inferTailActivity = false;
            const bool active = s.active;
            s.active = false;
            s.reviewing = false;
            s.inputCalls.clear();
            update("idle");
            if (active && notify && timestamp >= m_startedAt) {
                m_outcome = type == "turn_aborted" ? "failed" : "completed";
                m_outcomeAt = timestamp;
                m_settle.start();
                if (type != "turn_aborted") emit taskCompleted();
            }
        } else if (s.active && type == "error") {
            update("failed");
        } else if (s.active && type == "entered_review_mode") {
            s.reviewing = true;
            update("review");
        } else if (s.active && type == "exited_review_mode") {
            s.reviewing = false;
            update("thinking");
        } else if (s.active && type == "item_completed") {
            const auto item = payload.value("item").toObject();
            const QString itemType = item.value("type").toString();
            if (!s.inputCalls.isEmpty()) return;
            if (s.reviewing) { update("review"); return; }
            if (itemType == "Reasoning") update("thinking");
            else if (itemType == "CommandExecution" || itemType == "FileChange" || itemType == "McpToolCall") {
                const QString status = item.value("status").toString().toLower();
                const bool failed = status == "failed" || (item.contains("exit_code") && !item.value("exit_code").isNull() && item.value("exit_code").toInt() != 0);
                update(failed ? "failed" : "working");
            }
        }
        return;
    }
    if (recordType != "response_item" || !s.active) return;
    if (type == "message" && payload.value("role").toString() == "user") {
        s.inputCalls.clear();
        update(s.reviewing ? "review" : "thinking");
    } else if (type == "reasoning") {
        if (s.inputCalls.isEmpty() && s.state != "review") update("thinking");
    } else if (type == "function_call" || type == "custom_tool_call") {
        const QString name = payload.value("name").toString();
        if (name.contains("request_user_input")) {
            s.inputCalls.insert(payload.value("call_id").toString(), name.contains("async"));
            update("waiting");
        } else if (s.inputCalls.isEmpty()) update(s.reviewing ? "review" : "working");
    } else if (type == "function_call_output" || type == "custom_tool_call_output") {
        const QString callId = payload.value("call_id").toString();
        // Async acknowledgement means the question is pending, not answered.
        if (s.inputCalls.contains(callId) && !s.inputCalls.value(callId)) s.inputCalls.remove(callId);
        if (s.inputCalls.isEmpty()) update(s.reviewing ? "review" : "thinking");
    }
}

void TaskActivity::poll() {
    const bool wasWorking = working();
    const auto now = QDateTime::currentDateTimeUtc();
    readTaskNames();
    QDirIterator files(m_sessionRoot, {"*.jsonl"}, QDir::Files, QDirIterator::Subdirectories);
    while (files.hasNext()) {
        const QString path = files.next();
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly)) continue;
        const bool known = m_sessions.contains(path);
        auto &s = m_sessions[path];
        if (s.offset > file.size()) s = Session{};
        if (!known) {
            const auto firstLine = file.readLine();
            const auto metadata = QJsonDocument::fromJson(firstLine).object();
            if (firstLine.endsWith('\n') && metadata.value("type").toString() == "session_meta")
                consume(s, metadata, false);
            s.offset = qMax<qint64>(0, file.size() - 262144);
            s.inferTailActivity = s.offset > 0;
            file.seek(s.offset);
            if (s.offset > 0) file.readLine();
        } else file.seek(s.offset);
        while (!file.atEnd()) {
            const qint64 lineStart = file.pos();
            const auto line = file.readLine();
            if (!line.endsWith('\n')) { file.seek(lineStart); break; }
            consume(s, QJsonDocument::fromJson(line).object(), !m_initial);
        }
        s.offset = file.pos();
        // Windows can retain an old last-write time while Codex holds the log open.
        // The timestamps inside the log reflect ongoing and resumed turns.
        if (s.lastEventAt.isValid() && s.lastEventAt.secsTo(now) > 3600) {
            s.active = false;
            s.inputCalls.clear();
        }
    }
    m_initial = false;
    for (auto it = m_sessions.begin(); it != m_sessions.end();) {
        if (!QFileInfo::exists(it.key())) it = m_sessions.erase(it);
        else ++it;
    }
    QString next = "idle";
    QDateTime latest;
    // Follow the most recently active chat rather than filesystem enumeration order.
    for (const auto &s : m_sessions) {
        if (s.active && !s.ignored && (!latest.isValid() || s.changed > latest)) { next = s.state; latest = s.changed; }
    }
    if (!m_outcome.isEmpty() && (!latest.isValid() || m_outcomeAt >= latest)) next = m_outcome;
    setState(next);
    updateActiveTasks();
    if (wasWorking != working()) emit workingChanged();
}

void TaskActivity::readTaskNames() {
    QFile index(QDir(m_sessionRoot).absoluteFilePath("../session_index.jsonl"));
    if (!index.open(QIODevice::ReadOnly)) return;
    if (m_indexOffset > index.size()) {
        m_indexOffset = 0;
        m_taskNames.clear();
    }
    index.seek(m_indexOffset);
    while (!index.atEnd()) {
        const qint64 lineStart = index.pos();
        const auto line = index.readLine();
        if (!line.endsWith('\n')) { index.seek(lineStart); break; }
        const auto row = QJsonDocument::fromJson(line).object();
        const QString id = row.value("id").toString();
        const QString title = row.value("thread_name").toString().trimmed();
        if (!id.isEmpty() && !title.isEmpty()) m_taskNames.insert(id, title);
    }
    m_indexOffset = index.pos();
}

void TaskActivity::updateActiveTasks() {
    QHash<QString, QVariantMap> tasks;
    QHash<QString, QDateTime> latest;
    for (auto it = m_sessions.cbegin(); it != m_sessions.cend(); ++it) {
        const auto &s = it.value();
        if (!s.active || s.ignored) continue;
        const QString id = s.id.isEmpty() ? it.key() : s.id;
        if (tasks.contains(id) && latest.value(id) > s.changed) continue;
        QString title = m_taskNames.value(s.id, s.title);
        if (title.isEmpty()) {
            const QString workspace = QFileInfo(s.workspace).fileName();
            title = workspace.isEmpty() ? QStringLiteral("Task %1").arg(QFileInfo(it.key()).completeBaseName().right(8))
                                        : QStringLiteral("%1 · %2").arg(workspace, id.right(8));
        }
        tasks.insert(id, {{"id", id}, {"title", title}, {"state", s.state}});
        latest.insert(id, s.changed);
    }
    QVariantList active;
    for (const auto &task : tasks) active.append(task);
    std::sort(active.begin(), active.end(), [](const QVariant &a, const QVariant &b) {
        const auto left = a.toMap(), right = b.toMap();
        const int order = QString::localeAwareCompare(left.value("title").toString(), right.value("title").toString());
        return order == 0 ? left.value("id").toString() < right.value("id").toString() : order < 0;
    });
    if (active == m_activeTasks) return;
    m_activeTasks = active;
    emit activeTasksChanged();
}
