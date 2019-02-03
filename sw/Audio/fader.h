//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.01.2019
// Filename  : fader.h
// Changelog : 27.01.2019 - file created
//------------------------------------------------------------------------------

#ifndef LEVELSLIDER_H
#define LEVELSLIDER_H

#include <QWidget>
#include <QMouseEvent>
#include "iupdateelement.h"

class Fader : public IUpdateElement
{
    Q_OBJECT

public:
    Fader();
    void updateParam(unsigned int *level) override;

protected:
    void paintEvent(QPaintEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mousePressEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;

private:
    void updateGain(float level);

    QColor _frameColor;
    QColor _backgroundColor;
    QColor _sliderColor;
    QColor _sliderActiveColor;
    QColor _sliderInactiveColor;
    QFont  _font;
    int    _width;
    int    _height;
    int    _oldMousePosX;
    int    _moveValueX;
    int    _sliderPos;
    int    _sliderWidth;
    int    _sliderHeight;
    int    _lineOffset;
    int    _lineHeight;
    bool   _moveEnable;
    bool   _sliderActive;
    int    _rangedB;
    int    _sliderSpacing;
    int    _numberOfMarkers;
    float  _gainLevel;

};

#endif // LEVELSLIDER_H
