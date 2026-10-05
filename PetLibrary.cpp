#include <QCoreApplication>
#include "PetLibrary.h"

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QImageReader>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QUrl>
#include <QMap>
#include <QUuid>

namespace {
QString libraryPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
        + QStringLiteral("/custom-pets");
}

QString safeName(QString name)
{
    name = name.trimmed();
    name.replace(QRegularExpression(QStringLiteral("[^\\p{L}\\p{N} _-]")), QString());
    return name.left(32).trimmed();
}

QJsonObject findManifest(const QString &root, QString *path)
{
    QDirIterator it(root, QStringList{QStringLiteral("frames-manifest.json")},
                    QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        const QString candidate = it.next();
        QFile file(candidate);
        if (!file.open(QIODevice::ReadOnly)) continue;
        QJsonParseError error;
        const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &error);
        if (error.error == QJsonParseError::NoError && doc.isObject()) {
            *path = candidate;
            return doc.object();
        }
    }
    return {};
}

QString localFramePath(const QString &manifestDir, const QString &state, const QString &entry)
{
    QString normalized = entry;
    normalized.replace('\\', '/');
    QString relative;
    // Older generated manifests may contain absolute paths from the creator's PC.
    // Resolve those by their final state/frame components instead of trusting them.
    if (QFileInfo(normalized).isAbsolute() || normalized.contains(':'))
        relative = state + '/' + QFileInfo(normalized).fileName();
    else
        relative = normalized;
    const QString base = QDir::fromNativeSeparators(QFileInfo(manifestDir).absolutePath());
    QString path = QDir::fromNativeSeparators(QDir::cleanPath(QDir(base).filePath(relative)));
    if (!QFileInfo(path).isFile() && QFileInfo(base).fileName() == QStringLiteral("frames")
        && relative.startsWith(QStringLiteral("frames/")))
        path = QDir::fromNativeSeparators(QDir::cleanPath(QDir(base).filePath(relative.mid(7))));
    if (!path.startsWith(base + QLatin1Char('/'), Qt::CaseInsensitive) || !QFileInfo(path).isFile())
        return {};
    return path;
}

bool validatePackage(const QString &root, QVariantMap *result, QString *errorText)
{
    QString manifestPath;
    const QJsonObject manifest = findManifest(root, &manifestPath);
    if (manifest.isEmpty()) {
        *errorText = QCoreApplication::translate("PetLibrary", "Non trovo frames-manifest.json. Seleziona la cartella del pet o uno ZIP che lo contenga.");
        return false;
    }
    if (manifest.value(QStringLiteral("schema")).toString() != QStringLiteral("codexmeter-16-pose-extension")) {
        *errorText = QCoreApplication::translate("PetLibrary", "Il manifest non usa lo schema codexmeter-16-pose-extension.");
        return false;
    }
    const QJsonArray rows = manifest.value(QStringLiteral("rows")).toArray();
    QMap<QString, QVariantMap> animations;
    for (const QJsonValue &value : rows) {
        if (!value.isObject()) continue;
        const QJsonObject row = value.toObject();
        const QString state = row.value(QStringLiteral("state")).toString();
        if (state.isEmpty()) continue;
        const QJsonArray frameEntries = row.value(QStringLiteral("frames")).toArray();
        QVariantList durations;
        const QJsonArray durationValues = row.value(QStringLiteral("durations")).toArray();
        QStringList paths;
        for (int i = 0; i < frameEntries.size(); ++i) {
            const QString path = localFramePath(manifestPath, state, frameEntries.at(i).toString());
            if (path.isEmpty() || !QImageReader(path).canRead()) {
                *errorText = QCoreApplication::translate("PetLibrary", "La sequenza '%1' contiene un'immagine mancante o non valida (%2). Ricrea il PNG e riprova.")
                    .arg(state, QFileInfo(frameEntries.at(i).toString()).fileName());
                return false;
            }
            paths.append(path);
            const int duration = i < durationValues.size() ? durationValues.at(i).toInt(125) : 125;
            durations.append(qBound(20, duration, 2000));
        }
        if (!paths.isEmpty())
            animations.insert(state, {{QStringLiteral("frames"), paths.size()},
                                      {QStringLiteral("paths"), paths},
                                      {QStringLiteral("durations"), durations}});
    }
    const QStringList required{QStringLiteral("idle"), QStringLiteral("running"),
                               QStringLiteral("review"), QStringLiteral("waiting"),
                               QStringLiteral("jumping"), QStringLiteral("failed")};
    QStringList missing;
    for (const QString &state : required)
        if (!animations.contains(state)) missing.append(state);
    if (!missing.isEmpty()) {
        *errorText = QCoreApplication::translate("PetLibrary", "Mancano queste animazioni obbligatorie: %1. Per completare il pet, crea per ciascuna lo stato una cartella frames/<stato>/ con almeno un PNG numerato (per esempio 00.png), poi aggiungi i percorsi relativi in frames-manifest.json usando lo schema codexmeter-16-pose-extension.")
            .arg(missing.join(QStringLiteral(", ")));
        return false;
    }
    QString name = safeName(manifest.value(QStringLiteral("name")).toString());
    if (name.isEmpty()) name = QFileInfo(QFileInfo(manifestPath).absolutePath()).dir().dirName();
    result->insert(QStringLiteral("name"), name);
    QVariantMap animationMap;
    for (auto it = animations.cbegin(); it != animations.cend(); ++it)
        animationMap.insert(it.key(), QVariant::fromValue(it.value()));
    result->insert(QStringLiteral("animations"), animationMap);
    result->insert(QStringLiteral("manifestPath"), manifestPath);
    return true;
}
}

