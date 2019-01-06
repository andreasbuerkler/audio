#ifndef METER_H
#define METER_H

#include <QWidget>
#include "iupdateelement.h"

class Meter : public IUpdateElement
{
    Q_OBJECT
public:
    explicit Meter();
    void updateParam(int level) override;

protected:
    void paintEvent(QPaintEvent *event) override;

private:
    QColor _frameColor;
    QColor _backgroundColor;
    QColor _textBackgroundColor;
    QColor _textFrameColor;
    QColor _barColor;
    QFont  _font;
    int    _width;
    int    _height;
    int    _level;
};

#endif // METER_H
