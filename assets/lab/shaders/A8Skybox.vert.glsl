/*!*****************************************************************************
\file Shaders/Skybox.vert.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 8
\date 02/28/2026
\brief
  Skybox vertex shader.
  Removes camera translation so skybox rotates with camera but does not move.
*******************************************************************************/
#version 330 core

layout(location = 0) in vec3 position;

uniform mat4 V;
uniform mat4 P;

out vec3 TexDir;

void main()
{
    mat4 rotationOnlyView = mat4(mat3(V));
    vec4 clip = P * rotationOnlyView * vec4(position, 1.0);

    // Force skybox depth to the far plane.
    gl_Position = clip.xyww;
    TexDir = position;
}
