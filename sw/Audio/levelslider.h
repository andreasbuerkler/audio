//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.01.2019
// Filename  : levelslider.h
// Changelog : 27.01.2019 - file created
//------------------------------------------------------------------------------

#ifndef LEVELSLIDER_H
#define LEVELSLIDER_H

#include <QWidget>
#include <QMouseEvent>

class LevelSlider : public QWidget
{
    Q_OBJECT

public:
    LevelSlider();
    void mouseMoveEvent(QMouseEvent *event) override;
    void mousePressEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;

protected:
    void paintEvent(QPaintEvent *event) override;

private:
    QColor _frameColor;
    QColor _backgroundColor;
    QColor _barColor;
    QFont  _font;
    int    _width;
    int    _height;
    int    _oldMousePosX;
    int    _moveValueX;
    int    _sliderPos;
    int    _sliderWidth;
    bool   _moveEnable;

};

#endif // LEVELSLIDER_H