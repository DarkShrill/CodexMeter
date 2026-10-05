#include "AppSettings.h"

#include <QCoreApplication>
#include <QDir>
#include <QGuiApplication>
#include <QRect>
#include <QScreen>
#include <QLocale>
#include <QtGlobal>
#include <limits>

AppSettings::AppSettings(QObject *parent)
    : QObject(parent),
      m_settings(QSettings::defaultFormat(), QSettings::UserScope,
                 QCoreApplication::organizationName(), QCoreApplication::applicationName())
{
    // Enable the new continuous Kira player once; later toggle choices persist.
    if (!m_settings.value("ui/kiraContinuousPlayback", false).toBool()) {
        if (petExpression() == 0)
            m_settings.setValue("ui/petAnimated", true);
        m_settings.setValue("ui/kiraContinuousPlayback", true);
    }
}

QString AppSettings::viewMode() const
{
    const QString stored = m_settings.value(QStringLiteral("ui/viewMode"), QStringLiteral("compact")).toString();
    // Compatibility with the first prototype.
    if (stored == QStringLiteral("rings"))
        return QStringLiteral("compact");
    if (stored == QStringLiteral("notch"))
        return QStringLiteral("pill");
    if (stored == QStringLiteral("compact") || stored == QStringLiteral("pill") || stored == QStringLiteral("pet"))
        return stored;
    return QStringLiteral("compact");
}

QStringList AppSettings::languageCodes()
{
    return {"en", "it", "fr", "de", "es", "pt", "nl", "pl", "zh_CN", "ru", "tr"};
}

QString AppSettings::language() const
{
    QString system = QLocale::system().name();
    system = system.startsWith("zh") ? QStringLiteral("zh_CN") : system.section('_', 0, 0);
    const QString code = m_settings.value("ui/language", system).toString();
    return languageCodes().contains(code) ? code : QStringLiteral("en");
}

void AppSettings::setLanguage(const QString &code)
{
    if (!languageCodes().contains(code)) return;
    const bool changed = language() != code;
    m_settings.setValue("ui/language", code);
    if (changed) emit languageChanged();
}

int AppSettings::petExpression() const
{
    const int stored = m_settings.value(QStringLiteral("ui/petExpression"), 0).toInt();
    return stored == 1 || stored == 4 || stored == 5 || stored == 6 || stored == 7 || stored == 8 || stored == 9 || stored == 10 || stored >= 1000 ? stored : 0;
}

bool AppSettings::taskbarMonitor() const
{
    return m_settings.value(QStringLiteral("ui/taskbarMonitor"), false).toBool();
}

QString AppSettings::petInfoStyle() const
{
    return m_settings.value(QStringLiteral("ui/petInfoStyle"), QStringLiteral("minimal")).toString() == QStringLiteral("bubble")
        ? QStringLiteral("bubble") : QStringLiteral("minimal");
}

void AppSettings::setPetInfoStyle(const QString &value)
{
    if ((value != QStringLiteral("minimal") && value != QStringLiteral("bubble")) || petInfoStyle() == value)
        return;
    m_settings.setValue(QStringLiteral("ui/petInfoStyle"), value);
    emit petInfoStyleChanged();
}

double AppSettings::petBubbleScale() const
{
    return qBound(0.60, m_settings.value(QStringLiteral("ui/petBubbleScale"), 1.0).toDouble(), 1.80);
}

void AppSettings::setPetBubbleScale(double value)
{
    if (!qIsFinite(value)) return;
    value = qBound(0.60, value, 1.80);
    if (qFuzzyCompare(petBubbleScale(), value)) return;
    m_settings.setValue(QStringLiteral("ui/petBubbleScale"), value);
    emit petBubbleScaleChanged();
}

void AppSettings::setTaskbarMonitor(bool value)
{
    if (taskbarMonitor() == value) return;
    m_settings.setValue(QStringLiteral("ui/taskbarMonitor"), value);
    emit taskbarMonitorChanged();
}

QVariantMap AppSettings::petLayout() const
{
    return m_settings.value(QStringLiteral("ui/petLayout/%1").arg(petExpression())).toMap();
}

