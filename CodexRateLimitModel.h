#pragma once

#include <QAbstractListModel>
#include <QJsonObject>
#include <QVariantMap>
#include <QVector>

class CodexRateLimitModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(QString planType READ planType NOTIFY metadataChanged)
    Q_PROPERTY(int resetCredits READ resetCredits NOTIFY metadataChanged)
    Q_PROPERTY(QVariant ordinaryUsageAllowed READ ordinaryUsageAllowed NOTIFY metadataChanged)

public:
    enum Roles {
        KeyRole = Qt::UserRole + 1,
        LimitIdRole,
        LimitNameRole,
        BucketRole,
        UsedPercentRole,
        RemainingPercentRole,
        WindowMinutesRole,
        ResetTimestampRole,
        ResetTextRole,
        IsReserveRole,
        DisplayBucketRole
    };

    explicit CodexRateLimitModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString planType() const { return m_planType; }
    int resetCredits() const { return m_resetCredits; }
    QVariant ordinaryUsageAllowed() const { return m_ordinaryUsageAllowed; }

    Q_INVOKABLE QVariantMap get(int row) const;
    void retranslate();
    static QString displayBucket(const QString &bucket, qint64 minutes);
    void updateFromRateLimitsResult(const QJsonObject &result);
    void clear();

signals:
    void countChanged();
    void metadataChanged();

private:
    struct Entry {
        QString key;
        QString limitId;
        QString limitName;
        QString bucket;
        int usedPercent = 0;
        int remainingPercent = 100;
        qint64 windowMinutes = 0;
        qint64 resetTimestamp = 0;
        QString resetText;
        bool isReserve = false;
    };

    static QString bucketLabel(qint64 minutes, const QString &fallback);
    static Entry makeEntry(const QString &limitKey,
                           const QJsonObject &snapshot,
                           const QString &windowKey,
                           const QJsonObject &window);
    void appendSnapshotEntries(const QString &limitKey, const QJsonObject &snapshot, QVector<Entry> &out);

    QVector<Entry> m_entries;
    QString m_planType;
    int m_resetCredits = 0;
    QVariant m_ordinaryUsageAllowed;
};
