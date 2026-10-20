/*!*****************************************************************************
\file EdgeFilter.frag.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 9 (Stylized NPR Viewer)
\date 03/07/2026
\brief
  Sobel edge detection pass. Computes luminance gradients from the blurred scene
  and produces a monochrome outline texture for the final composite.
******************************************************************************/
#version 420

layout(location = 0) out vec4 FragColor;

layout(binding = 2) uniform sampler2D Texture2;

uniform bool UseEdge = true;
uniform float EdgeThreshold = 0.12;

float luminance(vec3 color)
{
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float sampleLuma(ivec2 pixel)
{
    ivec2 size = textureSize(Texture2, 0);
    ivec2 clamped = clamp(pixel, ivec2(0), size - 1);
    return luminance(texelFetch(Texture2, clamped, 0).rgb);
}

void main()
{
    if (!UseEdge)
    {
        FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    ivec2 pix = ivec2(gl_FragCoord.xy);

    float s00 = sampleLuma(pix + ivec2(-1,  1));
    float s10 = sampleLuma(pix + ivec2(-1,  0));
    float s20 = sampleLuma(pix + ivec2(-1, -1));
    float s01 = sampleLuma(pix + ivec2( 0,  1));
    float s21 = sampleLuma(pix + ivec2( 0, -1));
    float s02 = sampleLuma(pix + ivec2( 1,  1));
    float s12 = sampleLuma(pix + ivec2( 1,  0));
    float s22 = sampleLuma(pix + ivec2( 1, -1));

    float sx = s00 + 2.0 * s10 + s20 - (s02 + 2.0 * s12 + s22);
    float sy = s00 + 2.0 * s01 + s02 - (s20 + 2.0 * s21 + s22);

    float gradient = length(vec2(sx, sy));
    float edge = (gradient > EdgeThreshold) ? 1.0 : 0.0;

    FragColor = vec4(vec3(edge), 1.0);
}
