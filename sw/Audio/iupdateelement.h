#ifndef IUPDATEELEMENT_H
#define IUPDATEELEMENT_H

#include <QWidget>

class IUpdateElement : public QWidget
{
    Q_OBJECT

public:
    virtual ~IUpdateElement() { }
    virtual void updateParam(unsigned int param) = 0;
};

#endif // IUPDATEELEMENT_H
