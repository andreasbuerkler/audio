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
    explicit Meter(QString label);
    ~Meter() override;
    void updateParam(unsigned int level) override;

protected:
    void paintEvent(QPaintEvent *event) override;

private:
    QColor       _frameColor;
    QColor       _backgroundColor;
    QColor       _barColor;
    QFont        _labelFont;
    QFont        _markerFont;
    QString      _label;
    int          _width;
    int          _height;
    unsigned int _level;
    int          _levelBar;
    float        _levelDisplay;
};

#endif // METER_H
