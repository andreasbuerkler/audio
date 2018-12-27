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
#include "typedefinitions.h"

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

private:
    void setupSettings(QGroupBox *group);
    void setupRegister(QGroupBox *group);

    UdpTransfer    _udptransfer;
    RegisterAccess _registerAccess;
    QPalette       _paletteActive;
    QPalette       _paletteInactive;

    QLabel         _ipAddressLabel;
    QLabel         _portLabel;
    QLineEdit      _ipAddressField;
    QLineEdit      _portField;
    QPushButton    _changeSettingsButton;

    QLabel         _addressLabel;
    QLabel         _dataLabel;
    QPushButton    _readButton;
    QPushButton    _writeButton;
    QLineEdit      _addressField;
    QLineEdit      _dataField;

    QGroupBox      *_settingsGroup;
    QGroupBox      *_registerGroup;
    QWidget        *_centralWidget;
    QGridLayout    *_settingsLayout;
    QGridLayout    *_registerLayout;
    QGridLayout    *_mainLayout;

    Ui::MainWindow *_ui;

};

#endif // MAINWINDOW_H
