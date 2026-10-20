/*!*****************************************************************************
\file Assignment11GBuffer.vert.glsl
\author Yimo Kong (yimo.kong@digipen.edu)
\par Course: CSD2151
\par Assignment: 11 (Ogres)
\date 03/21/2026 (MM/DD/YYYY)
\brief
    Vertex shader for the Assignment 11 geometry pass. It transforms each
    instanced Ogre into clip space, keeps world-space position and normal data
    for the G-buffer, and also builds tangent-space light and view directions
    for deferred normal-mapped lighting in the later pass.
*******************************************************************************/
R"(
    #version 420 core

    layout(location = 0) in vec3 VertexPosition;
    layout(location = 1) in vec3 VertexNormal;
    layout(location = 2) in vec2 VertexTexCoord;
    layout(location = 3) in vec4 VertexTangent;

    struct Light
    {
        vec3 position;
        vec3 La;
        vec3 Ld;
        vec3 Ls;
    };

    uniform Light light[1];
    uniform mat4 M;
    uniform mat4 V;
    uniform mat4 P;

    out vec3 WorldPosition;
    out vec3 WorldNormal;
    out vec3 TangentLightDirection;
    out vec3 TangentViewDirection;
    out vec2 TextureCoordinates;

    void main()
    {
        mat3 worldNormalMatrix = transpose(inverse(mat3(M)));
        mat4 modelView = V * M;
        mat3 viewNormalMatrix = transpose(inverse(mat3(modelView)));

        WorldPosition = vec3(M * vec4(VertexPosition, 1.0));
        WorldNormal = normalize(worldNormalMatrix * VertexNormal);

        vec3 normal = normalize(viewNormalMatrix * VertexNormal);
        vec3 tangent = normalize(viewNormalMatrix * VertexTangent.xyz);
        tangent = normalize(tangent - dot(tangent, normal) * normal);
        vec3 bitangent = normalize(cross(normal, tangent)) * VertexTangent.w;

        mat3 toTangentSpace = mat3(
            tangent.x, bitangent.x, normal.x,
            tangent.y, bitangent.y, normal.y,
            tangent.z, bitangent.z, normal.z
        );

        vec3 vertexPositionInView = vec3(modelView * vec4(VertexPosition, 1.0));
        vec3 lightPositionInView = vec3(V * vec4(light[0].position, 1.0));

        TangentLightDirection = toTangentSpace * (lightPositionInView - vertexPositionInView);
        TangentViewDirection = toTangentSpace * normalize(-vertexPositionInView);
        TextureCoordinates = VertexTexCoord;

        gl_Position = P * modelView * vec4(VertexPosition, 1.0);
    }
)"
