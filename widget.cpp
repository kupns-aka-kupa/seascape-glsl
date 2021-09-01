#include "widget.hpp"

#include <QMouseEvent>
#include <QOpenGLShaderProgram>
#include <QCoreApplication>
#include <Qt3DRender/QMesh>

bool GLWidget::_transparent = false;

GLWidget::GLWidget(QWidget *parent)
        : QOpenGLWidget(parent)
{
    if (_transparent) {
        QSurfaceFormat fmt = format();
        fmt.setAlphaBufferSize(8);
        setFormat(fmt);
    }
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
    _logoVbo.destroy();
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

    QFile vertexFile(":/shaders/vector/vector_v2.glsl");

    vertexFile.open(QFile::ReadOnly | QFile::Text);

    QTextStream in(&vertexFile);

    _program = new QOpenGLShaderProgram;
    _program->addShaderFromSourceCode(QOpenGLShader::Vertex, in.readAll());

    QFile fragmentFile(":/shaders/fragment/fragment_v2.glsl");
    fragmentFile.open(QFile::ReadOnly | QFile::Text);
    in.reset();
    in.setDevice(&fragmentFile);

    _program->addShaderFromSourceCode(QOpenGLShader::Fragment, in.readAll());
    _program->bindAttributeLocation("vertex", 0);
    _program->bindAttributeLocation("normal", 1);
    _program->link();

    _program->bind();
    _projMatrixLoc = _program->uniformLocation("projMatrix");
    _mvMatrixLoc = _program->uniformLocation("mvMatrix");
    _normalMatrixLoc = _program->uniformLocation("normalMatrix");
    _lightPosLoc = _program->uniformLocation("lightPos");

    // Create a vertex array object. In OpenGL ES 2.0 and OpenGL 2.x
    // implementations this is optional and support may not be present
    // at all. Nonetheless the below code works in all cases and makes
    // sure there is a VAO when one is needed.
    _vao.create();
    QOpenGLVertexArrayObject::Binder vaoBinder(&_vao);

    // Setup our vertex buffer object.
    _logoVbo.create();
    _logoVbo.bind();
    _logoVbo.allocate(_logo.constData(), _logo.count() * sizeof(GLfloat));

    // Store the vertex attribute bindings for the program.
    setupVertexAttribs();

    // Our camera never changes in this example.
    _camera.setToIdentity();
    _camera.translate(0, 0, -1);

    // Light position is fixed.
    _program->setUniformValue(_lightPosLoc, QVector3D(0, 0, 70));

    _program->release();
}

void GLWidget::setupVertexAttribs()
{
    _logoVbo.bind();
    QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
    f->glEnableVertexAttribArray(0);
    f->glEnableVertexAttribArray(1);
    f->glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat),
                             nullptr);
    f->glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat),
                             reinterpret_cast<void *>(3 * sizeof(GLfloat)));
    _logoVbo.release();
}

void GLWidget::paintGL()
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);

    _world.setToIdentity();
    _world.rotate(180.0f - (_xRot / 16.0f), 1, 0, 0);
    _world.rotate(_yRot / 16.0f, 0, 1, 0);
    _world.rotate(_zRot / 16.0f, 0, 0, 1);

    QOpenGLVertexArrayObject::Binder vaoBinder(&_vao);
    _program->bind();
    _program->setUniformValue(_projMatrixLoc, _proj);
    _program->setUniformValue(_mvMatrixLoc, _camera * _world);
    QMatrix3x3 normalMatrix = _world.normalMatrix();
    _program->setUniformValue(_normalMatrixLoc, normalMatrix);

    glDrawArrays(GL_TRIANGLES, 0, _logo.vertexCount());

    _program->release();
}

void GLWidget::resizeGL(int w, int h)
{
    _proj.setToIdentity();
    _proj.perspective(45.0f, GLfloat(w) / h, 0.01f, 100.0f);
}

void GLWidget::mousePressEvent(QMouseEvent *event)
{
    m_lastPos = event->pos();
}

void GLWidget::mouseMoveEvent(QMouseEvent *event)
{
    int dx = event->x() - m_lastPos.x();
    int dy = event->y() - m_lastPos.y();

    if (event->buttons() & Qt::LeftButton) {
        setXRotation(_xRot + 8 * dy);
        setYRotation(_yRot + 8 * dx);
    } else if (event->buttons() & Qt::RightButton) {
        setXRotation(_xRot + 8 * dy);
        setZRotation(_zRot + 8 * dx);
    }
    m_lastPos = event->pos();
}

