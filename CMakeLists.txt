cmake_minimum_required(VERSION 3.14)

project(Seascape)

include(ExternalProject)

find_package(GSL REQUIRED)
find_package(glm REQUIRED)
find_package(OpenSceneGraph REQUIRED COMPONENTS osgDB)
find_package(OpenGL REQUIRED)
find_package(GLEW REQUIRED)

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Widgets OpenGL 3DCore 3DRender REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Widgets OpenGL 3DCore 3DRender REQUIRED)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)

set(GLAD_URL https://glad.dav1d.de/generated/tmp5_gi6ks8glad/glad.zip)

ExternalProject_Add(GladExternal
        URL ${GLAD_URL}
        BUILD_ALWAYS OFF
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        UPDATE_COMMAND ""
        INSTALL_COMMAND "")

ExternalProject_Get_Property(GladExternal SOURCE_DIR)
set(GLAD_INCLUDE_DIRECTORIES ${SOURCE_DIR}/include)
file(GLOB_RECURSE GLAD_FILES ${SOURCE_DIR}/*)

file(GLOB SOURCE_FILES ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)
set(RESOURCE_FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/shaders/shaders.qrc
#        ${CMAKE_CURRENT_SOURCE_DIR}/obj/obj.qrc
        )

add_executable(${PROJECT_NAME} ${SOURCE_FILES} ${RESOURCE_FILES} ${GLAD_FILES})
add_dependencies(${PROJECT_NAME} GladExternal)

target_include_directories(${PROJECT_NAME}
    PRIVATE
        ${GLAD_INCLUDE_DIRECTORIES}
        ${GSL_INCLUDE_DIRS}
        ${GLM_INCLUDE_DIRS}
        ${FREETYPE_INCLUDE_DIRS}
        ${OPENSCENEGRAPH_INCLUDE_DIRS}
        ${OPENGL_INCLUDE_DIR}
        ${GLEW_INCLUDE_DIRS})

target_compile_definitions(${PROJECT_NAME} PRIVATE
        PROJECT_NAME="${PROJECT_NAME}"
        PROJECT_VERSION="${PROJECT_VERSION}")

target_link_libraries(${PROJECT_NAME}
    PRIVATE
        Qt${QT_VERSION_MAJOR}::Core
        Qt${QT_VERSION_MAJOR}::Widgets
        Qt${QT_VERSION_MAJOR}::OpenGL
        Qt${QT_VERSION_MAJOR}::3DCore
        Qt${QT_VERSION_MAJOR}::3DRender
        ${GSL_LIBRARIES}
        ${OPENGL_LIBRARIES}
        ${OPENSCENEGRAPH_LIBRARIES}
        ${GLEW_LIBRARIES}
        glm::glm
        ${CMAKE_DL_LIBS})
