QT += widgets qml quick quickcontrols2 qmltest
CONFIG += console c++17
TEMPLATE = app
TARGET = ReadmeCapture
SOURCES += capture.cpp ../../PetLibrary.cpp
HEADERS += ../../PetLibrary.h
INCLUDEPATH += ../..
