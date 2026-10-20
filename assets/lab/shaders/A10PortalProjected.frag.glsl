#version 420 core

in vec2 TexCoord;

uniform float PortalBlend = 0.82;

layout(binding = 1) uniform sampler2D PortalTexture;

layout(location = 0) out vec4 FragColor;

void main()
{
    vec4 portal = texture(PortalTexture, TexCoord);
    vec3 color = portal.rgb + portal.rgb * portal.a * 0.35;
    float alpha = clamp(portal.a * PortalBlend, 0.0, 1.0);
    FragColor = vec4(color, alpha);
}
