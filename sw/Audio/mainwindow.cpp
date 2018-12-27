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
    _udptransfer(),
    _registerAccess(_udptransfer),
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
    _settingsGroup(new QGroupBox("Settings")),
    _registerGroup(new QGroupBox("Register read/write")),
    _centralWidget(new QWidget(this)),
    _settingsLayout(new QGridLayout()),
    _registerLayout(new QGridLayout()),
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

    _mainLayout->addWidget(_settingsGroup, 0, 0);
    _mainLayout->addWidget(_registerGroup, 1, 0);

    setCentralWidget(_centralWidget);
    setWindowTitle("Audio Control");
    show();
}

MainWindow::~MainWindow()
{
  //delete _settingsGroup;
  //delete _registerGroup;
  //delete _centralWidget;
  //delete _settingsLayout;
  //delete _registerLayout;
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
        QVector<quint8> dataVector;
        QString dataString;
        quint32 data;
        error = _registerAccess.read(address, dataVector, 4);
        if (error == AUDIO_SUCCESS) {
            data = (static_cast<quint32>(dataVector[3])<<24) |
                   (static_cast<quint32>(dataVector[2])<<16) |
                   (static_cast<quint32>(dataVector[1])<<8) |
                    static_cast<quint32>(dataVector[0]);
            dataString.setNum(data, 16);
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
        QVector<quint8> dataVector;
        for (int byte=3; byte>=0; byte--) {
            dataVector.append(static_cast<quint8>((data>>(8*byte)) & 0xff));
        }
        error =_registerAccess.write(address, dataVector);
    }
    statusBar()->showMessage(QString("Register write ") + QString(errorToString(error)), 2000);
}
