#include "udptransfer.h"

UdpTransfer::UdpTransfer(QObject *parent) :
    QObject(parent),
    _sendSocket(new QUdpSocket(this)),
    _targetAddressString(new QString("192.168.1.100")),
    _targetAddress(new QHostAddress(*_targetAddressString)),
    _hostAddressString(new QString("192.168.1.0")),
    _hostAddress(new QHostAddress(*_hostAddressString)),
    _port(4660)
{
    *_hostAddressString = getLocalAddress();
    _hostAddress->setAddress(*_hostAddressString);
    _sendSocket->bind(*_hostAddress, _port);
    connect(_sendSocket, SIGNAL(readyRead()), this, SLOT(readyRead()));
}

UdpTransfer::~UdpTransfer()
{
    delete _sendSocket;
    delete _targetAddressString;
    delete _targetAddress;
    delete _hostAddressString;
    delete _hostAddress;
}

QString UdpTransfer::getLocalAddress()
{
    QString localhostIP;
    foreach (const QNetworkInterface& networkInterface, QNetworkInterface::allInterfaces()) {
        foreach (const QNetworkAddressEntry& entry, networkInterface.addressEntries()) {
            quint32 netmask = entry.netmask().toIPv4Address();
            int bitcount = 0;
            for (int shift=0; shift<32; shift++) {
                if ((netmask<<shift) & 0x80000000) {
                    bitcount++;
                } else {
                    break;
                }
            }
            if (_targetAddress->isInSubnet(entry.ip(), bitcount)) {
                localhostIP = entry.ip().toString();
                break;
            }

        }
    }

    return localhostIP;
}

QString UdpTransfer::getAddress()
{
    return *_targetAddressString;
}

quint16 UdpTransfer::getPort()
{
    return _port;
}

void UdpTransfer::setAddress(QString address)
{
    if (*_targetAddressString != address) {
        *_targetAddressString = address;
        _targetAddress->setAddress(*_targetAddressString);
        QString localAddress = getLocalAddress();
        if (*_hostAddressString != localAddress) {
            *_hostAddressString = localAddress;
            _hostAddress->setAddress(*_hostAddressString);
            updateSocket();
        }
    }
}

void UdpTransfer::setPort(quint16 port)
{
    if (port != _port) {
        _port = port;
        updateSocket();
    }
}

void UdpTransfer::updateSocket()
{
    disconnect(_sendSocket, SIGNAL(readyRead()), this, SLOT(readyRead()));
    delete _sendSocket;
    _sendSocket = new QUdpSocket(this);
    _sendSocket->bind(*_hostAddress, _port);
    connect(_sendSocket, SIGNAL(readyRead()), this, SLOT(readyRead()));
}

void UdpTransfer::sendDatagram()
{
    QByteArray msg;
    msg.append("Hello!!!");

    _sendSocket->writeDatagram(msg, *_targetAddress, _port);
}

void UdpTransfer::readyRead()
{
    // when data comes in
    QByteArray buffer;
    buffer.resize(static_cast<int>(_sendSocket->pendingDatagramSize()));

    QHostAddress sender;
    quint16 senderPort;

    _sendSocket->readDatagram(buffer.data(), buffer.size(), &sender, &senderPort);

    qDebug() << "Message: " << buffer;
}