PetLibrary::PetLibrary(QObject *parent) : QObject(parent) { load(); }
QVariantList PetLibrary::customPets() const { return m_pets; }
int PetLibrary::lastImportedPetId() const { return m_lastImportedPetId; }

void PetLibrary::load()
{
    m_pets.clear();
    QDir dir(libraryPath());
    if (!dir.exists()) return;
    const QFileInfoList entries = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Time);
    for (const QFileInfo &entry : entries) {
        QVariantMap data;
        QString error;
        if (!validatePackage(entry.absoluteFilePath(), &data, &error)) continue;
        bool ok = false;
        int id = 1000 + static_cast<int>(entry.fileName().left(8).toUInt(&ok, 16) % 1000000000U);
        if (!ok || id == 0) id = 1000 + m_pets.size();
        data.insert(QStringLiteral("id"), id);
        QVariantMap anims = data.value(QStringLiteral("animations")).toMap();
        QVariantMap mascotAnimations;
        for (auto it = anims.cbegin(); it != anims.cend(); ++it) {
            const QVariantMap animation = it.value().toMap();
            QVariantMap mascotConfig;
            mascotConfig.insert(QStringLiteral("frames"), animation.value(QStringLiteral("frames")));
            mascotConfig.insert(QStringLiteral("directory"), it.key());
            mascotConfig.insert(QStringLiteral("durations"), animation.value(QStringLiteral("durations")));
            mascotAnimations.insert(it.key(), QVariant::fromValue(mascotConfig));
        }
        const auto alias = [&mascotAnimations, &anims](const QString &name, const QString &source) {
            if (!mascotAnimations.contains(name) && anims.contains(source)) {
                QVariantMap mapped = mascotAnimations.value(source).toMap();
                mascotAnimations.insert(name, mapped);
            }
        };
        alias(QStringLiteral("working"), QStringLiteral("running"));
        alias(QStringLiteral("thinking"), QStringLiteral("running"));
        alias(QStringLiteral("running-right"), QStringLiteral("running"));
        alias(QStringLiteral("running-left"), QStringLiteral("running"));
        alias(QStringLiteral("completed"), QStringLiteral("jumping"));
        alias(QStringLiteral("happy"), QStringLiteral("jumping"));
        alias(QStringLiteral("critical"), QStringLiteral("failed"));
        alias(QStringLiteral("warning"), QStringLiteral("waiting"));
        const QVariantMap idle = anims.value(QStringLiteral("idle")).toMap();
        const QStringList frames = idle.value(QStringLiteral("paths")).toStringList();
        data.insert(QStringLiteral("preview"), frames.isEmpty() ? QString() : QUrl::fromLocalFile(frames.first()).toString());
        data.insert(QStringLiteral("animations"), mascotAnimations);
        data.insert(QStringLiteral("resourceRoot"), QUrl::fromLocalFile(QDir(entry.absoluteFilePath()).filePath(QStringLiteral("frames/"))).toString());
        m_pets.append(data);
    }
    emit customPetsChanged();
}

QVariantMap PetLibrary::pet(int id) const
{
    for (const QVariant &value : m_pets) {
        const QVariantMap item = value.toMap();
        if (item.value(QStringLiteral("id")).toInt() == id) return item;
    }
    return {};
}

