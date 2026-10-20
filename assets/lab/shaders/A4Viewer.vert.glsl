/*!*****************************************************************************
\file Viewer.vert.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 5 (Tabs + Viewer)
\date 02/06/2026
\brief
  Viewer vertex shader. Transforms vertices using M/V/P and outputs
  world-space position and normal for per-fragment lighting.
*******************************************************************************/
#version 330 core
layout(location = 0) in vec3 position;
layout(location = 1) in vec3 normal;

out vec3 vWorldPos;
out vec3 vWorldNormal;

uniform mat4 M;
uniform mat4 V;
uniform mat4 P;

void main()
{
    vec4 world = M * vec4(position, 1.0);
    vWorldPos = world.xyz;
    vWorldNormal = mat3(transpose(inverse(M))) * normal;

    gl_Position = P * V * world;
}
