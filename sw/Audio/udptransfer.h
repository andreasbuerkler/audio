#ifndef UDPTRANSFER_H
#define UDPTRANSFER_H

#include <QObject>
#include <QUdpSocket>

namespace Ui {
    class UdpTransfer;
}

class UdpTransfer : public QObject
{
    Q_OBJECT

public:
    UdpTransfer(QObject *parent = nullptr);
    ~UdpTransfer();
    void sendDatagram();
    QString getAddress();
    quint16 getPort();
    void setAddress(QString address);
    void setPort(quint16 port);

public slots:
    void readyRead();

private:
    void updateSocket();

    QUdpSocket *_socket;
    QString *_addressString;
    QHostAddress *_address;
    quint16 _port;

};

#endif // UDPTRANSFER_H
