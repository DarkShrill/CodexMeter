QT += core gui widgets qml quick quickcontrols2 testlib
CONFIG += console testcase c++17
TEMPLATE = app
TARGET = LocalizationTests
SOURCES += tst_localization.cpp ../Localization.cpp ../AppSettings.cpp ../CodexAppServerClient.cpp ../CodexRateLimitModel.cpp ../PetLibrary.cpp ../TrayController.cpp
HEADERS += ../Localization.h ../AppSettings.h ../CodexAppServerClient.h ../CodexRateLimitModel.h ../PetLibrary.h ../TrayController.h
INCLUDEPATH += ..
RESOURCES += ../translations.qrc
