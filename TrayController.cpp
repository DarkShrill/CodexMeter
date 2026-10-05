#include "TrayController.h"
#include "AppSettings.h"
#include "CodexAppServerClient.h"

#include <QAction>
#include <QActionGroup>
#include <QApplication>
#include <QIcon>
#include <QMenu>
#include <QSignalBlocker>

TrayController::TrayController(AppSettings *settings, CodexAppServerClient *client, QObject *parent)
    : QObject(parent), m_settings(settings), m_client(client)
{
    m_menu = new QMenu();

    m_visibilityAction = m_menu->addAction(tr("Nascondi Codex Meter"));
    m_refreshAction = m_menu->addAction(tr("Aggiorna ora"));
    m_settingsAction = m_menu->addAction(tr("Impostazioni…"));
    m_languageMenu = m_menu->addMenu(tr("Lingua"));
    auto *languages = new QActionGroup(m_languageMenu);
    languages->setExclusive(true);
    const QStringList names = {QStringLiteral("English"), QStringLiteral("Italiano"),
        QStringLiteral("Français"), QStringLiteral("Deutsch"), QStringLiteral("Español"),
        QStringLiteral("Português"), QStringLiteral("Nederlands"), QStringLiteral("Polski"),
        QStringLiteral("中文简体"), QStringLiteral("Русский"), QStringLiteral("Türkçe")};
    const auto codes = AppSettings::languageCodes();
    for (int i = 0; i < codes.size(); ++i) {
        auto *action = m_languageMenu->addAction(names.at(i));
        action->setData(codes.at(i));
        action->setCheckable(true);
        languages->addAction(action);
        connect(action, &QAction::triggered, this, [this, code = codes.at(i)] {
            m_settings->setLanguage(code);
        });
    }
    m_menu->addSeparator();
    m_startupAction = m_menu->addAction(tr("Avvia con Windows"));
    m_startupAction->setCheckable(true);
    syncStartupAction();
    m_menu->addSeparator();
    m_quitAction = m_menu->addAction(tr("Esci"));
    retranslate();

    connect(m_visibilityAction, &QAction::triggered, this, [this] {
        if (m_widgetVisible) emit hideRequested();
        else emit showRequested();
    });
    connect(m_refreshAction, &QAction::triggered, m_client, &CodexAppServerClient::refresh);
    connect(m_settingsAction, &QAction::triggered, this, &TrayController::settingsRequested);
    connect(m_startupAction, &QAction::toggled, m_settings, &AppSettings::setLaunchAtStartup);
    connect(m_settings, &AppSettings::launchAtStartupChanged, this, &TrayController::syncStartupAction);
    connect(m_quitAction, &QAction::triggered, this, &TrayController::quit);

    m_tray.setIcon(QIcon(QStringLiteral(":/assets/darkshrill-icon.png")));
    m_tray.setToolTip(QStringLiteral("Codex Meter"));
    m_tray.setContextMenu(m_menu);
    connect(&m_tray, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick)
            emit showRequested();
    });
    m_tray.show();
}

void TrayController::setWidgetVisible(bool visible)
{
    m_widgetVisible = visible;
    m_visibilityAction->setText(visible ? tr("Nascondi Codex Meter") : tr("Mostra Codex Meter"));
}

void TrayController::retranslate()
{
    setWidgetVisible(m_widgetVisible);
    m_refreshAction->setText(tr("Aggiorna ora"));
    m_settingsAction->setText(tr("Impostazioni…"));
    m_startupAction->setText(tr("Avvia con Windows"));
    m_quitAction->setText(tr("Esci"));
    m_languageMenu->setTitle(tr("Lingua"));
    for (auto *action : m_languageMenu->actions())
        action->setChecked(action->data().toString() == m_settings->language());
}

void TrayController::syncStartupAction()
{
    const QSignalBlocker blocker(m_startupAction);
    m_startupAction->setChecked(m_settings->launchAtStartup());
}

void TrayController::quit()
{
    if (m_quitting) return;
    m_quitting = true;
    emit quittingChanged();
    m_client->stop();
    m_tray.hide();
    qApp->quit();
}
