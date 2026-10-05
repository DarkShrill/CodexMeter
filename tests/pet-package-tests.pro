QT += core gui testlib
CONFIG += console testcase c++17
TEMPLATE = app
TARGET = PetPackageTests
SOURCES += tst_pet_package.cpp
HEADERS += ../PetLibrary.h
INCLUDEPATH += ..
