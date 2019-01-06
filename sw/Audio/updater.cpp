#include "updater.h"

Updater::Updater(RegisterAccess &registerAccess, QObject *parent) :
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
    if (_testVal >= 0) { // TODO: remove this
        _testVal = -100;
    } else {
        _testVal = _testVal + 1;
    }
    foreach(auto pair, _elementVector) {

        // TODO: read register with address = _registerAccess.read(pair.second, ...);
        pair.first->updateParam(_testVal);
    }
}
