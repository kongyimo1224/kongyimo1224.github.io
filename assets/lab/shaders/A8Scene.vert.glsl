/*!*****************************************************************************
\file Shaders/Assignment8.vert.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 8
\date 02/28/2026
\brief
  View-space transform vertex shader for Assignment 8 rendering.
*******************************************************************************/
#version 330 core

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 texCoord;

uniform mat4 M;
uniform mat4 V;
uniform mat4 P;

out vec3 Position;
out vec3 Normal;
out vec2 TexCoord;

void main()
{
    mat4 MV = V * M;
    vec4 positionInView = MV * vec4(position, 1.0);

    Position = positionInView.xyz;
    Normal = normalize(transpose(inverse(mat3(MV))) * normal);
    TexCoord = texCoord;

    gl_Position = P * positionInView;
}
