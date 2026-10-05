#pragma once

#include <QObject>
#include <QSystemTrayIcon>

class AppSettings;
class CodexAppServerClient;
class QAction;
class QMenu;

class TrayController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool quitting READ quitting NOTIFY quittingChanged)

public:
    explicit TrayController(AppSettings *settings, CodexAppServerClient *client, QObject *parent = nullptr);
    bool quitting() const { return m_quitting; }

signals:
    void showRequested();
    void hideRequested();
    void settingsRequested();
    void quittingChanged();

public slots:
    void quit();
    void setWidgetVisible(bool visible);
    void retranslate();

private:
    void syncStartupAction();

    AppSettings *m_settings = nullptr;
    CodexAppServerClient *m_client = nullptr;
    QSystemTrayIcon m_tray;
    QMenu *m_menu = nullptr;
    QAction *m_startupAction = nullptr;
    QAction *m_visibilityAction = nullptr;
    QAction *m_refreshAction = nullptr;
    QAction *m_settingsAction = nullptr;
    QAction *m_quitAction = nullptr;
    QMenu *m_languageMenu = nullptr;
    bool m_widgetVisible = true;
    bool m_quitting = false;
};
