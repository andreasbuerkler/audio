//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.12.2018
// Filename  : mainwindow.cpp
// Changelog : 27.12.2018 - file created
//------------------------------------------------------------------------------

#include <QStatusBar>
#include "mainwindow.h"
#include "ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    _udptransfer(this),
    _registerAccess(_udptransfer, this),
    _updater(_registerAccess, this),
    _paletteActive(),
    _paletteInactive(),
    _ipAddressLabel("IP Address:"),
    _portLabel("UDP Port:"),
    _ipAddressField(),
    _portField(),
    _changeSettingsButton("Change"),
    _addressLabel("Address:"),
    _dataLabel("Data:"),
    _readButton("Read"),
    _writeButton("Write"),
    _addressField(),
    _dataField(),
    _debugButton("Debug"),
    _meterL(new Meter()),
    _meterR(new Meter()),
    _settingsGroup(new QGroupBox("Settings")),
    _registerGroup(new QGroupBox("Register read/write")),
    _debugGroup(new QGroupBox("Debug")),
    _centralWidget(new QWidget(this)),
    _settingsLayout(new QGridLayout()),
    _registerLayout(new QGridLayout()),
    _debugLayout(new QGridLayout()),
    _mainLayout(new QGridLayout(_centralWidget)),
    _ui(new Ui::MainWindow)
{
    _ui->setupUi(this);
    delete _ui->mainToolBar;
    _paletteActive.setColor(QPalette::Text, Qt::black);
    _paletteInactive.setColor(QPalette::Text, Qt::darkGray);

    statusBar()->setSizeGripEnabled(false);

    // create layout
    setupSettings(_settingsGroup);
    setupRegister(_registerGroup);
    setupDebug(_debugGroup);

    _mainLayout->addWidget(_settingsGroup, 0, 0);
    _mainLayout->addWidget(_registerGroup, 1, 0);
    _mainLayout->addWidget(_debugGroup, 2, 0);

    setCentralWidget(_centralWidget);
    setWindowTitle("Audio Control");
    show();
}

MainWindow::~MainWindow()
{
  //delete _settingsGroup;
  //delete _registerGroup;
  //delete _debugGroup;
  //delete _centralWidget;
  //delete _settingsLayout;
  //delete _registerLayout;
  //delete _debugLayout;
    delete _ui;
}

void MainWindow::setupSettings(QGroupBox *group)
{
    _portField.setInputMask("900000");
    _portField.setText(QString::number(_udptransfer.getPort()));
    _portField.setReadOnly(true);
    _portField.setFrame(false);
    _portField.setPalette(_paletteInactive);
    _ipAddressField.setInputMask("900.900.900.900");
    _ipAddressField.setText(_udptransfer.getAddress());
    _ipAddressField.setReadOnly(true);
    _ipAddressField.setFrame(false);
    _ipAddressField.setPalette(_paletteInactive);

    _settingsLayout->addWidget(&_ipAddressLabel, 0, 0);
    _settingsLayout->addWidget(&_portLabel, 1, 0);
    _settingsLayout->addWidget(&_ipAddressField, 0, 1);
    _settingsLayout->addWidget(&_portField, 1, 1);
    _settingsLayout->addWidget(&_changeSettingsButton, 0, 2);

    group->setLayout(_settingsLayout);

    connect(&_changeSettingsButton, SIGNAL (released()), this, SLOT (onChangeSettingsButtonPressed()));
}

void MainWindow::setupRegister(QGroupBox *group)
{
    _addressField.setInputMask("Hhhhhhhh");
    _addressField.setPlaceholderText("00000000");
    _dataField.setInputMask("Hhhhhhhh");
    _dataField.setPlaceholderText("00000000");

    _registerLayout->addWidget(&_addressLabel, 0, 0);
    _registerLayout->addWidget(&_addressField, 0, 1);
    _registerLayout->addWidget(&_dataLabel, 1, 0);
    _registerLayout->addWidget(&_dataField, 1, 1);
    _registerLayout->addWidget(&_readButton, 0, 2);
    _registerLayout->addWidget(&_writeButton, 1, 2);

    group->setLayout(_registerLayout);

    connect(&_readButton, SIGNAL (released()), this, SLOT (onReadButtonPressed()));
    connect(&_writeButton, SIGNAL (released()), this, SLOT (onWriteButtonPressed()));
}

void MainWindow::setupDebug(QGroupBox *group)
{
    _debugLayout->addWidget(&_debugButton, 0, 0);
    _debugLayout->addWidget(_meterL, 1, 0);
    _debugLayout->addWidget(_meterR, 1, 1);
    group->setLayout(_debugLayout);

    _updater.addElement(0x4, _meterL);
    _updater.addElement(0x8, _meterR);

    connect(&_debugButton, SIGNAL (released()), this, SLOT (onDebugButtonPressed()));
}