void AppSettings::setPetLayoutOffset(const QString &element, double x, double y)
{
    if (!QStringList{QStringLiteral("bubble"), QStringLiteral("status"),
                     QStringLiteral("tasksPopup"), QStringLiteral("details")}.contains(element)
        || !qIsFinite(x) || !qIsFinite(y)) return;
    auto layout = petLayout();
    const double maxOffset = element == QStringLiteral("tasksPopup") ? 16384.0 : 600.0;
    layout.insert(element, QVariantMap{{QStringLiteral("x"), qBound(-maxOffset, x, maxOffset)},
                                      {QStringLiteral("y"), qBound(-maxOffset, y, maxOffset)}});
    m_settings.setValue(QStringLiteral("ui/petLayout/%1").arg(petExpression()), layout);
    emit petLayoutChanged();
}

void AppSettings::resetPetLayout()
{
    m_settings.remove(QStringLiteral("ui/petLayout/%1").arg(petExpression()));
    emit petLayoutChanged();
}

bool AppSettings::alwaysOnTop() const
{
    return m_settings.value(QStringLiteral("ui/alwaysOnTop"), true).toBool();
}

int AppSettings::refreshSeconds() const
{
    return qBound(15, m_settings.value(QStringLiteral("network/refreshSeconds"), 60).toInt(), 3600);
}

double AppSettings::scale() const
{
    return qBound(0.60, m_settings.value(QStringLiteral("ui/scale"), 0.85).toDouble(), 1.60);
}

double AppSettings::widgetOpacity() const
{
    return qBound(0.40, m_settings.value(QStringLiteral("ui/opacity"), 1.0).toDouble(), 1.0);
}

bool AppSettings::launchAtStartup() const { return readStartupState(); }
bool AppSettings::hasSavedPosition() const { return m_settings.contains(QStringLiteral("window/x")) && m_settings.contains(QStringLiteral("window/y")); }
int AppSettings::savedX() const { return m_settings.value(QStringLiteral("window/x"), 0).toInt(); }
int AppSettings::savedY() const { return m_settings.value(QStringLiteral("window/y"), 0).toInt(); }

void AppSettings::setViewMode(const QString &value)
{
    if (value != QStringLiteral("compact") && value != QStringLiteral("pill") && value != QStringLiteral("pet"))
        return;
    if (viewMode() == value)
        return;
    m_settings.setValue(QStringLiteral("ui/viewMode"), value);
    emit viewModeChanged();
}

void AppSettings::setPetExpression(int value)
{
    if (value != 0 && value != 1 && value != 4 && value != 5 && value != 6 && value != 7 && value != 8 && value != 9 && value != 10 && value < 1000) value = 0;
    if (petExpression() == value)
        return;
    m_settings.setValue(QStringLiteral("ui/petExpression"), value);
    emit petExpressionChanged();
    emit petLayoutChanged();
}

void AppSettings::setLaunchAtStartup(bool value)
{
    if (launchAtStartup() == value)
        return;
    applyStartupState(value);
    emit launchAtStartupChanged();
}

void AppSettings::setAlwaysOnTop(bool value)
{
    if (alwaysOnTop() == value)
        return;
    m_settings.setValue(QStringLiteral("ui/alwaysOnTop"), value);
    emit alwaysOnTopChanged();
}

void AppSettings::setRefreshSeconds(int value)
{
    value = qBound(15, value, 3600);
    if (refreshSeconds() == value)
        return;
    m_settings.setValue(QStringLiteral("network/refreshSeconds"), value);
    emit refreshSecondsChanged();
}

void AppSettings::setScale(double value)
{
    value = qBound(0.60, value, 1.60);
    if (qFuzzyCompare(scale(), value))
        return;
    m_settings.setValue(QStringLiteral("ui/scale"), value);
    emit scaleChanged();
}

void AppSettings::setWidgetOpacity(double value)
{
    value = qBound(0.40, value, 1.0);
    if (qFuzzyCompare(widgetOpacity(), value))
        return;
    m_settings.setValue(QStringLiteral("ui/opacity"), value);
    emit widgetOpacityChanged();
}

