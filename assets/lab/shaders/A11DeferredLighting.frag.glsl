/*!*****************************************************************************
\file DeferredLighting.frag.glsl
\author Yimo Kong (yimo.kong@digipen.edu)
\par Course: CSD2151
\par Assignment: 11 (Ogres)
\date 03/21/2026 (MM/DD/YYYY)
\brief
    Fullscreen deferred-lighting shader for Assignment 11. It samples the
    stored G-buffer textures, reads the Ogre diffuse texture and normal map,
    reconstructs the tangent-space normal, and evaluates a Blinn-Phong lighting
    model to produce an HDR lighting result for the final display pass.
*******************************************************************************/
R"(
    #version 420 core

    struct Material
    {
        vec3 Ka;
        vec3 Kd;
        vec3 Ks;
        float shininess;
    };

    layout(binding = 0) uniform sampler2D GPositionTexture;
    layout(binding = 1) uniform sampler2D GNormalTexture;
    layout(binding = 2) uniform sampler2D GTexCoordTexture;
    layout(binding = 3) uniform sampler2D GLightDirectionTexture;
    layout(binding = 4) uniform sampler2D GViewDirectionTexture;
    layout(binding = 5) uniform sampler2D ColorTexture;
    layout(binding = 6) uniform sampler2D NormalMapTexture;

    uniform Material material;

    layout(location = 0) out vec4 FragColor;

    vec3 blinnPhong(vec3 color, vec3 normal, vec3 lightDir, vec3 viewDir)
    {
        vec3 ambient = material.Ka * color;

        float lDotN = max(dot(lightDir, normal), 0.0);
        vec3 diffuse = material.Kd * color * lDotN;

        vec3 specular = vec3(0.0);
        if (lDotN > 0.0)
        {
            vec3 halfway = normalize(lightDir + viewDir);
            float specAmount = pow(max(dot(halfway, normal), 0.0), material.shininess);
            specular = material.Ks * specAmount;
        }

        return ambient + diffuse + specular;
    }

    void main()
    {
        ivec2 fragCoord = ivec2(gl_FragCoord.xy);
        vec3 geometricNormal = texelFetch(GNormalTexture, fragCoord, 0).xyz;

        if (length(geometricNormal) < 0.0001)
        {
            FragColor = vec4(0.0);
            return;
        }

        vec2 uv = texelFetch(GTexCoordTexture, fragCoord, 0).xy;
        vec3 tangentLightDirection = normalize(texelFetch(GLightDirectionTexture, fragCoord, 0).xyz);
        vec3 tangentViewDirection = normalize(texelFetch(GViewDirectionTexture, fragCoord, 0).xyz);

        vec3 tangentNormal = texture(NormalMapTexture, uv).xyz;
        tangentNormal.xy = 2.0 * tangentNormal.xy - 1.0;
        tangentNormal = normalize(tangentNormal);

        vec3 albedo = texture(ColorTexture, uv).rgb;
        vec3 hdrColor = blinnPhong(albedo, tangentNormal, tangentLightDirection, tangentViewDirection);

        FragColor = vec4(max(hdrColor, vec3(0.0)), 1.0);
    }
)"
