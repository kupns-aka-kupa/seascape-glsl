cmake_minimum_required(VERSION 3.14)

project(Seascape)

include(ExternalProject)

find_package(GSL REQUIRED)
find_package(glm REQUIRED)
find_package(OpenSceneGraph REQUIRED COMPONENTS osgDB)
find_package(OpenGL REQUIRED)
find_package(glfw3 REQUIRED)
find_package(fmt REQUIRED)
find_package(GLEW REQUIRED)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_CXX_STANDARD 17)

set(GLAD_URL https://glad.dav1d.de/generated/tmpg_m4gwk2glad/glad.zip)

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

file(GLOB SHADER_FILES *.glsl)
file(COPY ${SHADER_FILES} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/obj DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

file(GLOB SOURCE_FILES ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)
add_executable(${PROJECT_NAME} ${SOURCE_FILES} ${GLAD_FILES})
add_dependencies(${PROJECT_NAME} GladExternal)

target_include_directories(${PROJECT_NAME}
    PRIVATE
        ${GLAD_INCLUDE_DIRECTORIES}
        ${GSL_INCLUDE_DIRS}
        ${GLM_INCLUDE_DIRS}
        ${OPENSCENEGRAPH_INCLUDE_DIRS}
        ${OPENGL_INCLUDE_DIR}
        ${GLEW_INCLUDE_DIRS})

target_compile_definitions(${PROJECT_NAME} PRIVATE
        PROJECT_NAME="${PROJECT_NAME}"
        PROJECT_VERSION="${PROJECT_VERSION}")

target_link_libraries(${PROJECT_NAME}
    PRIVATE
        glfw
        ${GSL_LIBRARIES}
        ${OPENGL_LIBRARIES}
        ${OPENSCENEGRAPH_LIBRARIES}
        ${GLEW_LIBRARIES}
        glm::glm
        fmt::fmt
        ${CMAKE_DL_LIBS})
