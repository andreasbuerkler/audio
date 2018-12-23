#include "mainwindow.h"
#include "ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    _udptransfer(new UdpTransfer()),
    _paletteActive(new QPalette()),
    _paletteInactive(new QPalette()),
    _ui(new Ui::MainWindow)
{
    _ui->setupUi(this);
    _paletteActive->setColor(QPalette::Text, Qt::black);
    _paletteInactive->setColor(QPalette::Text, Qt::darkGray);

    // create layout
    QGroupBox *settingsGroup = new QGroupBox(tr("Settings"));
    setupSettings(*settingsGroup);

    QGroupBox *registerGroup = new QGroupBox(tr("Register read/write"));
    setupRegister(*registerGroup);

    QWidget *centralWidget = new QWidget(this);
    QGridLayout *mainLayout = new QGridLayout(centralWidget);
    mainLayout->addWidget(settingsGroup, 0, 0);
    mainLayout->addWidget(registerGroup, 1, 0);

    setCentralWidget(centralWidget);
    setWindowTitle(tr("Audio Control"));
    show();
}

void MainWindow::setupSettings(QGroupBox &group)
{
    _ipAddressLabel = new QLabel(tr("IP Address:"));
    _portLabel = new QLabel(tr("UDP Port:"));
    _portField = new QLineEdit();
    _portField->setInputMask("900000");
    _portField->setText(QString::number(_udptransfer->getPort()));
    _portField->setReadOnly(true);
    _portField->setFrame(false);
    _portField->setPalette(*_paletteInactive);
    _ipAddressField = new QLineEdit();
    _ipAddressField->setInputMask("900.900.900.900");
    _ipAddressField->setText(_udptransfer->getAddress());
    _ipAddressField->setReadOnly(true);
    _ipAddressField->setFrame(false);
    _ipAddressField->setPalette(*_paletteInactive);
    _changeSettingsButton = new QPushButton("Change");

    QGridLayout *settingsLayout = new QGridLayout();
    settingsLayout->addWidget(_ipAddressLabel, 0, 0);
    settingsLayout->addWidget(_portLabel, 1, 0);
    settingsLayout->addWidget(_ipAddressField, 0, 1);
    settingsLayout->addWidget(_portField, 1, 1);
    settingsLayout->addWidget(_changeSettingsButton, 0, 2);

    group.setLayout(settingsLayout);

    connect(_changeSettingsButton, SIGNAL (released()), this, SLOT (onChangeSettingsButtonPressed()));
}

void MainWindow::setupRegister(QGroupBox &group)
{
    _addressLabel = new QLabel(tr("Address:"));
    _dataLabel = new QLabel(tr("Data:"));
    _readButton = new QPushButton("Read");
    _writeButton = new QPushButton("Write");
    _addressField = new QLineEdit();
    _addressField->setInputMask("Hhhhhhhh");
    _addressField->setPlaceholderText("00000000");
    _dataField = new QLineEdit();
    _dataField->setInputMask("Hhhhhhhh");
    _dataField->setPlaceholderText("00000000");

    QGridLayout *registerLayout = new QGridLayout();
    registerLayout->addWidget(_addressLabel, 0, 0);
    registerLayout->addWidget(_addressField, 0, 1);
    registerLayout->addWidget(_dataLabel, 1, 0);
    registerLayout->addWidget(_dataField, 1, 1);
    registerLayout->addWidget(_readButton, 0, 2);
    registerLayout->addWidget(_writeButton, 1, 2);

    group.setLayout(registerLayout);

    connect(_readButton, SIGNAL (released()), this, SLOT (onReadButtonPressed()));
    connect(_writeButton, SIGNAL (released()), this, SLOT (onWriteButtonPressed()));
}

MainWindow::~MainWindow()
{
    delete _udptransfer;
    delete _paletteActive;
    delete _paletteInactive;
    delete _ui;
}

void MainWindow::onChangeSettingsButtonPressed()
{
    _ipAddressField->setReadOnly(!_ipAddressField->isReadOnly());
    _ipAddressField->setFrame(!_ipAddressField->hasFrame());
    _portField->setReadOnly(!_portField->isReadOnly());
    _portField->setFrame(!_portField->hasFrame());
    if (!_portField->isReadOnly()) {
        _changeSettingsButton->setText("Save");
        _portField->setPalette(*_paletteActive);
        _ipAddressField->setPalette(*_paletteActive);
    } else {
        _changeSettingsButton->setText("Change");
        _portField->setPalette(*_paletteInactive);
        _ipAddressField->setPalette(*_paletteInactive);

        _udptransfer->setAddress(_ipAddressField->text());
        _udptransfer->setPort(static_cast<quint16>(_portField->text().toInt()));
    }
}

void MainWindow::onReadButtonPressed()
{
    _dataField->setText("0");
}

void MainWindow::onWriteButtonPressed()
{
    _udptransfer->sendDatagram();
    _dataField->setText("1");
}
