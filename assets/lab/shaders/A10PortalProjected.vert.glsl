#version 420 core

layout(location = 0) in vec3 VertexPosition;
layout(location = 2) in vec2 VertexTexCoord;

uniform mat4 M;
uniform mat4 V;
uniform mat4 P;
uniform float PortalScale = 1.35;

out vec2 TexCoord;

void main()
{
    mat4 invView = inverse(V);
    vec3 center = vec3(M[3]);
    vec3 cameraRight = normalize(vec3(invView[0]));
    vec3 cameraUp = normalize(vec3(invView[1]));

    vec3 worldPos =
        center +
        cameraRight * (VertexPosition.x * PortalScale) +
        cameraUp * (VertexPosition.y * PortalScale);

    TexCoord = VertexTexCoord;
    gl_Position = P * V * vec4(worldPos, 1.0);
}
