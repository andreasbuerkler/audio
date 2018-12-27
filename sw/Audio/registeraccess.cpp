//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.12.2018
// Filename  : registeraccess.cpp
// Changelog : 27.12.2018 - file created
//------------------------------------------------------------------------------

#include "registeraccess.h"
#include "typedefinitions.h"

RegisterAccess::RegisterAccess(UdpTransfer &udpTransfer, QObject *parent) :
    QObject(parent),
    _udpTransfer(udpTransfer),
    _id(0)
{

}

int RegisterAccess::read(quint32 address, QVector<quint8> &data, int length)
{
    if (length > 255) {
        return AUDIO_LENGTH_ERROR;
    }

    QByteArray dataArray;
    // id
    quint8 _readId = _id;
    _mutex.lock();
    dataArray.append(static_cast<char>(_id));
    _id ++;
    _mutex.unlock();

    // command
    dataArray.append(UDP_READ);
    // address length = 4 byte
    dataArray.append(4);
    // address
    for (int byte=3; byte>=0; byte--) {
        dataArray.append(static_cast<char>((address>>(8*byte)) & 0xff));
    }

    _udpTransfer.sendPacket(dataArray);

    QByteArray receiveData;
    int timeoutMs = 100;
    while (_udpTransfer.readPacket(_readId, receiveData, 1) == false) {
        timeoutMs--;
        if (timeoutMs == 0) {
            return AUDIO_TIMEOUT_ERROR;
        }
    };

    if (receiveData[1] != UDP_READ_RESPONSE) {
        return AUDIO_TYPE_ERROR;
    }
    int receiveLength = receiveData[2];
    if (receiveLength != length) {
        return AUDIO_RECEIVED_LENGTH_ERROR;
    }
    if (receiveLength > (receiveData.length()-3)) {
        return AUDIO_PACKET_LENGTH_ERROR;
    }
    for (int index=0; index<receiveLength; index++) {

        data.append(static_cast<quint8>(receiveData[index+2]));
    }

    return AUDIO_SUCCESS;
}

int RegisterAccess::write(quint32 address, QVector<quint8> &data)
{
    int length = data.length();
    if (length > 255) {
        return AUDIO_LENGTH_ERROR;
    }

    QByteArray dataArray;
    // id
    _mutex.lock();
    dataArray.append(static_cast<char>(_id));
    _id ++;
    _mutex.unlock();

    // command
    dataArray.append(UDP_WRITE);
    // address length = 4 byte
    dataArray.append(4);
    // address
    for (int byte=3; byte>=0; byte--) {
        dataArray.append(static_cast<char>((address>>(8*byte)) & 0xff));
    }
    // data length
    dataArray.append(static_cast<char>(length));
    // data
    foreach (const quint8 byte, data) {
        dataArray.append(static_cast<char>(byte));
    }

    _udpTransfer.sendPacket(dataArray);

    return AUDIO_SUCCESS;
}
