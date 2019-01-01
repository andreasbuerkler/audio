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

class RegisterAccess : public QObject
{
    Q_OBJECT
public:
    explicit RegisterAccess(UdpTransfer &udpTransfer, QObject *parent = nullptr);
    int read(quint32 address, QVector<quint32> &data, int length);
    int write(quint32 address, QVector<quint32> &data);

signals:

public slots:

private:
    quint8 sendReadCommand(quint32 address, int length);
    int    getReadData(QVector<quint8> &data, int length, quint8 readId);
    quint8 sendWriteCommand(quint32 address, QVector<quint8> &data);

    UdpTransfer &_udpTransfer;

    quint8 _id;
    QMutex _mutex;

};

#endif // REGISTERACCESS_H
