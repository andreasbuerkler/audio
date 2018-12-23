#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QPushButton>
#include <QLineEdit>
#include <QGridLayout>
#include <QLabel>
#include <QGroupBox>

#include "udptransfer.h"

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
    void setupSettings(QGroupBox &group);
    void setupRegister(QGroupBox &group);

    UdpTransfer *_udptransfer;
    QPalette *_paletteActive;
    QPalette *_paletteInactive;

    QLabel *_ipAddressLabel;
    QLabel *_portLabel;
    QLineEdit *_ipAddressField;
    QLineEdit *_portField;
    QPushButton *_changeSettingsButton;

    QLabel *_addressLabel;
    QLabel *_dataLabel;
    QPushButton *_readButton;
    QPushButton *_writeButton;
    QLineEdit *_addressField;
    QLineEdit *_dataField;
    Ui::MainWindow *_ui;

};

#endif // MAINWINDOW_H
