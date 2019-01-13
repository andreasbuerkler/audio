#ifndef UPDATER_H
#define UPDATER_H

#include <QTimer>
#include <QVector>

#include "registeraccess.h"
#include "iupdateelement.h"

class Updater : public QObject
{
    Q_OBJECT

public:
    Updater(RegisterAccess &registerAccess, QObject *parent);
    void addElement(uint address, IUpdateElement *element);

public slots:
    void update();

private:
    QTimer _timer;
    QVector<QPair<IUpdateElement *, quint32>> _elementVector;
    RegisterAccess &_registerAccess;
};

#endif // UPDATER_H
