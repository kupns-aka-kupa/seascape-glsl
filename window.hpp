
#ifndef SEASCAPE_WINDOW_HPP
#define SEASCAPE_WINDOW_HPP


#include <QWidget>
#include <QSlider>
#include <QPushButton>
#include "mainwindow.hpp"
#include "widget.hpp"

class Window : public QWidget
{
Q_OBJECT

public:
    Window(MainWindow *mw);

protected:
    void keyPressEvent(QKeyEvent *event) override;

private slots:
    void dockUndock();

private:
    QSlider *createSlider();

    GLWidget *glWidget;
    QSlider *xSlider;
    QSlider *ySlider;
    QSlider *zSlider;
    QPushButton *dockBtn;
    MainWindow *mainWindow;
};

#endif //SEASCAPE_WINDOW_HPP
