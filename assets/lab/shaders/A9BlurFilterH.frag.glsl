/*!*****************************************************************************
\file BlurFilter.2.frag.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 9 (Stylized NPR Viewer)
\date 03/07/2026
\brief
  Horizontal Gaussian blur pass. Completes the separable blur by filtering the
  intermediate texture along the X axis.
******************************************************************************/
#version 420

layout(location = 0) out vec4 FragColor;

layout(binding = 1) uniform sampler2D Texture1;

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
        FragColor = fetchClamped(Texture1, pix);
        return;
    }

    vec4 sum = fetchClamped(Texture1, pix) * Weight[0];
    sum += fetchClamped(Texture1, pix + ivec2(-4, 0)) * Weight[4];
    sum += fetchClamped(Texture1, pix + ivec2(-3, 0)) * Weight[3];
    sum += fetchClamped(Texture1, pix + ivec2(-2, 0)) * Weight[2];
    sum += fetchClamped(Texture1, pix + ivec2(-1, 0)) * Weight[1];
    sum += fetchClamped(Texture1, pix + ivec2( 1, 0)) * Weight[1];
    sum += fetchClamped(Texture1, pix + ivec2( 2, 0)) * Weight[2];
    sum += fetchClamped(Texture1, pix + ivec2( 3, 0)) * Weight[3];
    sum += fetchClamped(Texture1, pix + ivec2( 4, 0)) * Weight[4];

    FragColor = sum;
}
