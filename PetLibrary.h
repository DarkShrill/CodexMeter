#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class PetLibrary : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList customPets READ customPets NOTIFY customPetsChanged)
    Q_PROPERTY(int lastImportedPetId READ lastImportedPetId NOTIFY customPetsChanged)

public:
    explicit PetLibrary(QObject *parent = nullptr);
    QVariantList customPets() const;
    int lastImportedPetId() const;
    Q_INVOKABLE bool importPackage(const QString &path);
    Q_INVOKABLE QVariantMap pet(int id) const;

signals:
    void customPetsChanged();
    void importFinished(bool success, const QString &message);

private:
    void load();
    QVariantList m_pets;
    int m_lastImportedPetId = 0;
};
