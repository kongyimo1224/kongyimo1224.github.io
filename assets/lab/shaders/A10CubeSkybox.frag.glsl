#version 420 core

in vec3 CubeDir;

layout(binding = 0) uniform samplerCube SkyboxTexture;
uniform float Exposure = 1.0;

layout(location = 0) out vec4 FragColor;

void main()
{
    vec3 hdrColor = texture(SkyboxTexture, normalize(CubeDir)).rgb;
    vec3 mapped = vec3(1.0) - exp(-hdrColor * Exposure);
    mapped = pow(mapped, vec3(1.0 / 2.2));
    FragColor = vec4(mapped, 1.0);
}
