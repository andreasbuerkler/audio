//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 20.01.2019
// Filename  : iupdateelement.h
// Changelog : 20.01.2019 - file created
//------------------------------------------------------------------------------

#ifndef IUPDATEELEMENT_H
#define IUPDATEELEMENT_H

#include <QWidget>

class IUpdateElement : public QWidget
{
    Q_OBJECT

public:
    virtual ~IUpdateElement() {}
    virtual void updateParam(unsigned int *param) = 0;
};

#endif // IUPDATEELEMENT_H
