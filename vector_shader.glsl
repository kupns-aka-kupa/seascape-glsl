#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 color ;

void main()
{
    gl_Position = vec4(aPos, 1.0); // see how we directly give a vec3 to vec4's constructor
}