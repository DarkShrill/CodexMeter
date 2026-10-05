#pragma once
#include <QTranslator>
#include <QJsonObject>

// Catalogs use the source text as key, shared between C++ and QML contexts.
class Localization : public QTranslator
{
public:
    explicit Localization(QObject *parent = nullptr);
    bool setLanguage(const QString &code);
    bool isEmpty() const override { return false; }
    QString translate(const char *context, const char *sourceText,
                      const char *disambiguation = nullptr, int n = -1) const override;
private:
    QJsonObject m_catalog;
};
