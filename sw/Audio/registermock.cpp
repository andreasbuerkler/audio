//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 20.01.2019
// Filename  : registermock.cpp
// Changelog : 20.01.2019 - file created
//------------------------------------------------------------------------------

#include <QRandomGenerator>
#include "registermock.h"
#include "typedefinitions.h"

RegisterMock::RegisterMock()
{
    _meterDataL = 0;
    _meterDataR = 50;
}

RegisterMock::~RegisterMock() {}

int RegisterMock::read(quint32 address, QVector<quint32> &data, int length)
{
    switch (address) {
        case 0x04 : {
            quint32 minValue = (_meterDataL >= 10) ? _meterDataL-10 : 0;
            quint32 maxValue = (_meterDataL <= 245) ? _meterDataL+10 : 255;
            quint32 mockData = QRandomGenerator::global()->bounded(minValue, maxValue);
            _meterDataL = mockData;
            for (int word=0; word<length; word++) {
                data.append(_meterDataL);
            }
            }
            break;
        case 0x08 : {
            quint32 minValue = (_meterDataR >= 10) ? _meterDataR-10 : 0;
            quint32 maxValue = (_meterDataR <= 245) ? _meterDataR+10 : 255;
            quint32 mockData = QRandomGenerator::global()->bounded(minValue, maxValue);
            _meterDataR = mockData;
            for (int word=0; word<length; word++) {
                data.append(_meterDataR);
            }
            }
            break;
        default:
            for (int word=0; word<length; word++) {
                data.append(0x00);
            }
    }

    return AUDIO_SUCCESS;
}

int RegisterMock::write(quint32 address, QVector<quint32> &data)
{
    switch (address) {
        case 0x04 : _meterDataL = data[0];
            break;
        case 0x08 : _meterDataR = data[0];
            break;
    }
    return AUDIO_SUCCESS;
}
