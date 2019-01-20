//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 20.01.2019
// Filename  : meter.h
// Changelog : 20.01.2019 - file created
//------------------------------------------------------------------------------

#ifndef METER_H
#define METER_H

#include <QWidget>
#include "iupdateelement.h"

class Meter : public IUpdateElement
{
    Q_OBJECT
public:
    explicit Meter();
    ~Meter() override;
    void updateParam(unsigned int level) override;

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
    float  _levelDisplay;
};

#endif // METER_H
