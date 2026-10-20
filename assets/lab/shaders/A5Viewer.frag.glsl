/*!*****************************************************************************
\file Viewer.frag.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 8 (Tabs + Viewer)
\date 02/28/2026
\brief
  Implements Blinn-Phong shading with a fixed ambient level (0.1) and
  adjustable light parameters.
*******************************************************************************/
#version 330 core
in vec3 vWorldPos;
in vec3 vWorldNormal;
in vec3 vDir;
out vec4 FragColor;

uniform mat4 V; // used to recover camera world position
uniform int Pass;

struct Material
{
    float shininess;
    vec3 Ka;
    vec3 Kd;
    vec3 Ks;
    float effect;

    // Extra fields used by some presets (safe to ignore if not set)
    float rough;
    float metal;
    vec3 color;
    float reflectionFactor;
    float eta;
};

uniform Material material;

vec3 cameraWorldPos()
{
    // Inverse view matrix translation
    mat4 invV = inverse(V);
    return vec3(invV[3].x, invV[3].y, invV[3].z);
}

vec4 checkerboardTexture(vec2 uv, float size)
{
    vec2 scaled = uv * size;
    vec2 cell = floor(scaled);
    float sum = cell.x + cell.y;
    float parity = mod(sum, 2.0);
    if (parity < 0.5)
        return vec4(0.0, 0.0, 0.0, 1.0);
    return vec4(1.0, 1.0, 1.0, 1.0);
}

vec2 vec2uv(vec3 v)
{
    vec3 dir = normalize(v);
    float ax = abs(dir.x);
    float ay = abs(dir.y);
    float az = abs(dir.z);

    if (ay >= ax && ay >= az)
        return vec2(0.0, 0.0);

    vec2 uv;
    if (az >= ax)
    {
        float t = 1.0 / az;
        float x = dir.x * t;
        float y = dir.y * t;
        uv = vec2((x + 1.0) * 0.5, (y + 1.0) * 0.5);
    }
    else
    {
        float t = 1.0 / ax;
        float z = dir.z * t;
        float y = dir.y * t;
        if (dir.x < 0.0)
            uv = vec2((z + 1.0) * 0.5, (y + 1.0) * 0.5);
        else
            uv = vec2((1.0 - z) * 0.5, (y + 1.0) * 0.5);
    }

    return uv;
}

vec3 sampleSky(vec3 dir)
{
    vec2 uv = vec2uv(dir);
    if (uv.x <= 0.0 && uv.y <= 0.0)
        return vec3(0.0);
    return checkerboardTexture(uv, 10.0).rgb;
}

void main()
{
    if (Pass == 0)
    {
        vec3 color = sampleSky(normalize(vDir));
        FragColor = vec4(color, 1.0);
        return;
    }

    vec3 N = normalize(vWorldNormal);
    vec3 Vdir = normalize(cameraWorldPos() - vWorldPos);
    vec3 reflectDir = reflect(-Vdir, N);
    vec3 refractDir = refract(-Vdir, N, material.eta);

    vec3 reflectColor = sampleSky(reflectDir);
    vec3 refractColor = (length(refractDir) < 0.001) ? reflectColor : sampleSky(refractDir);

    float reflectionFactor = clamp(material.reflectionFactor, 0.0, 1.0);
    vec3 envColor = mix(refractColor, reflectColor, reflectionFactor);
    vec3 baseColor = (material.color == vec3(0.0)) ? vec3(1.0) : material.color;

    FragColor = vec4(envColor * baseColor, 1.0);
}
