#ifndef SEASCAPE_WIDGET_HPP
#define SEASCAPE_WIDGET_HPP

#include <QOpenGLWidget>
#include <QOpenGLFunctions>
#include <QOpenGLVertexArrayObject>
#include <QOpenGLBuffer>
#include <QMatrix4x4>

#include "logo.hpp"

QT_FORWARD_DECLARE_CLASS(QOpenGLShaderProgram)

class GLWidget : public QOpenGLWidget, protected QOpenGLFunctions
{
    Q_OBJECT

public:
    GLWidget(QWidget *parent = nullptr);
    ~GLWidget();

    static bool isTransparent() { return _transparent; }
    static void setTransparent(bool t) { _transparent = t; }

    QSize minimumSizeHint() const override;
    QSize sizeHint() const override;

public slots:
            void setXRotation(int angle);
    void setYRotation(int angle);
    void setZRotation(int angle);
    void cleanup();

    signals:
    void xRotationChanged(int angle);
    void yRotationChanged(int angle);
    void zRotationChanged(int angle);

protected:
    void initializeGL() override;
    void paintGL() override;
    void resizeGL(int width, int height) override;
    void mousePressEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;

private:
    void setupVertexAttribs();

    int _xRot = 0;
    int _yRot = 0;
    int _zRot = 0;
    QPoint _lastPos;
    Logo _logo;
    QOpenGLVertexArrayObject _vao;
    QOpenGLBuffer _logoVbo;
    QOpenGLShaderProgram *_program = nullptr;
    int _projMatrixLoc = 0;
    int _timeLoc = 0;
    int _resolutionLoc = 0;
    int _mouseLoc = 0;
    int _mvMatrixLoc = 0;
    int _normalMatrixLoc = 0;
    int _lightPosLoc = 0;
    QMatrix4x4 _proj;
    QMatrix4x4 _camera;
    QMatrix4x4 _world;
    static bool _transparent;
};
#endif //SEASCAPE_WIDGET_HPP
