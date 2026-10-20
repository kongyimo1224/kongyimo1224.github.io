/*!*****************************************************************************
\file Composite.frag.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 9 (Stylized NPR Viewer)
\date 03/07/2026
\brief
  Final compositing pass. Blends the cartoon-shaded render with the detected
  outlines and also supports a blur-only presentation when edges are disabled.
******************************************************************************/
#version 420

in vec2 UV;

layout(location = 0) out vec4 FragColor;

layout(binding = 3) uniform sampler2D EdgeTexture;
layout(binding = 4) uniform sampler2D CartoonTexture;

uniform bool UseBlur = true;
uniform bool UseEdge = true;
uniform float AlphaFactor = 1.0;

const float Weight[5] = float[5](
    0.158435,
    0.148836,
    0.123389,
    0.0902733,
    0.0582848
);

vec3 sampleHorizontalBlur(vec2 uv, vec2 texelSize)
{
    vec3 sum = texture(CartoonTexture, uv).rgb * Weight[0];
    for (int i = 1; i < 5; ++i)
    {
        sum += texture(CartoonTexture, uv + vec2(texelSize.x * float(i), 0.0)).rgb * Weight[i];
        sum += texture(CartoonTexture, uv - vec2(texelSize.x * float(i), 0.0)).rgb * Weight[i];
    }
    return sum;
}

vec3 sampleVerticalBlur(vec2 uv, vec2 texelSize)
{
    vec3 sum = texture(CartoonTexture, uv).rgb * Weight[0];
    for (int i = 1; i < 5; ++i)
    {
        sum += texture(CartoonTexture, uv + vec2(0.0, texelSize.y * float(i))).rgb * Weight[i];
        sum += texture(CartoonTexture, uv - vec2(0.0, texelSize.y * float(i))).rgb * Weight[i];
    }
    return sum;
}

void main()
{
    vec3 cartoon = texture(CartoonTexture, UV).rgb;
    vec2 texelSize = 1.0 / vec2(textureSize(CartoonTexture, 0));

    if (!UseEdge)
    {
        vec3 color = cartoon;
        if (UseBlur)
            color = 0.5 * (sampleHorizontalBlur(UV, texelSize) + sampleVerticalBlur(UV, texelSize));

        FragColor = vec4(color, 1.0);
        return;
    }

    float edge = texture(EdgeTexture, UV).r;
    float outline = clamp(edge * AlphaFactor, 0.0, 1.0);
    vec3 color = mix(cartoon, vec3(0.0), outline);
    FragColor = vec4(color, 1.0);
}
