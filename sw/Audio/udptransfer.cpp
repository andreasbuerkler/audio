#include "udptransfer.h"

UdpTransfer::UdpTransfer(QObject *parent) :
    QObject(parent),
    _socket(new QUdpSocket(this)),
    _addressString(new QString("192.168.1.100")),
    _address(new QHostAddress(*_addressString)),
    _port(2000)
{
    _socket->bind(*_address, _port);
    connect(_socket, SIGNAL(readyRead()), this, SLOT(readyRead()));
}

UdpTransfer::~UdpTransfer()
{
    delete _socket;
    delete _addressString;
    delete _address;
}

QString UdpTransfer::getAddress()
{
    return *_addressString;
}

quint16 UdpTransfer::getPort()
{
    return _port;
}

void UdpTransfer::setAddress(QString address)
{
    if (address != *_addressString) {
        *_addressString = address;
        _address->setAddress(*_addressString);
        updateSocket();
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
    disconnect(_socket, SIGNAL(readyRead()), this, SLOT(readyRead()));
    delete _socket;
    _socket = new QUdpSocket(this);
    _socket->bind(*_address, _port);
    connect(_socket, SIGNAL(readyRead()), this, SLOT(readyRead()));
}

void UdpTransfer::sendDatagram()
{
    QByteArray msg;
    msg.append("Hello!!!");

    _socket->writeDatagram(msg, *_address, _port);
}

void UdpTransfer::readyRead()
{
    // when data comes in
    QByteArray buffer;
    buffer.resize(static_cast<int>(_socket->pendingDatagramSize()));

    QHostAddress sender;
    quint16 senderPort;

    _socket->readDatagram(buffer.data(), buffer.size(), &sender, &senderPort);

    qDebug() << "Message from: " << sender.toString();
    qDebug() << "Message port: " << senderPort;
    qDebug() << "Message: " << buffer;
}
