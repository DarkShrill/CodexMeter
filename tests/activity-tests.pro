QT += core testlib
CONFIG += console testcase c++17
CONFIG -= app_bundle
TEMPLATE = app
TARGET = ActivityTests
SOURCES += tst_activity.cpp ../TaskActivity.cpp
HEADERS += ../TaskActivity.h
