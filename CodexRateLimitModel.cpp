#include "CodexRateLimitModel.h"

#include <QDateTime>
#include <QLocale>
#include <QJsonValue>
#include <QtMath>
#include <algorithm>

CodexRateLimitModel::CodexRateLimitModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int CodexRateLimitModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_entries.size();
}

QVariant CodexRateLimitModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size())
        return {};

    const Entry &e = m_entries.at(index.row());
    switch (role) {
    case KeyRole: return e.key;
    case LimitIdRole: return e.limitId;
    case LimitNameRole: return e.limitName;
    case BucketRole: return e.bucket;
    case UsedPercentRole: return e.usedPercent;
    case RemainingPercentRole: return e.remainingPercent;
    case WindowMinutesRole: return e.windowMinutes;
    case ResetTimestampRole: return e.resetTimestamp;
    case ResetTextRole: return e.resetTimestamp > 0 ? QLocale().toString(QDateTime::fromSecsSinceEpoch(e.resetTimestamp), QLocale::ShortFormat) : QString();
    case IsReserveRole: return e.isReserve;
    case DisplayBucketRole: return displayBucket(e.bucket, e.windowMinutes);
    default: return {};
    }
}

QHash<int, QByteArray> CodexRateLimitModel::roleNames() const
{
    return {
        {KeyRole, "key"},
        {LimitIdRole, "limitId"},
        {LimitNameRole, "limitName"},
        {BucketRole, "bucket"},
        {UsedPercentRole, "usedPercent"},
        {RemainingPercentRole, "remainingPercent"},
        {WindowMinutesRole, "windowMinutes"},
        {ResetTimestampRole, "resetTimestamp"},
        {ResetTextRole, "resetText"},
        {IsReserveRole, "isReserve"},
        {DisplayBucketRole, "displayBucket"}
    };
}

QVariantMap CodexRateLimitModel::get(int row) const
{
    QVariantMap out;
    if (row < 0 || row >= m_entries.size())
        return out;

    const Entry &e = m_entries.at(row);
    out.insert("key", e.key);
    out.insert("limitId", e.limitId);
    out.insert("limitName", e.limitName);
    out.insert("bucket", e.bucket);
    out.insert("displayBucket", displayBucket(e.bucket, e.windowMinutes));
    out.insert("usedPercent", e.usedPercent);
    out.insert("remainingPercent", e.remainingPercent);
    out.insert("windowMinutes", e.windowMinutes);
    out.insert("resetTimestamp", e.resetTimestamp);
    out.insert("resetText", data(index(row), ResetTextRole));
    out.insert("isReserve", e.isReserve);
    return out;
}

QString CodexRateLimitModel::displayBucket(const QString &bucket, qint64 minutes)
{
    if (bucket == "Week") return tr("Settimanale");
    if (minutes == 300) return tr("5 ore");
    if (minutes > 0 && minutes % 1440 == 0) return tr("%1 g").arg(minutes / 1440);
    if (minutes > 0 && minutes % 60 == 0) return tr("%1 h").arg(minutes / 60);
    if (minutes > 0) return tr("%1 min").arg(minutes);
    return bucket == "Primary" ? tr("Primario") : bucket == "Secondary" ? tr("Secondario") : bucket;
}

void CodexRateLimitModel::retranslate()
{
    if (!m_entries.isEmpty())
        emit dataChanged(index(0), index(m_entries.size() - 1), {ResetTextRole, DisplayBucketRole});
}

QString CodexRateLimitModel::bucketLabel(qint64 minutes, const QString &fallback)
{
    if (minutes <= 0)
        return fallback;
    if (minutes == 10080)
        return QStringLiteral("Week");
    if (minutes % 1440 == 0)
        return QStringLiteral("%1d").arg(minutes / 1440);
    if (minutes % 60 == 0)
        return QStringLiteral("%1h").arg(minutes / 60);
    return QStringLiteral("%1m").arg(minutes);
}

