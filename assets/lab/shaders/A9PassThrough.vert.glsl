/*!*****************************************************************************
\file PassThrough.vert.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 9 (Stylized NPR Viewer)
\date 03/07/2026
\brief
  Fullscreen post-processing vertex shader. Forwards the quad UVs unchanged so
  fragment shaders can sample intermediate render targets.
******************************************************************************/
#version 420

layout(location = 0) in vec3 position;
layout(location = 2) in vec2 texCoord;

out vec2 UV;

void main()
{
    UV = texCoord;
    gl_Position = vec4(position.xy, 0.0, 1.0);
}
