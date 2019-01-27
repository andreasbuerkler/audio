//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.01.2019
// Filename  : levelslider.cpp
// Changelog : 27.01.2019 - file created
//------------------------------------------------------------------------------

#include "levelslider.h"
#include <QPainter>

LevelSlider::LevelSlider() :
    _frameColor(0, 0, 0),
    _backgroundColor(250, 250, 210),
    _barColor(200,200,250),
    _font(),
    _width(250),
    _height(30),
    _oldMousePosX(10),
    _moveValueX(0),
    _sliderPos(10),
    _sliderWidth(10),
    _moveEnable(false)
{
   _font.setPixelSize(9);
    setFixedSize(QSize(_width, _height));
    setMouseTracking(true);
}

void LevelSlider::paintEvent(QPaintEvent *)
{
    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setFont(_font);

    // draw frame
    painter.setPen(_frameColor);
    painter.setBrush(_backgroundColor);
    QRect frame(0, 0, _width, _height);
    painter.drawRoundedRect(frame, 5, 5);

    // draw dB text
    int textdB = -80;
    for (float i=0.0f; i<9.0f; i+=1.0f) {
        QRect textRect(static_cast<int>(_width/10.0f*(i+0.5f)), 0, 20, 20);
        painter.drawText(textRect, Qt::AlignCenter, QString::number(textdB));
        textdB += 10;
    }

    // draw line
    painter.setPen(QPen(_barColor, 5));
    painter.setOpacity(0.5);
    painter.drawLine(_sliderWidth, _height/2, _width-_sliderWidth, _height/2);

    // draw slider
    painter.setPen(_frameColor);
    painter.setOpacity(1.0);
    QRect slider(_sliderPos, 5, _sliderWidth, _height-10);
    painter.drawRoundedRect(slider, 5, 5);

}

void LevelSlider::mouseMoveEvent(QMouseEvent *event)
{
    if ((event->buttons() & Qt::LeftButton) && _moveEnable) {
        _moveValueX = event->pos().x() - _oldMousePosX;
        _oldMousePosX = event->pos().x();
        _sliderPos += _moveValueX;
        if (_sliderPos < _sliderWidth) {
            _sliderPos = _sliderWidth;
        }
        if (_sliderPos > _width-2*_sliderWidth) {
            _sliderPos =_width-2*_sliderWidth;
        }
        update();
    } else {
        _moveValueX = 0;
    }
}

void LevelSlider::mousePressEvent(QMouseEvent *event)
{
    if (event->button() == Qt::LeftButton) {
        _oldMousePosX = event->pos().x();
        _moveEnable = true;
    }
}

void LevelSlider::mouseReleaseEvent(QMouseEvent *event)
{
    if (event->button() == Qt::LeftButton && _moveEnable) {
        _moveEnable = false;
    }
}
