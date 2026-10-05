#include "Localization.h"
#include <QCoreApplication>
#include <QFile>
#include <QJsonDocument>
#include <QLocale>

Localization::Localization(QObject *parent) : QTranslator(parent) {}

bool Localization::setLanguage(const QString &code)
{
    QFile file(QStringLiteral(":/translations/%1.json").arg(code));
    if (!file.open(QIODevice::ReadOnly)) return false;
    const auto document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject()) return false;
    QCoreApplication::removeTranslator(this);
    m_catalog = document.object();
    QLocale::setDefault(QLocale(code));
    QCoreApplication::installTranslator(this);
    return true;
}

QString Localization::translate(const char *, const char *sourceText, const char *, int) const
{
    return m_catalog.value(QString::fromUtf8(sourceText)).toString();
}
