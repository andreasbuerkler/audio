//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.01.2019
// Filename  : fader.cpp
// Changelog : 27.01.2019 - file created
//------------------------------------------------------------------------------

#include "fader.h"
#include <QPainter>

Fader::Fader() :
    _frameColor(230, 230, 230),
    _backgroundColor(0, 100, 220),
    _sliderColor(0, 40, 80),
    _sliderActiveColor(0, 0, 0),
    _sliderInactiveColor(0, 40, 80),
    _font(),
    _width(250),
    _height(50),
    _oldMousePosX(10),
    _moveValueX(0),
    _sliderPos(10),
    _sliderWidth(40),
    _sliderHeight(16),
    _lineOffset(10),
    _lineHeight(6),
    _moveEnable(false),
    _sliderActive(false),
    _rangedB(80),
    _sliderSpacing(10),
    _numberOfMarkers(8),
    _gainLevel(0)
{
   _font.setPixelSize(9);
    setFixedSize(QSize(_width, _height));
    setMouseTracking(true);
}

void Fader::paintEvent(QPaintEvent *)
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
    const int border = _sliderSpacing+_sliderWidth/2;
    const int lineWidth = _width-2*border;
    int textdB = -_rangedB;
    for (int i=0; i<=_numberOfMarkers; i++) {
        float offset = border+lineWidth/static_cast<float>(_numberOfMarkers)*i;
        painter.drawLine(static_cast<int>(offset), 20, static_cast<int>(offset), _height-5);
        QRect textRect(static_cast<int>(offset)-10, 0, 20, 20);
        painter.drawText(textRect, Qt::AlignCenter, QString::number(textdB));
        textdB += _rangedB/_numberOfMarkers;
    }

    // draw line
    painter.setPen(QPen(_backgroundColor, 1));
    painter.setBrush(_frameColor);
    QRect line(border-5, _height/2-_lineHeight/2+_lineOffset, lineWidth+10, _lineHeight);
    painter.drawRoundedRect(line, 5, 5);

    // draw slider
    painter.setPen(_sliderColor);
    painter.setBrush(_sliderColor);
    const int sliderTop = _height/2+_lineOffset-_sliderHeight/2;
    QRect slider(_sliderPos, sliderTop, _sliderWidth, _sliderHeight);
    painter.drawRoundedRect(slider, 5, 5);
    painter.setPen(_backgroundColor);
    painter.drawLine(_sliderPos+_sliderWidth/2, sliderTop, _sliderPos+_sliderWidth/2, sliderTop+4);
    painter.drawLine(_sliderPos+_sliderWidth/2, sliderTop+_sliderHeight, _sliderPos+_sliderWidth/2, sliderTop+_sliderHeight-4);

    // calculate gain
    float sliderRange = static_cast<float>(_width-_sliderWidth-2*_sliderSpacing);
    float level = -_rangedB+static_cast<float>(_rangedB*(_sliderPos-_sliderSpacing)) / sliderRange;
    updateGain(level);

    // draw dB inside slider
    //painter.setPen(_frameColor);
    //QRect dBRect(_sliderPos+_sliderWidth/2-20, _height/2+_lineOffset-10, 40, 20);
    //painter.drawText(dBRect, Qt::AlignCenter, QString::number(static_cast<double>(level), 'f', 1) + QString(" dB"));
}

void Fader::updateParam(unsigned int *level)
{
    // 0dB = 255
    *level = static_cast<unsigned int>(255+_gainLevel*2);
}

void Fader::updateGain(float level)
{
    _gainLevel = level;
}

void Fader::mouseMoveEvent(QMouseEvent *event)
{
    bool updateRequired = false;
    // check if mouse is in slider area
    const int sliderTop = _height/2+_lineOffset-_sliderHeight/2;
    if (((event->pos().x() > _sliderPos) && (event->pos().x() < (_sliderPos+_sliderWidth))) &&
        ((event->pos().y() > sliderTop) && (event->pos().y() < sliderTop+_sliderHeight)))  {
        if (!_sliderActive) {
            updateRequired = true;
        }
        _sliderActive = true;
    } else {
        if (_sliderActive) {
            updateRequired = true;
        }
        _sliderActive = false;
    }
    // move slider
    if ((event->buttons() & Qt::LeftButton) && _moveEnable) {
        _moveValueX = event->pos().x() - _oldMousePosX;
        _oldMousePosX = event->pos().x();
        _sliderPos += _moveValueX;
        if (_sliderPos < _sliderSpacing) {
            _sliderPos = _sliderSpacing;
        }
        if (_sliderPos > _width-_sliderWidth-_sliderSpacing) {
            _sliderPos =_width-_sliderWidth-_sliderSpacing;
        }
        updateRequired = true;
    } else {
        _moveValueX = 0;
    }
    // change color
    if ((_moveEnable) || (_sliderActive)) {
        _sliderColor = _sliderActiveColor;
    } else {
        if (_sliderColor == _sliderActiveColor) {
            updateRequired = true;
        }
        _sliderColor = _sliderInactiveColor;
    }
    // update view
    if (updateRequired) {
        update();
    }
}

void Fader::mousePressEvent(QMouseEvent *event)
{
    if (event->button() == Qt::LeftButton) {
        _oldMousePosX = event->pos().x();
        _moveEnable = _sliderActive;
    }
}

void Fader::mouseReleaseEvent(QMouseEvent *event)
{
    if (event->button() == Qt::LeftButton && _moveEnable) {
        _moveEnable = false;
    }
}
