#ifndef UDPTRANSFER_H
#define UDPTRANSFER_H

#include <QObject>
#include <QUdpSocket>
#include <QNetworkInterface>

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
    QString getLocalAddress();
    void updateSocket();

    QUdpSocket *_sendSocket;
    QString *_targetAddressString;
    QHostAddress *_targetAddress;
    QString *_hostAddressString;
    QHostAddress *_hostAddress;
    quint16 _port;

};

#endif // UDPTRANSFER_H
