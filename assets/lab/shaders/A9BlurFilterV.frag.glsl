/*!*****************************************************************************
\file BlurFilter.1.frag.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 9 (Stylized NPR Viewer)
\date 03/07/2026
\brief
  Vertical Gaussian blur pass. Samples the Phong render target along the Y axis
  to reduce high-frequency noise before Sobel edge detection.
******************************************************************************/
#version 420

layout(location = 0) out vec4 FragColor;

layout(binding = 0) uniform sampler2D Texture0;

uniform bool UseBlur = true;

const float Weight[5] = float[5](
    0.158435,
    0.148836,
    0.123389,
    0.0902733,
    0.0582848
);

vec4 fetchClamped(sampler2D tex, ivec2 pixel)
{
    ivec2 size = textureSize(tex, 0);
    ivec2 clamped = clamp(pixel, ivec2(0), size - 1);
    return texelFetch(tex, clamped, 0);
}

void main()
{
    ivec2 pix = ivec2(gl_FragCoord.xy);

    if (!UseBlur)
    {
        FragColor = fetchClamped(Texture0, pix);
        return;
    }

    vec4 sum = fetchClamped(Texture0, pix) * Weight[0];
    sum += fetchClamped(Texture0, pix + ivec2(0, -4)) * Weight[4];
    sum += fetchClamped(Texture0, pix + ivec2(0, -3)) * Weight[3];
    sum += fetchClamped(Texture0, pix + ivec2(0, -2)) * Weight[2];
    sum += fetchClamped(Texture0, pix + ivec2(0, -1)) * Weight[1];
    sum += fetchClamped(Texture0, pix + ivec2(0,  1)) * Weight[1];
    sum += fetchClamped(Texture0, pix + ivec2(0,  2)) * Weight[2];
    sum += fetchClamped(Texture0, pix + ivec2(0,  3)) * Weight[3];
    sum += fetchClamped(Texture0, pix + ivec2(0,  4)) * Weight[4];

    FragColor = sum;
}
