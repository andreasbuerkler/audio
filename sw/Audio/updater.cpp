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

void Updater::addElement(uint address, IUpdateElement *element, bool read)
{
    _elementVector.append(QPair<IUpdateElement *, QPair<quint32, bool>>(element, QPair<quint32, bool>(address, read)));
}

void Updater::update()
{
    foreach(auto pair, _elementVector) {
        if (pair.second.second) {
            QVector<quint32> readVector;
            _registerAccess->read(pair.second.first , readVector, 1);
            pair.first->updateParam(&readVector[0]);
        } else {
            QVector<quint32> writeVector;
            unsigned int writeParam = 0;
            pair.first->updateParam(&writeParam);
            writeVector.append(writeParam);
            _registerAccess->write(pair.second.first , writeVector);
        }
    }
}
