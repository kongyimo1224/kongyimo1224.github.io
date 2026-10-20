/*!*****************************************************************************
\file Viewer.vert.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 8 (Tabs + Viewer)
\date 02/28/2026
\brief
  Viewer vertex shader. Transforms vertices using M/V/P and outputs
  world-space position and normal for per-fragment lighting.
*******************************************************************************/
#version 330 core
layout(location = 0) in vec3 position;
layout(location = 1) in vec3 normal;

out vec3 vWorldPos;
out vec3 vWorldNormal;
out vec3 vDir;

uniform mat4 M;
uniform mat4 V;
uniform mat4 P;
uniform int Pass;

void main()
{
    if (Pass == 0)
    {
        vDir = position;
        gl_Position = P * V * vec4(position, 1.0);
        vWorldPos = vec3(0.0);
        vWorldNormal = vec3(0.0, 1.0, 0.0);
    }
    else
    {
        vec4 world = M * vec4(position, 1.0);
        vWorldPos = world.xyz;
        vWorldNormal = mat3(transpose(inverse(M))) * normal;
        vDir = vec3(0.0);
        gl_Position = P * V * world;
    }
}
