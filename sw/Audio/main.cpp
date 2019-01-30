//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.12.2018
// Filename  : main.cpp
// Changelog : 27.12.2018 - file created
//------------------------------------------------------------------------------

#include "mainwindow.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    MainWindow w;

    QFile styleSheetFile(":/stylesheet.qss");
    styleSheetFile.open(QFile::ReadOnly);

    QString styleSheet(styleSheetFile.readAll());
    a.setStyleSheet(styleSheet);

    w.show();

    return a.exec();
}