void MainWindow::onChangeSettingsButtonPressed()
{
    bool settingsChanged = false;

    _ipAddressField.setReadOnly(!_ipAddressField.isReadOnly());
    _ipAddressField.setFrame(!_ipAddressField.hasFrame());
    _portField.setReadOnly(!_portField.isReadOnly());
    _portField.setFrame(!_portField.hasFrame());

    if (!_portField.isReadOnly()) {
        _changeSettingsButton.setText("Save");
        _portField.setPalette(_paletteActive);
        _ipAddressField.setPalette(_paletteActive);
    } else {
        _changeSettingsButton.setText("Change");
        _portField.setPalette(_paletteInactive);
        _ipAddressField.setPalette(_paletteInactive);

        settingsChanged |= _udptransfer.setAddress(_ipAddressField.text());
        settingsChanged |= _udptransfer.setPort(static_cast<quint16>(_portField.text().toInt()));
    }

    if (settingsChanged) {
        statusBar()->showMessage("Settings changed", 2000);
    }
}

void MainWindow::onReadButtonPressed()
{
    int error = AUDIO_SUCCESS;
    bool addressOk = false;
    quint32 address = _addressField.text().toUInt(&addressOk, 16);

    if (!addressOk) {
        error = AUDIO_ADDRESS_FORMAT_ERROR;
    } else {
        QVector<quint32> dataVector;
        QString dataString;
        error = _registerAccess.read(address, dataVector, 1);
        if (error == AUDIO_SUCCESS) {
            dataString.setNum(dataVector.at(0), 16);
            _dataField.setText(dataString);
        }
    }
    statusBar()->showMessage(QString("Register read ") + QString(errorToString(error)), 2000);
}

void MainWindow::onWriteButtonPressed()
{
    int error = AUDIO_SUCCESS;
    bool addressOk = false;
    bool dataOk = false;
    quint32 address = _addressField.text().toUInt(&addressOk, 16);
    quint32 data = _dataField.text().toUInt(&dataOk, 16);

    if (!addressOk) {
        error = AUDIO_ADDRESS_FORMAT_ERROR;
    } else if (!dataOk) {
        error = AUDIO_DATA_FORMAT_ERROR;
    } else {
        QVector<quint32> dataVector;
        dataVector.append(data);
        error =_registerAccess.write(address, dataVector);
    }
    statusBar()->showMessage(QString("Register write ") + QString(errorToString(error)), 2000);
}

void MainWindow::onDebugButtonPressed()
{
    // test consecutive read write access
    int error = AUDIO_SUCCESS;

    QVector<quint32> writeVector;
    writeVector.append(0x46580465);
    writeVector.append(0xab678923);
    writeVector.append(0x890bc892);
    writeVector.append(0xe7890138);
    writeVector.append(0xf082789a);
    writeVector.append(0xb798b012);
    writeVector.append(0x05df4081);
    writeVector.append(0x7db89019);
    writeVector.append(0xab673015);
    writeVector.append(0x169ba201);
    writeVector.append(0x48c36016);
    writeVector.append(0x98f29543);
    writeVector.append(0x096fb921);
    writeVector.append(0x95ac2098);
    writeVector.append(0x76b12afc);
    error =_registerAccess.write(0x4, writeVector);
    if (error != AUDIO_SUCCESS) {
        statusBar()->showMessage(QString("Debug write ") + QString(errorToString(error)), 2000);
        return;
    }
    QVector<quint32> readVector;
    error = _registerAccess.read(0x4, readVector, 15);
    if (error != AUDIO_SUCCESS) {
        statusBar()->showMessage(QString("Debug read ") + QString(errorToString(error)), 2000);
        return;
    }
    if (writeVector.length() != readVector.length()) {
        statusBar()->showMessage(QString("Debug length ") + QString(errorToString(error)), 2000);
        return;
    }
    for (int i=0; i<15; i++) {
        if (writeVector.at(i) != readVector.at(i)) {
            statusBar()->showMessage(QString("Debug compare ") + QString(errorToString(error)), 2000);
            return;
        }
    }
    for (int i=0; i<1000;i++) {
        QVector<quint32> singleWriteVector;
        singleWriteVector.append(static_cast<quint32>(i));
        error =_registerAccess.write(0x4, singleWriteVector);
        if (error != AUDIO_SUCCESS) {
            statusBar()->showMessage(QString("Debug write ") + QString(errorToString(error)), 2000);
            return;
        }
        QVector<quint32> singleReadVector;
        error = _registerAccess.read(0x4, singleReadVector, 1);
        if (error != AUDIO_SUCCESS) {
            statusBar()->showMessage(QString("Debug read ") + QString(errorToString(error)), 2000);
            return;
        }
        if (static_cast<quint32>(i) != singleReadVector.at(0)) {
            statusBar()->showMessage(QString("Debug write iteration ") + QString(errorToString(error)), 2000);
            return;
        }
    }

    statusBar()->showMessage(QString("Debug ") + QString(errorToString(error)), 2000);
}
