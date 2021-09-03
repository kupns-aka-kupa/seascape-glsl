#include "widget.hpp"

#include <QMouseEvent>
#include <QDateTime>
#include <QOpenGLShaderProgram>
#include <QCoreApplication>
#include <Qt3DRender/QMesh>
#include <QPainter>

bool GLWidget::_transparent = false;

GLWidget::GLWidget(QWidget *parent)
: QOpenGLWidget(parent)
, _program(nullptr)
, _vbo(QOpenGLBuffer::VertexBuffer)
, _ebo(QOpenGLBuffer::IndexBuffer)
{
    if (_transparent) {
        QSurfaceFormat fmt = format();
        fmt.setAlphaBufferSize(8);
        setFormat(fmt);
    }
    _timer.start();
}

GLWidget::~GLWidget()
{
    cleanup();
}

QSize GLWidget::minimumSizeHint() const
{
    return QSize(50, 50);
}

QSize GLWidget::sizeHint() const
{
    return QSize(400, 400);
}

static void qNormalizeAngle(int &angle)
{
    while (angle < 0)
        angle += 360 * 16;
    while (angle > 360 * 16)
        angle -= 360 * 16;
}

void GLWidget::setXRotation(int angle)
{
    qNormalizeAngle(angle);
    if (angle != _xRot) {
        _xRot = angle;
        emit xRotationChanged(angle);
        update();
    }
}

void GLWidget::setYRotation(int angle)
{
    qNormalizeAngle(angle);
    if (angle != _yRot) {
        _yRot = angle;
        emit yRotationChanged(angle);
        update();
    }
}

void GLWidget::setZRotation(int angle)
{
    qNormalizeAngle(angle);
    if (angle != _zRot) {
        _zRot = angle;
        emit zRotationChanged(angle);
        update();
    }
}

void GLWidget::cleanup()
{
    if (_program == nullptr)
        return;
    makeCurrent();
    _vbo.destroy();
    _ebo.destroy();
    delete _program;
    _program = nullptr;
    doneCurrent();
}

void GLWidget::initializeGL()
{
    connect(context(), &QOpenGLContext::aboutToBeDestroyed, this, &GLWidget::cleanup);

    initializeOpenGLFunctions();

    auto *mesh = new Qt3DRender::QMesh();
    mesh->setSource(QUrl(QStringLiteral(":/obj/cube.obj")));

    glClearColor(0, 0, 0, _transparent ? 0 : 1);

    _program = new QOpenGLShaderProgram;
    _program->addShaderFromSourceFile(QOpenGLShader::Vertex, ":/shaders/vertex/transpose");
    _program->addShaderFromSourceFile(QOpenGLShader::Fragment, ":/shaders/fragment/seascape");

    _program->bindAttributeLocation("vertex", 0);
    _program->bindAttributeLocation("normal", 1);

    if (!_program->link())
    {
        close();
    }

    if (!_program->bind())
    {
        close();
    }

    _projMatrixLoc = _program->uniformLocation("projMatrix");
    _mvMatrixLoc = _program->uniformLocation("mvMatrix");
    _normalMatrixLoc = _program->uniformLocation("normalMatrix");

    _timeLoc = _program->uniformLocation("iTime");
    _resolutionLoc = _program->uniformLocation("iResolution");
    _mouseLoc = _program->uniformLocation("iMouse");

    _lightPosLoc = _program->uniformLocation("lightPos");

    // Create a vertex array object. In OpenGL ES 2.0 and OpenGL 2.x
    // implementations this is optional and support may not be present
    // at all. Nonetheless the below code works in all cases and makes
    // sure there is a VAO when one is needed.
    _vao.create();
    _vbo.create();
    _ebo.create();
    QOpenGLVertexArrayObject::Binder vaoBinder(&_vao);

    QVector3D vertices[] =
    {
        {-1, -1, 0.0f},
        {1, -1, 0.0f},
        {1, 1, 0.0f},
        {-1, 1, 0.0f},
    };

    QVector3D indices[] =
    {
        {0, 1, 2},
        {0, 2, 3}
    };

    // Setup our vertex buffer object.
    _vbo.bind();
    _vbo.setUsagePattern(QOpenGLBuffer::StaticDraw);
//    _vbo.allocate(_logo.constData(), _logo.count() * sizeof(GLfloat));
    _vbo.allocate(vertices, sizeof(vertices));

    QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
    f->glEnableVertexAttribArray(0);
//    glEnableVertexAttribArray(1);
    f->glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(QVector3D), nullptr);
//    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat),
//                          reinterpret_cast<void *>(3 * sizeof(GLfloat)));

    _vbo.release();

    _ebo.bind();
    _ebo.setUsagePattern(QOpenGLBuffer::StaticDraw);
    _ebo.allocate(indices, sizeof(indices));
    _ebo.release();

    // Our camera never changes in this example.
    _camera.setToIdentity();
    _camera.translate(0, 0, -1);

    // Light position is fixed.
    _program->setUniformValue(_lightPosLoc, QVector3D(0, 0, 70));

    _program->release();
}

void GLWidget::paintGL()
{
    Q_ASSERT(_vbo.isCreated());
    Q_ASSERT(_vao.isCreated());

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);

    _world.setToIdentity();
    _world.rotate(180.0f - (_xRot / 16.0f), 1, 0, 0);
    _world.rotate(_yRot / 16.0f, 0, 1, 0);
    _world.rotate(_zRot / 16.0f, 0, 0, 1);

    QOpenGLVertexArrayObject::Binder vaoBinder(&_vao);
    _program->bind();
    _ebo.bind();
//    _program->setUniformValue(_projMatrixLoc, _proj);
//    _program->setUniformValue(_mvMatrixLoc, _camera * _world);
    _program->setUniformValue(_timeLoc, (float)_timer.elapsed());
    _program->setUniformValue(_resolutionLoc, QVector2D(geometry().bottomRight()));
    _program->setUniformValue(_mouseLoc, QVector2D(QCursor::pos()));
//    _program->setUniformValue(_normalMatrixLoc, _world.normalMatrix());

//    glDrawArrays(GL_TRIANGLES, 0, 3);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nullptr);

    _program->release();
}

void GLWidget::paintEvent(QPaintEvent *event)
{
    QOpenGLWidget::paintEvent(event);
//    QPainter painter;
//
//    painter.begin(this);
//    painter.fillRect(QRect(0, 0, 100, 100), QBrush(QColor(0,0,0)));
//    painter.setRenderHint(QPainter::Antialiasing);
//    painter.drawText(QRect(0, 0, 100, 100), Qt::AlignCenter, QString::number(_timer.elapsed()));
//    painter.end();
//    update();
}

void GLWidget::resizeGL(int w, int h)
{
    _proj.setToIdentity();
    _proj.perspective(45.0f, GLfloat(w) / h, 0.01f, 100.0f);
}

void GLWidget::mousePressEvent(QMouseEvent *event)
{
    _lastPos = event->pos();
}

void GLWidget::mouseMoveEvent(QMouseEvent *event)
{
    int dx = event->x() - _lastPos.x();
    int dy = event->y() - _lastPos.y();

    if (event->buttons() & Qt::LeftButton) {
        setXRotation(_xRot + 8 * dy);
        setYRotation(_yRot + 8 * dx);
    } else if (event->buttons() & Qt::RightButton) {
        setXRotation(_xRot + 8 * dy);
        setZRotation(_zRot + 8 * dx);
    }
    _lastPos = event->pos();
}

