/*!*****************************************************************************
\file Shaders/Skybox.frag.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 8
\date 02/28/2026
\brief
  Skybox fragment shader.
  Uses cubemap when available; otherwise renders a procedural night sky.
*******************************************************************************/
#version 330 core

in vec3 TexDir;

uniform samplerCube skyboxTex;
uniform int useCubemap;

layout(location = 0) out vec4 FragColor;

float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 proceduralNightSky(vec3 dir)
{
    vec3 d = normalize(dir);

    float horizon = clamp(d.y * 0.5 + 0.5, 0.0, 1.0);
    vec3 deep = vec3(0.01, 0.02, 0.05);
    vec3 zenith = vec3(0.03, 0.05, 0.12);
    vec3 sky = mix(deep, zenith, horizon);

    vec2 starUV = normalize(d.xz) * 75.0 + d.y * 40.0;
    float starNoise = hash12(floor(starUV));
    float stars = smoothstep(0.995, 1.0, starNoise);
    sky += vec3(stars);

    vec3 moonDir = normalize(vec3(-0.2, 0.35, -1.0));
    float moon = pow(max(dot(d, moonDir), 0.0), 420.0);
    sky += vec3(0.7, 0.75, 0.9) * moon;

    return sky;
}

void main()
{
    vec3 dir = normalize(TexDir);
    vec3 color = (useCubemap != 0)
        ? texture(skyboxTex, dir).rgb
        : proceduralNightSky(dir);

    FragColor = vec4(color, 1.0);
}
