#version 420 core

layout(location = 0) in vec3 VertexPosition;

uniform mat4 V;
uniform mat4 P;

out vec3 CubeDir;

void main()
{
    vec4 clip = P * V * vec4(VertexPosition, 1.0);
    gl_Position = clip;
    CubeDir = VertexPosition;
}
