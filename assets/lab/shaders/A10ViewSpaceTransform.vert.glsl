#version 420 core

layout(location = 0) in vec3 VertexPosition;
layout(location = 1) in vec3 VertexNormal;
layout(location = 2) in vec2 VertexTexCoord;

uniform mat4 M;
uniform mat4 V;
uniform mat4 P;

out vec3 Position;
out vec3 Normal;
out vec2 TexCoord;

void main()
{
    mat4 MV = V * M;
    vec4 positionInView = MV * vec4(VertexPosition, 1.0);

    Position = positionInView.xyz;
    Normal = normalize(transpose(inverse(mat3(MV))) * VertexNormal);
    TexCoord = VertexTexCoord;

    gl_Position = P * positionInView;
}
