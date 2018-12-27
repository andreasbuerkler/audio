//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.12.2018
// Filename  : udptransfer.cpp
// Changelog : 27.12.2018 - file created
//------------------------------------------------------------------------------

#include "udptransfer.h"

UdpTransfer::UdpTransfer(QObject *parent) :
    QObject(parent),
    _sendSocket(new QUdpSocket(this)),
    _targetAddressString("192.168.1.100"),
    _targetAddress(_targetAddressString),
    _hostAddressString("192.168.1.0"),
    _hostAddress(_hostAddressString),
    _port(4660)
{
    _hostAddressString = getLocalAddress();
    _hostAddress.setAddress(_hostAddressString);
    _sendSocket.bind(_hostAddress, _port);
    connect(&_sendSocket, SIGNAL(readyRead()), this, SLOT(readyRead()));
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
            if (_targetAddress.isInSubnet(entry.ip(), bitcount)) {
                localhostIP = entry.ip().toString();
                break;
            }

        }
    }

    return localhostIP;
}

QString UdpTransfer::getAddress()
{
    return _targetAddressString;
}

quint16 UdpTransfer::getPort()
{
    return _port;
}

bool UdpTransfer::setAddress(QString address)
{
    if (_targetAddressString != address) {
        _targetAddressString = address;
        _targetAddress.setAddress(_targetAddressString);
        QString localAddress = getLocalAddress();
        if (_hostAddressString != localAddress) {
            _hostAddressString = localAddress;
            _hostAddress.setAddress(_hostAddressString);
            updateSocket();
            return true;
        }
    }
    return false;
}

bool UdpTransfer::setPort(quint16 port)
{
    if (port != _port) {
        _port = port;
        updateSocket();
        return true;
    }
    return false;
}

void UdpTransfer::updateSocket()
{
    disconnect(&_sendSocket, SIGNAL(readyRead()), this, SLOT(readyRead()));
    _sendSocket.abort();
    _sendSocket.bind(_hostAddress, _port);
    connect(&_sendSocket, SIGNAL(readyRead()), this, SLOT(readyRead()));
}

void UdpTransfer::sendPacket(QByteArray &data)
{
    _sendSocket.writeDatagram(data, _targetAddress, _port);
}

bool UdpTransfer::readPacket(quint8 id, QByteArray &data, int waitMs)
{
    _mutex.lock();
    for (int index=0; index<_receiveBuffer.length(); index++) {
        if (_receiveBuffer[index][0] == static_cast<char>(id)) {
            data.setRawData(_receiveBuffer[index], static_cast<uint>(_receiveBuffer[index].size()));
            _receiveBuffer.remove(index);
            _mutex.unlock();
            return true;
        }
    }
    _mutex.unlock();
    _sendSocket.waitForReadyRead(waitMs);
    return false;
}

void UdpTransfer::readyRead()
{
    QByteArray buffer;
    buffer.resize(static_cast<int>(_sendSocket.pendingDatagramSize()));
    _sendSocket.readDatagram(buffer.data(), buffer.size());
    _mutex.lock();
    _receiveBuffer.append(buffer);
    _mutex.unlock();

    qDebug() << "Message: " << buffer;
}
