//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.12.2018
// Filename  : mainwindow.h
// Changelog : 27.12.2018 - file created
//------------------------------------------------------------------------------

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QPushButton>
#include <QLineEdit>
#include <QGridLayout>
#include <QLabel>
#include <QGroupBox>

#include "udptransfer.h"
#include "registeraccess.h"
#include "registermock.h"
#include "typedefinitions.h"
#include "meter.h"
#include "updater.h"
#include "fader.h"

namespace Ui {
    class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void onChangeSettingsButtonPressed();
    void onReadButtonPressed();
    void onWriteButtonPressed();
    void onDebugButtonPressed();

private:
    void setupSettings(QGroupBox *group);
    void setupRegister(QGroupBox *group);
    void setupInput(QGroupBox *group);
    void setupDebug(QGroupBox *group);

    UdpTransfer     _udptransfer;
    IRegisterAccess *_registerAccess;
    Updater         _updater;

    QLabel          _ipAddressLabel;
    QLabel          _portLabel;
    QLineEdit       _ipAddressField;
    QLineEdit       _portField;
    QPushButton     _changeSettingsButton;

    QLabel          _addressLabel;
    QLabel          _dataLabel;
    QPushButton     _readButton;
    QPushButton     _writeButton;
    QLineEdit       _addressField;
    QLineEdit       _dataField;

    QPushButton     _debugButton;
    Meter           _meterL;
    Meter           _meterR;
    Fader           _levelL;
    Fader           _levelR;
    QGroupBox       *_settingsGroup;
    QGroupBox       *_registerGroup;
    QGroupBox       *_inputGroup;
    QGroupBox       *_debugGroup;
    QWidget         *_centralWidget;
    QGridLayout     *_settingsLayout;
    QGridLayout     *_registerLayout;
    QGridLayout     *_inputLayout;
    QGridLayout     *_debugLayout;
    QGridLayout     *_mainLayout;

    Ui::MainWindow  *_ui;

};

#endif // MAINWINDOW_H
