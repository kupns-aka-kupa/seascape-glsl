
#ifndef SEASCAPE_MAINWINDOW_HPP
#define SEASCAPE_MAINWINDOW_HPP

#include <QMainWindow>

class MainWindow : public QMainWindow
{
Q_OBJECT

public:
    MainWindow();

private slots:
    void onAddNew();
};

#endif //SEASCAPE_MAINWINDOW_HPP
