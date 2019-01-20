//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.12.2018
// Filename  : registeraccess.cpp
// Changelog : 27.12.2018 - file created
//------------------------------------------------------------------------------

#include "registeraccess.h"
#include "typedefinitions.h"

RegisterAccess::RegisterAccess(UdpTransfer &udpTransfer) :
    _udpTransfer(udpTransfer),
    _id(0)
{

}

RegisterAccess::~RegisterAccess() {}

int RegisterAccess::read(quint32 address, QVector<quint32> &data, int length)
{
    if (length > 255) {
        return AUDIO_LENGTH_ERROR;
    }

    quint8 readId = 0;
    readId = sendReadCommand(address, length*4);

    int errorCode = AUDIO_SUCCESS;
    QVector<quint8> byteVector;
    errorCode = getReadData(byteVector, length*4, readId);
    if (errorCode == AUDIO_SUCCESS) {
        for (int byte=0; byte<byteVector.length(); byte+=4) {
            quint32 word = (static_cast<quint32>(byteVector[byte+0])<<24) |
                           (static_cast<quint32>(byteVector[byte+1])<<16) |
                           (static_cast<quint32>(byteVector[byte+2])<<8) |
                            static_cast<quint32>(byteVector[byte+3]);
            data.append(word);
        }
    }
    return errorCode;
}

int RegisterAccess::write(quint32 address, QVector<quint32> &data)
{
    if (data.length() > 255) {
        return AUDIO_LENGTH_ERROR;
    }

    QVector<quint8> byteVector;
    foreach (quint32 word, data) {
        for (int byte=3; byte>=0; byte--) {
            byteVector.append(static_cast<quint8>((word>>(8*byte)) & 0xff));
        }
    }
    sendWriteCommand(address, byteVector);

    return AUDIO_SUCCESS;
}

quint8 RegisterAccess::sendReadCommand(quint32 address, int length)
{
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
    // data length
    dataArray.append(static_cast<char>(length));
    _udpTransfer.sendPacket(dataArray);

    return _readId;
}

int RegisterAccess::getReadData(QVector<quint8> &data, int length, quint8 readId)
{
    QByteArray receiveData;
    int timeoutMs = 100;
    while (_udpTransfer.readPacket(readId, receiveData, 1) == false) {
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
        data.append(static_cast<quint8>(receiveData[index+3]));
    }

    return AUDIO_SUCCESS;
}

quint8 RegisterAccess::sendWriteCommand(quint32 address, QVector<quint8> &data)
{
    QByteArray dataArray;
    // id
    _mutex.lock();
    quint8 _writeId = _id;
    dataArray.append(static_cast<char>(_writeId));
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
    dataArray.append(static_cast<char>(data.length()));
    // data
    foreach (const quint8 byte, data) {
        dataArray.append(static_cast<char>(byte));
    }

    _udpTransfer.sendPacket(dataArray);

    return _writeId;
}
