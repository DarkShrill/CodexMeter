#pragma once

#include <QObject>
#include <QSettings>
#include <QVariantMap>

class AppSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString viewMode READ viewMode WRITE setViewMode NOTIFY viewModeChanged)
    Q_PROPERTY(int cardStyle READ cardStyle WRITE setCardStyle NOTIFY cardStyleChanged)
    Q_PROPERTY(bool petAnimated READ petAnimated WRITE setPetAnimated NOTIFY petAnimatedChanged)
    Q_PROPERTY(int petExpression READ petExpression WRITE setPetExpression NOTIFY petExpressionChanged)
    Q_PROPERTY(QString petInfoStyle READ petInfoStyle WRITE setPetInfoStyle NOTIFY petInfoStyleChanged)
    Q_PROPERTY(double petBubbleScale READ petBubbleScale WRITE setPetBubbleScale NOTIFY petBubbleScaleChanged)
    Q_PROPERTY(QVariantMap petLayout READ petLayout NOTIFY petLayoutChanged)
    Q_PROPERTY(bool launchAtStartup READ launchAtStartup WRITE setLaunchAtStartup NOTIFY launchAtStartupChanged)
    Q_PROPERTY(bool taskbarMonitor READ taskbarMonitor WRITE setTaskbarMonitor NOTIFY taskbarMonitorChanged)
    Q_PROPERTY(bool alwaysOnTop READ alwaysOnTop WRITE setAlwaysOnTop NOTIFY alwaysOnTopChanged)
    Q_PROPERTY(int refreshSeconds READ refreshSeconds WRITE setRefreshSeconds NOTIFY refreshSecondsChanged)
    Q_PROPERTY(double scale READ scale WRITE setScale NOTIFY scaleChanged)
    Q_PROPERTY(double widgetOpacity READ widgetOpacity WRITE setWidgetOpacity NOTIFY widgetOpacityChanged)
    Q_PROPERTY(bool hasSavedPosition READ hasSavedPosition NOTIFY positionChanged)
    Q_PROPERTY(int savedX READ savedX NOTIFY positionChanged)
    Q_PROPERTY(int savedY READ savedY NOTIFY positionChanged)

public:
    explicit AppSettings(QObject *parent = nullptr);
    QString language() const;
    static QStringList languageCodes();
    void setLanguage(const QString &code);

    QString viewMode() const;
    int cardStyle() const;
    bool petAnimated() const;
    int petExpression() const;
    QString petInfoStyle() const;
    double petBubbleScale() const;
    QVariantMap petLayout() const;
    Q_INVOKABLE void setPetLayoutOffset(const QString &element, double x, double y);
    Q_INVOKABLE void resetPetLayout();
    bool launchAtStartup() const;
    bool taskbarMonitor() const;
    bool alwaysOnTop() const;
    int refreshSeconds() const;
    double scale() const;
    double widgetOpacity() const;
    bool hasSavedPosition() const;
    int savedX() const;
    int savedY() const;

    void setViewMode(const QString &value);
    void setCardStyle(int value);
    void setPetAnimated(bool value);
    void setPetExpression(int value);
    void setPetInfoStyle(const QString &value);
    void setPetBubbleScale(double value);
    void setLaunchAtStartup(bool value);
    void setTaskbarMonitor(bool value);
    void setAlwaysOnTop(bool value);
    void setRefreshSeconds(int value);
    void setScale(double value);
    void setWidgetOpacity(double value);

    Q_INVOKABLE void savePosition(int x, int y);
    Q_INVOKABLE void clearPosition();
    Q_INVOKABLE QVariantMap initialWindowPosition(int width, int height) const;
    Q_INVOKABLE QVariantMap defaultWindowPosition(int width, int height) const;
    Q_INVOKABLE QVariantMap availableScreenGeometry(int x, int y) const;

signals:
    void languageChanged();
    void viewModeChanged();
    void cardStyleChanged();
    void petAnimatedChanged();
    void petExpressionChanged();
    void petInfoStyleChanged();
    void petBubbleScaleChanged();
    void petLayoutChanged();
    void launchAtStartupChanged();
    void taskbarMonitorChanged();
    void alwaysOnTopChanged();
    void refreshSecondsChanged();
    void scaleChanged();
    void widgetOpacityChanged();
    void positionChanged();

private:
    bool readStartupState() const;
    void applyStartupState(bool enabled);

    QSettings m_settings;
};
