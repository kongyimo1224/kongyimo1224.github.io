/*!*****************************************************************************
\file Shaders/Assignment8.frag.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 8
\date 02/28/2026
\brief
  Fragment shader implementing fog + effect routing:
  0 = PBR, 1 = discard, 2 = cartoon, 3 = checkerboard.
*******************************************************************************/
#version 330 core

const float PI = 3.14159265358979323846;

struct Light
{
    vec3 position;      // Position in world space

    vec3 L;             // Intensity used by PBR branch

    vec3 La;            // Ambient intensity for Phong branches
    vec3 Ld;            // Diffuse intensity for Phong branches
    vec3 Ls;            // Specular intensity for Phong branches
};

struct Material
{
    // PBR params
    float rough;
    float metal;
    vec3 color;

    // Phong params
    vec3 Ka;
    vec3 Kd;
    vec3 Ks;
    float shininess;

    float effect;
};

struct Fog
{
    float minDist;
    float maxDist;
    vec4 color;
};

in vec3 Position;
in vec3 Normal;
in vec2 TexCoord;

uniform Light light[1];
uniform Material material;
uniform Fog fog;
uniform mat4 V;

layout(location = 0) out vec4 FragColor;

vec3 checkerboardTexture(vec2 uv, float size)
{
    vec2 cell = floor(uv * size);
    float parity = mod(cell.x + cell.y, 2.0);
    return (parity < 0.5) ? vec3(0.08) : vec3(0.88);
}

float cartoon(float value)
{
    int levels = 3;
    float scale = 1.0 / float(levels);
    return floor(clamp(value, 0.0, 1.0) * float(levels)) * scale;
}

vec3 blinnPhong(vec3 position, vec3 n, Light lgt, Material mat, mat4 view)
{
    vec3 lightPosView = (view * vec4(lgt.position, 1.0)).xyz;
    vec3 toLight = normalize(lightPosView - position);
    vec3 toView = normalize(-position);
    vec3 h = normalize(toLight + toView);

    vec3 ambient = lgt.La * mat.Ka;

    float diff = max(dot(toLight, n), 0.0);
    vec3 diffuse = lgt.Ld * mat.Kd * diff;

    float specFactor = pow(max(dot(h, n), 0.0), mat.shininess);
    vec3 spec = lgt.Ls * mat.Ks * specFactor;

    return ambient + diffuse + spec;
}

vec3 blinnPhongCartoon(vec3 position, vec3 n, Light lgt, Material mat, mat4 view)
{
    vec3 lightPosView = (view * vec4(lgt.position, 1.0)).xyz;
    vec3 toLight = normalize(lightPosView - position);
    vec3 toView = normalize(-position);
    vec3 h = normalize(toLight + toView);

    vec3 ambient = lgt.La * mat.Ka;

    float diff = cartoon(max(dot(toLight, n), 0.0));
    vec3 diffuse = lgt.Ld * mat.Kd * diff;

    float specFactor = cartoon(pow(max(dot(h, n), 0.0), mat.shininess));
    vec3 spec = lgt.Ls * mat.Ks * specFactor;

    return ambient + diffuse + spec;
}

float ggxDistribution(float nDotH)
{
    float alpha2 = material.rough * material.rough * material.rough * material.rough;
    float d = (nDotH * nDotH) * (alpha2 - 1.0) + 1.0;
    return alpha2 / (PI * d * d);
}

float geomSmith(float nDotL)
{
    float k = (material.rough + 1.0) * (material.rough + 1.0) / 8.0;
    float denom = nDotL * (1.0 - k) + k;
    return 1.0 / denom;
}

vec3 schlickFresnel(float lDotH)
{
    vec3 f0 = vec3(0.04);
    if (material.metal == 1.0)
        f0 = material.color;
    return f0 + (1.0 - f0) * pow(1.0 - lDotH, 5.0);
}

vec3 microfacetModel(vec3 position, vec3 n)
{
    vec3 diffuseBrdf = material.color;

    vec3 lightI = light[0].L;
    vec3 lightPosView = (V * vec4(light[0].position, 1.0)).xyz;

    vec3 l = lightPosView - position;
    float dist = length(l);
    l = normalize(l);

    lightI *= 100.0 / (dist * dist);

    vec3 v = normalize(-position);
    vec3 h = normalize(v + l);

    float nDotH = max(dot(n, h), 0.0);
    float lDotH = max(dot(l, h), 0.0);
    float nDotL = max(dot(n, l), 0.0);
    float nDotV = max(dot(n, v), 0.0);

    vec3 specBrdf = 0.25 * ggxDistribution(nDotH) * schlickFresnel(lDotH)
        * geomSmith(nDotL) * geomSmith(nDotV);

    return (diffuseBrdf + PI * specBrdf) * lightI * nDotL;
}

void main()
{
    vec3 n = normalize(Normal);

    int effect = int(material.effect + 0.5);
    vec3 color;

    if (effect == 1)
    {
        // Custom discard pattern: remove fragments inside circular dots and rings.
        vec2 local = fract(TexCoord * 8.0) - vec2(0.5);
        float r = length(local);
        if (r < 0.22 || (r > 0.31 && r < 0.39))
            discard;

        color = blinnPhong(Position, n, light[0], material, V);
    }
    else if (effect == 2)
    {
        color = blinnPhongCartoon(Position, n, light[0], material, V);
    }
    else if (effect == 3)
    {
        vec3 lit = blinnPhong(Position, n, light[0], material, V);
        vec3 checks = checkerboardTexture(TexCoord, 10.0);
        color = mix(lit, checks, 0.65);
    }
    else
    {
        // effect == 0: physically based rendering
        color = microfacetModel(Position, n);
    }

    float dist = length(Position);
    float fogFactor = clamp((dist - fog.minDist) / (fog.maxDist - fog.minDist), 0.0, 1.0);

    vec3 fogged = mix(color, fog.color.rgb, fogFactor);

    // Gamma correction
    fogged = pow(max(fogged, vec3(0.0)), vec3(1.0 / 2.2));

    FragColor = vec4(fogged, 1.0);
}
