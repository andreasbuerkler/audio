//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 20.01.2019
// Filename  : updater.h
// Changelog : 20.01.2019 - file created
//------------------------------------------------------------------------------

#ifndef UPDATER_H
#define UPDATER_H

#include <QTimer>
#include <QVector>

#include "iregisteraccess.h"
#include "iupdateelement.h"

class Updater : public QObject
{
    Q_OBJECT

public:
    Updater(IRegisterAccess *registerAccess, QObject *parent);
    void addElement(uint address, IUpdateElement *element);

public slots:
    void update();

private:
    QTimer _timer;
    QVector<QPair<IUpdateElement *, quint32>> _elementVector;
    IRegisterAccess *_registerAccess;
};

#endif // UPDATER_H
