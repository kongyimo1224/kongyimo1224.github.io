/*!*****************************************************************************
\file ViewSpaceTransform.vert.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 9 (Stylized NPR Viewer)
\date 03/07/2026
\brief
  Vertex shader for scene geometry. Transforms vertices to view space and passes
  view-space position, transformed normal, and texture coordinates onward.
******************************************************************************/
#version 420

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
    mat4 modelView = V * M;
    vec4 viewPosition = modelView * vec4(position, 1.0);

    Position = viewPosition.xyz;
    Normal = normalize(transpose(inverse(mat3(modelView))) * normal);
    TexCoord = texCoord;

    gl_Position = P * viewPosition;
}
