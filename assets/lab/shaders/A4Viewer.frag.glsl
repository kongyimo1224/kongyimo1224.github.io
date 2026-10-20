/*!*****************************************************************************
\file Viewer.frag.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 5 (Tabs + Viewer)
\date 02/06/2026
\brief
  Implements Blinn-Phong shading with a fixed ambient level (0.1) and
  adjustable light parameters.
*******************************************************************************/
#version 330 core
in vec3 vWorldPos;
in vec3 vWorldNormal;
out vec4 FragColor;

uniform mat4 V; // used to recover camera world position

struct Light
{
    vec3 position;
    vec3 color;
    float intensity;
};

uniform Light light;

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

void main()
{
    vec3 N = normalize(vWorldNormal);
    vec3 L = normalize(light.position - vWorldPos);
    vec3 Vdir = normalize(cameraWorldPos() - vWorldPos);
    vec3 H = normalize(L + Vdir);

    float NdotL = max(dot(N, L), 0.0);
    float specPow = max(material.shininess, 1.0);
    float spec = (NdotL > 0.0) ? pow(max(dot(N, H), 0.0), specPow) : 0.0;

    vec3 ambient = material.Ka * 0.1;
    vec3 diffuse = material.Kd * NdotL;
    vec3 specular = material.Ks * spec;

    vec3 color = (ambient + diffuse + specular) * light.color * light.intensity;

    // Optional simple effect hook:
    // effect == 1: discard checker pattern
    if (material.effect > 0.5 && material.effect < 1.5)
    {
        float checker = step(0.5, fract(vWorldPos.x * 0.5) + fract(vWorldPos.z * 0.5));
        if (checker < 0.5)
            discard;
    }

    FragColor = vec4(color, 1.0);
}