CodexRateLimitModel::Entry CodexRateLimitModel::makeEntry(const QString &limitKey,
                                                           const QJsonObject &snapshot,
                                                           const QString &windowKey,
                                                           const QJsonObject &window)
{
    Entry e;
    e.limitId = snapshot.value("limitId").toString(limitKey);
    e.limitName = snapshot.value("limitName").toString();
    e.isReserve = limitKey.contains("reserve", Qt::CaseInsensitive)
        || e.limitId.contains("reserve", Qt::CaseInsensitive)
        || e.limitName.contains("reserve", Qt::CaseInsensitive);
    const auto used = window.value("usedPercent").toDouble(0.0);
    e.usedPercent = qBound(0, qRound(used), 100);
    e.remainingPercent = qBound(0, 100 - e.usedPercent, 100);
    e.windowMinutes = static_cast<qint64>(window.value("windowDurationMins").toDouble(0));
    e.resetTimestamp = static_cast<qint64>(window.value("resetsAt").toDouble(0));
    e.bucket = bucketLabel(e.windowMinutes, windowKey == "primary" ? QStringLiteral("Primary") : QStringLiteral("Secondary"));
    e.key = e.limitId + QLatin1Char(':') + windowKey + QLatin1Char(':') + QString::number(e.windowMinutes);
    if (e.resetTimestamp > 0) {
        e.resetText = QDateTime::fromSecsSinceEpoch(e.resetTimestamp)
                          .toLocalTime()
                          .toString(QStringLiteral("dd/MM/yyyy HH:mm"));
    }
    return e;
}

void CodexRateLimitModel::appendSnapshotEntries(const QString &limitKey,
                                                 const QJsonObject &snapshot,
                                                 QVector<Entry> &out)
{
    const QString plan = snapshot.value("planType").toString();
    if (m_planType.isEmpty() && !plan.isEmpty())
        m_planType = plan;

    for (const QString &windowKey : {QStringLiteral("primary"), QStringLiteral("secondary")}) {
        const QJsonValue value = snapshot.value(windowKey);
        if (!value.isObject())
            continue;
        const QJsonObject window = value.toObject();
        if (!window.contains("usedPercent"))
            continue;
        out.push_back(makeEntry(limitKey, snapshot, windowKey, window));
    }
}

void CodexRateLimitModel::updateFromRateLimitsResult(const QJsonObject &result)
{
    QVector<Entry> next;
    m_planType.clear();

    if (result.value("rateLimitsByLimitId").isObject()) {
        const QJsonObject all = result.value("rateLimitsByLimitId").toObject();
        for (auto it = all.constBegin(); it != all.constEnd(); ++it) {
            if (it.value().isObject())
                appendSnapshotEntries(it.key(), it.value().toObject(), next);
        }
    } else if (result.value("rateLimits").isObject()) {
        const QJsonObject snapshot = result.value("rateLimits").toObject();
        appendSnapshotEntries(snapshot.value("limitId").toString(QStringLiteral("codex")), snapshot, next);
    }

    std::sort(next.begin(), next.end(), [](const Entry &a, const Entry &b) {
        if (a.isReserve != b.isReserve)
            return !a.isReserve;
        if (a.windowMinutes == b.windowMinutes)
            return a.limitId < b.limitId;
        if (a.windowMinutes <= 0)
            return false;
        if (b.windowMinutes <= 0)
            return true;
        return a.windowMinutes < b.windowMinutes;
    });

    m_resetCredits = result.value("rateLimitResetCredits").toObject().value("availableCount").toInt(0);
    if (result.contains("ordinaryUsageAllowed") && !result.value("ordinaryUsageAllowed").isNull())
        m_ordinaryUsageAllowed = result.value("ordinaryUsageAllowed").toBool();
    else
        m_ordinaryUsageAllowed = {};

    beginResetModel();
    m_entries = std::move(next);
    endResetModel();
    emit countChanged();
    emit metadataChanged();
}

void CodexRateLimitModel::clear()
{
    beginResetModel();
    m_entries.clear();
    endResetModel();
    m_planType.clear();
    m_resetCredits = 0;
    m_ordinaryUsageAllowed = {};
    emit countChanged();
    emit metadataChanged();
}
