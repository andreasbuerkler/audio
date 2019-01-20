//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.12.2018
// Filename  : registeraccess.h
// Changelog : 27.12.2018 - file created
//------------------------------------------------------------------------------

#ifndef REGISTERACCESS_H
#define REGISTERACCESS_H

#include <QObject>
#include <QMutex>
#include "udptransfer.h"
#include "iregisteraccess.h"

class RegisterAccess : public IRegisterAccess
{

public:
    explicit RegisterAccess(UdpTransfer &udpTransfer);
    ~RegisterAccess() override;
    int read(quint32 address, QVector<quint32> &data, int length) override;
    int write(quint32 address, QVector<quint32> &data) override;

private:
    quint8 sendReadCommand(quint32 address, int length);
    int    getReadData(QVector<quint8> &data, int length, quint8 readId);
    quint8 sendWriteCommand(quint32 address, QVector<quint8> &data);

    UdpTransfer &_udpTransfer;

    quint8 _id;
    QMutex _mutex;

};

#endif // REGISTERACCESS_H
