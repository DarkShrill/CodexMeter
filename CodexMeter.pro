QT += core gui widgets qml quick quickcontrols2

CONFIG += c++17
TEMPLATE = app
TARGET = CodexMeter

SOURCES += \
    Localization.cpp \
    TaskbarMonitor.cpp \
    TaskActivity.cpp \
    main.cpp \
    AppSettings.cpp \
    CodexAppServerClient.cpp \
    CodexRateLimitModel.cpp \
    PetLibrary.cpp \
    TrayController.cpp

HEADERS += \
    Localization.h \
    TaskbarMonitor.h \
    TaskActivity.h \
    AppSettings.h \
    CodexAppServerClient.h \
    CodexRateLimitModel.h \
    PetLibrary.h \
    TrayController.h

RESOURCES += resources.qrc translations.qrc

# Le anteprime sono disponibili a Qt Creator e nella build Debug soltanto.
CONFIG(debug, debug|release) {
    CONFIG += qml_debug
    DEFINES += CODEXMETER_PREVIEWS
    RESOURCES += qml-previews.qrc
}

win32 {
    LIBS += -lcomctl32 -luser32 -lgdi32 -lole32 -luuid
    RC_FILE = windows.rc
    RC_INCLUDEPATH += $$PWD
    QMAKE_TARGET_PRODUCT = Codex Meter
    QMAKE_TARGET_DESCRIPTION = Codex usage meter
    QMAKE_TARGET_COMPANY = LocalTools
    QMAKE_TARGET_COPYRIGHT = Copyright 2026
}
