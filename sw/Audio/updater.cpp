//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 20.01.2019
// Filename  : updater.cpp
// Changelog : 20.01.2019 - file created
//------------------------------------------------------------------------------

#include "updater.h"

Updater::Updater(IRegisterAccess *registerAccess, QObject *parent) :
    QObject(parent),
    _timer(this),
    _registerAccess(registerAccess)
{
    connect(&_timer, SIGNAL(timeout()), this, SLOT(update()));
    _timer.start(20);
}

void Updater::addElement(uint address, IUpdateElement *element)
{
    _elementVector.append(QPair<IUpdateElement *, quint32>(element, address));
}

void Updater::update()
{
    foreach(auto pair, _elementVector) {
        QVector<quint32> readVector;
        _registerAccess->read(pair.second, readVector, 1);
        pair.first->updateParam(readVector[0]);
    }
}
