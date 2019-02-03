//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 20.01.2019
// Filename  : meter.cpp
// Changelog : 20.01.2019 - file created
//------------------------------------------------------------------------------

#include "meter.h"

#include <QPainter>
#include <QFont>
#include <QtMath>

Meter::Meter(QString label) :
    _frameColor(230, 230, 230),
    _backgroundColor(0, 100, 220),
    _barColor(200, 50, 50),
    _labelFont(),
    _markerFont(),
    _label(label),
    _width(250),
    _height(90),
    _level(200),
    _levelBar(-100),
    _levelDisplay(-100.0f)
{
    _labelFont.setPixelSize(12);
    _labelFont.setBold(true);
    _labelFont.setFamily("Tahoma");
    _markerFont.setPixelSize(9);
    setFixedSize(QSize(_width, _height));
}

Meter::~Meter() {}

void Meter::updateParam(unsigned int *level)
{
    if (_level < *level) {
        if (_level < (*level - 2)) {
            _level = _level + 2;
        } else {
            _level = *level;
        }
    } else if (_level > *level) {
        _level = *level;
    }

    _levelDisplay = (_levelDisplay*0.8f) + (-static_cast<float>(_level)/2*0.2f);

    if (_level > 200) {
        _levelBar = -100;
    } else {
        _levelBar = -static_cast<int>(_level)/2;
    }
    update();
}

void Meter::paintEvent(QPaintEvent *)
{
    int circleRadius = 210;
    int outerRadius = static_cast<int>(circleRadius*9.3/10);
    int innerRadius = static_cast<int>(circleRadius*8.0/10);
    int textRadius = static_cast<int>(circleRadius*8.65/10);
    int markLength = _height/20;
    qreal span = 0.8;

    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing);

    // draw frame
    painter.setPen(_backgroundColor);
    painter.setBrush(_backgroundColor);
    QRect frame(0, 0, _width, _height);
    painter.drawRoundedRect(frame, 5, 5);

    QRect textRect(_width/2-30, static_cast<int>(_height*0.78-9), 60, 18);
    painter.setPen(_frameColor);
    painter.setFont(_labelFont);
    painter.drawText(textRect, Qt::AlignCenter, _label);

    // draw dB text field
    //QRect textRect(_width/2-30, static_cast<int>(_height*0.78-9), 60, 18);
    //painter.setPen(_frameColor);
    //painter.setBrush(_frameColor);
    //painter.drawRoundedRect(textRect, 5, 5);
    //painter.setPen(_backgroundColor);
    //painter.drawText(textRect, Qt::AlignCenter, QString::number(static_cast<double>(_levelDisplay), 'f', 1) + QString(" dB"));

    // draw arc
    painter.setPen(_frameColor);
    painter.translate(_width/2, circleRadius);
    QRect outerArcRect(-outerRadius, -outerRadius, 2*outerRadius, 2*outerRadius);
    QRect innerArcRect(-innerRadius, -innerRadius, 2*innerRadius, 2*innerRadius);
    painter.drawArc(outerArcRect, static_cast<int>(16*(90-(span/2*90))), static_cast<int>(16*(span*90)));
    painter.drawArc(innerArcRect, static_cast<int>(16*(90-(span/2*90))), static_cast<int>(16*(span*90)));

    // draw 10 dB arc marker lines
    painter.setFont(_markerFont);
    int textdB = -100;
    for (qreal i=-span/2; i<=(span/2)+(span/20); i+=span/10) {
        painter.drawLine(static_cast<int>((outerRadius-markLength)*qSin(i*M_PI_2)),
                         static_cast<int>((-outerRadius+markLength)*qCos(i*M_PI_2)),
                         static_cast<int>((outerRadius+markLength)*qSin(i*M_PI_2)),
                         static_cast<int>((-outerRadius-markLength)*qCos(i*M_PI_2)));

        QRect textRect(static_cast<int>((textRadius)*qSin(i*M_PI_2))-10,
                       static_cast<int>((-textRadius)*qCos(i*M_PI_2))-10, 20, 20);
        painter.drawText(textRect, Qt::AlignCenter, QString::number(textdB));
        textdB += 10;

        painter.drawLine(static_cast<int>((innerRadius-markLength)*qSin(i*M_PI_2)),
                         static_cast<int>((-innerRadius+markLength)*qCos(i*M_PI_2)),
                         static_cast<int>((innerRadius+markLength)*qSin(i*M_PI_2)),
                         static_cast<int>((-innerRadius-markLength)*qCos(i*M_PI_2)));
    }

    // draw 2dB arc marker lines
    for (qreal i=-span/2; i<=(span/2)+(span/100); i+=span/50) {
        painter.drawLine(static_cast<int>((outerRadius-markLength/2)*qSin(i*M_PI_2)),
                         static_cast<int>((-outerRadius+markLength/2)*qCos(i*M_PI_2)),
                         static_cast<int>((outerRadius+markLength/2)*qSin(i*M_PI_2)),
                         static_cast<int>((-outerRadius-markLength/2)*qCos(i*M_PI_2)));
    }

    // draw needle
    qreal angle = (span/2 + span/100*_levelBar) * M_PI_2;
    painter.setPen(QPen(_frameColor, 5));
    painter.setOpacity(0.3);
    painter.drawLine(static_cast<int>((outerRadius+markLength*2)*qSin(angle)),
                     static_cast<int>((-outerRadius-markLength*2)*qCos(angle)),
                     static_cast<int>((innerRadius-markLength*2)*qSin(angle)),
                     static_cast<int>((-innerRadius+markLength*2)*qCos(angle)));

    painter.setPen(QPen(_barColor, 1));
    painter.setOpacity(1.0);
    painter.drawLine(static_cast<int>((outerRadius+markLength*2)*qSin(angle)),
                     static_cast<int>((-outerRadius-markLength*2)*qCos(angle)),
                     static_cast<int>((innerRadius-markLength*2)*qSin(angle)),
                     static_cast<int>((-innerRadius+markLength*2)*qCos(angle)));
}
