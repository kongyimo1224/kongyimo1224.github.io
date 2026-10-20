/*!*****************************************************************************
\file Phong.frag.glsl
\author yimo.kong (yimo.kong@digipen.edu) - Primary Author, 100%
\par Course: CSD2151
\par Assignment: 9 (Stylized NPR Viewer)
\date 03/07/2026
\brief
  First scene pass fragment shader. Renders standard Blinn-Phong lighting to an
  offscreen texture that is later blurred and analyzed for edge extraction.
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

layout(location = 0) out vec4 FragColor;

vec3 blinnPhong(vec3 position, vec3 normalVector, Light lgt, Material mat, mat4 view)
{
    vec3 lightPosView = (view * vec4(lgt.position, 1.0)).xyz;
    vec3 toLight = normalize(lightPosView - position);
    vec3 toView = normalize(-position);
    vec3 halfVector = normalize(toLight + toView);

    float diffuseTerm = max(dot(toLight, normalVector), 0.0);
    float specularTerm = pow(max(dot(halfVector, normalVector), 0.0), mat.shininess);

    vec3 ambient = lgt.La * mat.Ka;
    vec3 diffuse = lgt.Ld * mat.Kd * diffuseTerm;
    vec3 specular = lgt.Ls * mat.Ks * specularTerm;

    return ambient + diffuse + specular;
}

void main()
{
    vec3 normalVector = normalize(Normal);
    vec3 color = blinnPhong(Position, normalVector, light[0], material, V);
    FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
