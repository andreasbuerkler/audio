//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.01.2019
// Filename  : levelslider.cpp
// Changelog : 27.01.2019 - file created
//------------------------------------------------------------------------------

#include "levelslider.h"
#include <QPainter>

LevelSlider::LevelSlider() :
    _frameColor(230, 230, 230),
    _backgroundColor(0, 90, 200),
    _barColor(0, 40, 100),
    _font(),
    _width(250),
    _height(50),
    _oldMousePosX(10),
    _moveValueX(0),
    _sliderPos(10),
    _sliderWidth(40),
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
    painter.setPen(_backgroundColor);
    painter.setBrush(_backgroundColor);
    QRect frame(0, 0, _width, _height);
    painter.drawRoundedRect(frame, 5, 5);

    // draw dB text and marker lines
    painter.setPen(_frameColor);
    painter.setBrush(_backgroundColor);
    int border = 10+_sliderWidth/2;
    int lineWidth = _width-2*border;
    int numberOfMarkers = 8;
    int textdB = -80;
    for (int i=0; i<=numberOfMarkers; i++) {
        float offset = border+lineWidth/static_cast<float>(numberOfMarkers)*i;
        painter.drawLine(static_cast<int>(offset), 20, static_cast<int>(offset), _height-5);
        QRect textRect(static_cast<int>(offset)-10, 0, 20, 20);
        painter.drawText(textRect, Qt::AlignCenter, QString::number(textdB));
        textdB += 10;
    }

    // draw line
    int offset = 10;
    int lineHeight = 6;
    painter.setPen(QPen(_backgroundColor, 1));
    painter.setBrush(_frameColor);
    QRect line(border-5, _height/2-lineHeight/2+offset, lineWidth+10, lineHeight);
    painter.drawRoundedRect(line, 5, 5);

    // draw slider
    int sliderHeight = 20;
    painter.setPen(_backgroundColor);
    painter.setBrush(_frameColor);
    painter.setOpacity(1.0);
    QRect slider(_sliderPos, _height/2+offset-sliderHeight/2, _sliderWidth, sliderHeight);
    painter.drawRoundedRect(slider, 5, 5);
    painter.drawLine(_sliderPos+_sliderWidth/2, _height/2+offset-sliderHeight/2, _sliderPos+_sliderWidth/2, _height/2+offset-sliderHeight/2+4);
    painter.drawLine(_sliderPos+_sliderWidth/2, _height/2+offset+sliderHeight/2, _sliderPos+_sliderWidth/2, _height/2+offset+sliderHeight/2-4);

    // draw dB inside slider
    QRect dBRect(_sliderPos+_sliderWidth/2-20, _height/2+offset-10, 40, 20);
    float dBVal = -84.2f+80.0f*static_cast<float>(_sliderPos)/static_cast<float>(_width-_sliderWidth-20);
    painter.drawText(dBRect, Qt::AlignCenter, QString::number(static_cast<double>(dBVal), 'f', 1) + QString(" dB"));
}

void LevelSlider::mouseMoveEvent(QMouseEvent *event)
{
    if ((event->buttons() & Qt::LeftButton) && _moveEnable) {
        _moveValueX = event->pos().x() - _oldMousePosX;
        _oldMousePosX = event->pos().x();
        _sliderPos += _moveValueX;
        if (_sliderPos < 10) {
            _sliderPos = 10;
        }
        if (_sliderPos > _width-_sliderWidth-10) {
            _sliderPos =_width-_sliderWidth-10;
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
