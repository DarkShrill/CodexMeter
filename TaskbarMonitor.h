#pragma once
#include <QObject>
#include <QRect>
#include <QTimer>
#include <QVector>
class AppSettings;
class CodexRateLimitModel;

// Owns only our native surface. Explorer's windows and layout are never modified.
class TaskbarMonitor : public QObject
{
    Q_OBJECT
public:
    TaskbarMonitor(AppSettings *settings, CodexRateLimitModel *model, QObject *parent = nullptr);
    ~TaskbarMonitor() override;
    static QRect freeSlot(const QRect &bounds, const QVector<QRect> &occupied, const QSize &size);
    quintptr nativeHandle() const { return m_window; }
    QString summary() const;
public slots:
    void refresh();
signals:
    void activated();
private:
    void render();
    void closeSurface();
    void applyLayout(quintptr shell, const QVector<QRect> &occupied);
    AppSettings *m_settings;
    CodexRateLimitModel *m_model;
    QTimer m_timer;
    quintptr m_window = 0;
    quintptr m_tooltip = 0;
    QString m_tooltipText;
    QSize m_size;
    bool m_scanRunning = false;
};
