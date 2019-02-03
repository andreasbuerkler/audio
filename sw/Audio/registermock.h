//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 20.01.2019
// Filename  : registermock.h
// Changelog : 20.01.2019 - file created
//------------------------------------------------------------------------------

#ifndef REGISTERMOCK_H
#define REGISTERMOCK_H

#include "iregisteraccess.h"

class RegisterMock : public IRegisterAccess
{

public:
    RegisterMock();
    ~RegisterMock() override;
    int read(quint32 address, QVector<quint32> &data, int length) override;
    int write(quint32 address, QVector<quint32> &data) override;

private:
    quint32 _meterDataL;
    quint32 _meterDataR;
    quint32 _levelDataL;
    quint32 _levelDataR;

};

#endif // REGISTERMOCK_H