void AppSettings::savePosition(int x, int y)
{
    m_settings.setValue(QStringLiteral("window/x"), x);
    m_settings.setValue(QStringLiteral("window/y"), y);
    emit positionChanged();
}

void AppSettings::clearPosition()
{
    m_settings.remove(QStringLiteral("window/x"));
    m_settings.remove(QStringLiteral("window/y"));
    emit positionChanged();
}

QVariantMap AppSettings::defaultWindowPosition(int width, int height) const
{
    QScreen *screen = QGuiApplication::primaryScreen();
    if (!screen)
        return {{QStringLiteral("x"), 0}, {QStringLiteral("y"), 0}};

    const QRect available = screen->availableGeometry();
    const int x = qMax(available.left(), available.right() - width - 25);
    const int y = qMin(available.bottom() - height + 1, available.top() + 34);
    return {{QStringLiteral("x"), x}, {QStringLiteral("y"), qMax(available.top(), y)}};
}

QVariantMap AppSettings::availableScreenGeometry(int x, int y) const
{
    QScreen *screen = QGuiApplication::screenAt(QPoint(x, y));
    if (!screen) {
        qint64 closestDistance = std::numeric_limits<qint64>::max();
        for (QScreen *candidate : QGuiApplication::screens()) {
            const QRect area = candidate->availableGeometry();
            const qint64 dx = qint64(x) - qBound(area.left(), x, area.right());
            const qint64 dy = qint64(y) - qBound(area.top(), y, area.bottom());
            const qint64 distance = dx * dx + dy * dy;
            if (distance < closestDistance) { screen = candidate; closestDistance = distance; }
        }
    }
    const QRect area = screen ? screen->availableGeometry() : QRect(0, 0, 1920, 1080);
    return {{QStringLiteral("x"), area.x()}, {QStringLiteral("y"), area.y()},
            {QStringLiteral("width"), area.width()}, {QStringLiteral("height"), area.height()}};
}

QVariantMap AppSettings::initialWindowPosition(int width, int height) const
{
    if (hasSavedPosition()) {
        const QRect candidate(savedX(), savedY(), qMax(1, width), qMax(1, height));
        for (QScreen *screen : QGuiApplication::screens()) {
            if (candidate.intersects(screen->availableGeometry()))
                return {{QStringLiteral("x"), candidate.x()}, {QStringLiteral("y"), candidate.y()}};
        }
    }

    return defaultWindowPosition(width, height);
}

bool AppSettings::readStartupState() const
{
#ifdef Q_OS_WIN
    QSettings runKey(QStringLiteral("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"),
                     QSettings::NativeFormat);
    return runKey.contains(QCoreApplication::applicationName());
#else
    return false;
#endif
}

void AppSettings::applyStartupState(bool enabled)
{
#ifdef Q_OS_WIN
    QSettings runKey(QStringLiteral("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"),
                     QSettings::NativeFormat);
    const QString key = QCoreApplication::applicationName();
    if (enabled) {
        const QString exe = QDir::toNativeSeparators(QCoreApplication::applicationFilePath());
        runKey.setValue(key, QStringLiteral("\"") + exe + QStringLiteral("\" --autostart"));
    } else {
        runKey.remove(key);
    }
#else
    Q_UNUSED(enabled)
#endif
}

int AppSettings::cardStyle() const { return qBound(0, m_settings.value("ui/cardStyle", 1).toInt(), 2); }
bool AppSettings::petAnimated() const { return m_settings.value("ui/petAnimated", petExpression() == 0).toBool(); }
void AppSettings::setCardStyle(int value) {
    value = qBound(0, value, 2);
    if (cardStyle() == value) return;
    m_settings.setValue("ui/cardStyle", value);
    emit cardStyleChanged();
}
void AppSettings::setPetAnimated(bool value) {
    if (petAnimated() == value) return;
    m_settings.setValue("ui/petAnimated", value);
    emit petAnimatedChanged();
}
