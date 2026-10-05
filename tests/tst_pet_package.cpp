#include <QtTest>
#include <QTemporaryDir>
#include <QImage>
#include "../PetLibrary.cpp"

class PetPackageTests : public QObject {
    Q_OBJECT
private slots:
    void portableManifests_data() {
        QTest::addColumn<bool>("nestedManifest");
        QTest::addColumn<bool>("legacyAbsolute");
        QTest::newRow("normalized-root-manifest") << false << false;
        QTest::newRow("nested-manifest") << true << false;
        QTest::newRow("legacy-absolute-manifest") << true << true;
    }
    void portableManifests() {
        QFETCH(bool, nestedManifest);
        QFETCH(bool, legacyAbsolute);
        QTemporaryDir package;
        QVERIFY(package.isValid());
        QJsonArray rows;
        for (const auto *state : {"idle", "running", "review", "waiting", "jumping", "failed"}) {
            const QString relative = QString("frames/%1/00.png").arg(state);
            const QString frame = package.filePath(relative);
            QVERIFY(QDir().mkpath(QFileInfo(frame).absolutePath()));
            QImage image(192, 208, QImage::Format_ARGB32);
            image.fill(Qt::transparent);
            QVERIFY(image.save(frame));
            const QString reference = legacyAbsolute ? QString("C:/old-machine/pet/frames/%1/00.png").arg(state) : relative;
            rows.append(QJsonObject{{"state", state}, {"frames", QJsonArray{reference}}});
        }
        const QString manifestPath = package.filePath(nestedManifest ? "frames/frames-manifest.json" : "frames-manifest.json");
        QFile manifest(manifestPath);
        QVERIFY(manifest.open(QIODevice::WriteOnly));
        manifest.write(QJsonDocument(QJsonObject{{"schema", "codexmeter-16-pose-extension"}, {"name", "Demo"}, {"rows", rows}}).toJson());
        manifest.close();
        QVariantMap result;
        QString error;
        QVERIFY2(validatePackage(package.path(), &result, &error), qPrintable(error));
        QCOMPARE(result.value("animations").toMap().size(), 6);
        const auto idle = result.value("animations").toMap().value("idle").toMap();
        QCOMPARE(idle.value("durations").toList().first().toInt(), 125);
        QCOMPARE(idle.value("paths").toStringList().first(), package.filePath("frames/idle/00.png"));
    }
    void rejectsEscapingRelativePath() {
        QTemporaryDir package;
        QVERIFY(package.isValid());
        const QString manifest = package.filePath("frames-manifest.json");
        QCOMPARE(localFramePath(manifest, "idle", "../../outside/idle/00.png"), QString());
    }
    void documentedExample() {
        QFile source(QFINDTESTDATA("../docs/pets/frames-manifest.example.json"));
        QVERIFY(source.open(QIODevice::ReadOnly));
        const QByteArray json = source.readAll();
        const auto manifest = QJsonDocument::fromJson(json).object();
        QTemporaryDir package;
        QVERIFY(package.isValid());
        for (const auto &rowValue : manifest.value("rows").toArray()) {
            for (const auto &frameValue : rowValue.toObject().value("frames").toArray()) {
                const QString frame = package.filePath(frameValue.toString());
                QVERIFY(QDir().mkpath(QFileInfo(frame).absolutePath()));
                QImage image(192, 208, QImage::Format_ARGB32);
                image.fill(Qt::transparent);
                QVERIFY(image.save(frame));
            }
        }
        QFile output(package.filePath("frames-manifest.json"));
        QVERIFY(output.open(QIODevice::WriteOnly));
        QCOMPARE(output.write(json), qint64(json.size()));
        output.close();
        QVariantMap result;
        QString error;
        QVERIFY2(validatePackage(package.path(), &result, &error), qPrintable(error));
        QCOMPARE(result.value("animations").toMap().size(), 6);
    }
};
QTEST_GUILESS_MAIN(PetPackageTests)
#include "tst_pet_package.moc"
