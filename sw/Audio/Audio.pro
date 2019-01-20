#-------------------------------------------------
#
# Project created by QtCreator 2018-12-22T20:34:06
#
#-------------------------------------------------

QT       += core
QT       += gui
QT       += network

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = Audio
TEMPLATE = app

# The following define makes your compiler emit warnings if you use
# any feature of Qt which has been marked as deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if you use deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

CONFIG += c++11

SOURCES += \
    main.cpp \
    mainwindow.cpp \
    udptransfer.cpp \
    registeraccess.cpp \
    meter.cpp \
    updater.cpp \
    iregisteraccess.cpp \
    registermock.cpp

HEADERS += \
    mainwindow.h \
    udptransfer.h \
    registeraccess.h \
    typedefinitions.h \
    meter.h \
    updater.h \
    iupdateelement.h \
    iregisteraccess.h \
    registermock.h

FORMS += \
    mainwindow.ui

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
