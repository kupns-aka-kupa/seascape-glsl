cmake_minimum_required(VERSION 3.14)

project(seascape)

include(ExternalProject)

find_package(GSL REQUIRED)
find_package(OpenGL REQUIRED)
find_package(glfw3 REQUIRED)
find_package(GLEW REQUIRED)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_CXX_STANDARD 17)

set(GLAD_URL https://glad.dav1d.de/generated/tmpvb2rvq6qglad/glad.zip)

ExternalProject_Add(GladExternal
        URL ${GLAD_URL}
        PREFIX ${CMAKE_CURRENT_BINARY_DIR}
        SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/glad
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        UPDATE_COMMAND ""
        INSTALL_COMMAND "")

ExternalProject_Get_Property(GladExternal SOURCE_DIR)

file(GLOB_RECURSE GLAD_FILES ${SOURCE_DIR}/*)

file(GLOB SHADER_FILES *.glsl)
file(COPY ${SHADER_FILES} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

add_executable(${PROJECT_NAME} main.cpp shader.cpp shader.hpp ${GLAD_FILES})
add_dependencies(${PROJECT_NAME} GladExternal)

target_include_directories(${PROJECT_NAME}
    PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}/glad/include
    ${GSL_INCLUDE_DIRS}
    ${OPENGL_INCLUDE_DIR}
    ${GLEW_INCLUDE_DIRS})

target_link_libraries(${PROJECT_NAME}
    PRIVATE
    glfw
    ${GSL_LIBRARIES}
    ${OPENGL_LIBRARIES}
    ${GLEW_LIBRARIES}
    ${CMAKE_DL_LIBS})