bool PetLibrary::importPackage(const QString &inputPath)
{
    const QString source = QUrl(inputPath).isLocalFile() ? QUrl(inputPath).toLocalFile() : inputPath;
    const QFileInfo sourceInfo(source);
    if (!sourceInfo.exists()) {
        emit importFinished(false, QCoreApplication::translate("PetLibrary", "Il percorso selezionato non esiste più."));
        return false;
    }
    const QString temporary = QDir(QDir::tempPath()).filePath(QStringLiteral("codexmeter-pet-%1").arg(QUuid::createUuid().toString(QUuid::WithoutBraces)));
    QString packageRoot = sourceInfo.isDir() ? sourceInfo.absoluteFilePath() : temporary;
    if (!sourceInfo.isDir()) {
        if (sourceInfo.suffix().compare(QStringLiteral("zip"), Qt::CaseInsensitive) != 0) {
            emit importFinished(false, QCoreApplication::translate("PetLibrary", "Scegli una cartella oppure un archivio .zip."));
            return false;
        }
        QDir().mkpath(temporary);
        QProcess extractor;
        extractor.start(QStringLiteral("tar"), {QStringLiteral("-xf"), sourceInfo.absoluteFilePath(), QStringLiteral("-C"), temporary});
        if (!extractor.waitForStarted() || !extractor.waitForFinished(30000) || extractor.exitCode() != 0) {
            QDir(temporary).removeRecursively();
            emit importFinished(false, QCoreApplication::translate("PetLibrary", "Non riesco ad aprire lo ZIP. Estrailo e seleziona la cartella frames."));
            return false;
        }
    }

    QVariantMap parsed;
    QString error;
    if (!validatePackage(packageRoot, &parsed, &error)) {
        if (packageRoot == temporary) QDir(temporary).removeRecursively();
        emit importFinished(false, error);
        return false;
    }
    if (parsed.value(QStringLiteral("name")).toString() == QStringLiteral("frames")) {
        QString fallbackName = sourceInfo.isDir() ? sourceInfo.fileName() : sourceInfo.completeBaseName();
        if (!sourceInfo.isDir() && (fallbackName == QStringLiteral("frames") || fallbackName == QStringLiteral("production"))) {
            QDir parent(sourceInfo.absolutePath());
            if (parent.dirName() == QStringLiteral("production")) parent.cdUp();
            fallbackName = parent.dirName();
        }
        parsed.insert(QStringLiteral("name"), safeName(fallbackName));
    }
    // Keep imports as self-contained folders so future startup does not depend on the original location.
    QString destination = QDir(libraryPath()).filePath(QUuid::createUuid().toString(QUuid::WithoutBraces));
    QDir().mkpath(QFileInfo(destination).absolutePath());
    // Normalize to a self-contained `frames/` folder; manifests with legacy absolute paths
    // are rewritten to portable relative references during import.
    const QString framesDestination = QDir(destination).filePath(QStringLiteral("frames"));
    QDir().mkpath(framesDestination);
    const QVariantMap anims = parsed.value(QStringLiteral("animations")).toMap();
    QJsonArray rows;
    for (auto it = anims.cbegin(); it != anims.cend(); ++it) {
        const QVariantMap animation = it.value().toMap();
        const QString state = it.key();
        const QString stateDir = QDir(framesDestination).filePath(state);
        QDir().mkpath(stateDir);
        const QStringList paths = animation.value(QStringLiteral("paths")).toStringList();
        QJsonArray frameList, durationList;
        const QVariantList durations = animation.value(QStringLiteral("durations")).toList();
        for (int i = 0; i < paths.size(); ++i) {
            const QString fileName = QStringLiteral("%1.png").arg(i, 2, 10, QLatin1Char('0'));
            if (!QFile::copy(paths.at(i), QDir(stateDir).filePath(fileName))) {
                QDir(destination).removeRecursively();
                if (packageRoot == temporary) QDir(temporary).removeRecursively();
                emit importFinished(false, QCoreApplication::translate("PetLibrary", "Non riesco a copiare il frame %1.").arg(fileName));
                return false;
            }
            frameList.append(QStringLiteral("frames/%1/%2").arg(state, fileName));
            durationList.append(durations.value(i).toInt());
        }
        rows.append(QJsonObject{{QStringLiteral("state"), state}, {QStringLiteral("frames"), frameList}, {QStringLiteral("durations"), durationList}});
    }
    QJsonObject normalized{{QStringLiteral("schema"), QStringLiteral("codexmeter-16-pose-extension")},
                          {QStringLiteral("name"), parsed.value(QStringLiteral("name")).toString()},
                          {QStringLiteral("rows"), rows}};
    QFile manifestOut(QDir(destination).filePath(QStringLiteral("frames-manifest.json")));
    if (!manifestOut.open(QIODevice::WriteOnly) || manifestOut.write(QJsonDocument(normalized).toJson()) < 0) {
        QDir(destination).removeRecursively();
        if (packageRoot == temporary) QDir(temporary).removeRecursively();
        emit importFinished(false, QCoreApplication::translate("PetLibrary", "Non riesco a salvare il manifest del pet importato."));
        return false;
    }
    if (packageRoot == temporary) QDir(temporary).removeRecursively();
    m_lastImportedPetId = 1000 + static_cast<int>(QFileInfo(destination).fileName().left(8).toUInt(nullptr, 16) % 1000000000U);
    load();
    emit importFinished(true, QCoreApplication::translate("PetLibrary", "Pet '%1' aggiunto alla raccolta.").arg(parsed.value(QStringLiteral("name")).toString()));
    return true;
}
