//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.12.2018
// Filename  : udptransfer.h
// Changelog : 27.12.2018 - file created
//------------------------------------------------------------------------------

#ifndef UDPTRANSFER_H
#define UDPTRANSFER_H

#include <QObject>
#include <QUdpSocket>
#include <QNetworkInterface>
#include <QMutex>

class UdpTransfer : public QObject
{
    Q_OBJECT

public:
    UdpTransfer(QObject *parent = nullptr);

    void    sendPacket(QByteArray &data);
    bool    readPacket(quint8 id, QByteArray &data, int waitMs);
    QString getAddress();
    quint16 getPort();
    bool    setAddress(QString address);
    bool    setPort(quint16 port);

public slots:
    void readyRead();

private:
    QString getLocalAddress();
    void    updateSocket();

    QUdpSocket          _sendSocket;
    QString             _targetAddressString;
    QHostAddress        _targetAddress;
    QString             _hostAddressString;
    QHostAddress        _hostAddress;
    quint16             _port;
    QVector<QByteArray> _receiveBuffer;
    QMutex              _mutex;

};

#endif // UDPTRANSFER_H
