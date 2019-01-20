//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 20.01.2019
// Filename  : iregisteraccess.h
// Changelog : 20.01.2019 - file created
//------------------------------------------------------------------------------

#ifndef IREGISTERACCESS_H
#define IREGISTERACCESS_H

#include <QVector>

class IRegisterAccess
{

public:
    virtual ~IRegisterAccess() = 0;
    virtual int read(quint32 address, QVector<quint32> &data, int length) = 0;
    virtual int write(quint32 address, QVector<quint32> &data) = 0;
};

#endif // IREGISTERACCESS_H
