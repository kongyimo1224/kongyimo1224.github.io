/*!*****************************************************************************
\file Cartoon.frag.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 9 (Stylized NPR Viewer)
\date 03/07/2026
\brief
  Cartoon shading pass. Re-renders the scene with quantized diffuse lighting and
  banded highlights to create the cel-shaded base image.
******************************************************************************/
#version 420

struct Light
{
    vec3 position;
    vec3 L;
    vec3 La;
    vec3 Ld;
    vec3 Ls;
};

struct Material
{
    float rough;
    float metal;
    vec3 color;
    vec3 Ka;
    vec3 Kd;
    vec3 Ks;
    float shininess;
    float effect;
};

in vec3 Position;
in vec3 Normal;

uniform Light light[1];
uniform Material material;
uniform mat4 V;
uniform int ToonLevels = 4;

layout(location = 0) out vec4 FragColor;

float quantize(float value, int levels)
{
    int safeLevels = max(levels, 2);
    float scaled = floor(clamp(value, 0.0, 1.0) * float(safeLevels));
    return scaled / float(safeLevels - 1);
}

void main()
{
    vec3 normalVector = normalize(Normal);
    vec3 lightPosView = (V * vec4(light[0].position, 1.0)).xyz;
    vec3 toLight = normalize(lightPosView - Position);
    vec3 toView = normalize(-Position);
    vec3 halfVector = normalize(toLight + toView);

    float diffuseTerm = quantize(max(dot(toLight, normalVector), 0.0), ToonLevels);
    float specularRaw = pow(max(dot(halfVector, normalVector), 0.0), material.shininess);
    float specularBand = (specularRaw > 0.45) ? 1.0 : 0.0;

    vec3 ambient = light[0].La * material.Ka * 0.6;
    vec3 diffuse = light[0].Ld * material.Kd * diffuseTerm;
    vec3 specular = light[0].Ls * material.Ks * specularBand * 0.35;

    vec3 color = ambient + diffuse + specular;
    color = pow(max(color, vec3(0.0)), vec3(1.0 / 2.2));

    FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
