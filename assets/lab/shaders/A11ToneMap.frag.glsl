/*!*****************************************************************************
\file ToneMap.frag.glsl
\author Yimo Kong (yimo.kong@digipen.edu)
\par Course: CSD2151
\par Assignment: 11 (Ogres)
\date 03/21/2026 (MM/DD/YYYY)
\brief
    Final presentation shader for Assignment 11. It tone maps the HDR lighting
    texture to the default framebuffer and also provides the runtime debug views
    used to inspect stored UVs, tangent-space light/view directions, and the
    original Ogre color and normal-map textures.
*******************************************************************************/
R"(
    #version 420 core

    layout(binding = 2) uniform sampler2D GTexCoordTexture;
    layout(binding = 3) uniform sampler2D GLightDirectionTexture;
    layout(binding = 4) uniform sampler2D GViewDirectionTexture;
    layout(binding = 5) uniform sampler2D ColorTexture;
    layout(binding = 6) uniform sampler2D NormalMapTexture;
    layout(binding = 7) uniform sampler2D LightingTexture;

    uniform vec2 iResolution;
    uniform float Exposure;
    uniform int RenderMode;

    layout(location = 0) out vec4 FragColor;

    vec4 sampleRawTexturePreview(sampler2D tex, vec2 screenUv)
    {
        vec2 textureSizePx = vec2(textureSize(tex, 0));
        vec2 screenSizePx = vec2(textureSize(LightingTexture, 0));

        float textureAspect = textureSizePx.x / max(textureSizePx.y, 1.0);
        float screenAspect = screenSizePx.x / max(screenSizePx.y, 1.0);

        vec2 previewUv = screenUv;

        if (screenAspect > textureAspect)
        {
            float usedWidth = textureAspect / screenAspect;
            float minX = 0.5 - 0.5 * usedWidth;
            float maxX = 0.5 + 0.5 * usedWidth;
            if (screenUv.x < minX || screenUv.x > maxX)
                return vec4(0.0, 0.0, 0.0, 1.0);

            previewUv.x = (screenUv.x - minX) / usedWidth;
        }
        else
        {
            float usedHeight = screenAspect / textureAspect;
            float minY = 0.5 - 0.5 * usedHeight;
            float maxY = 0.5 + 0.5 * usedHeight;
            if (screenUv.y < minY || screenUv.y > maxY)
                return vec4(0.0, 0.0, 0.0, 1.0);

            previewUv.y = (screenUv.y - minY) / usedHeight;
        }

        return vec4(texture(tex, previewUv).rgb, 1.0);
    }

    void main()
    {
        vec2 screenUv = gl_FragCoord.xy / iResolution;

        if (RenderMode == 2)
        {
            vec3 lightDirection = normalize(texture(GLightDirectionTexture, screenUv).xyz);
            FragColor = vec4(lightDirection * 0.5 + 0.5, 1.0);
            return;
        }

        if (RenderMode == 3)
        {
            vec3 viewDirection = normalize(texture(GViewDirectionTexture, screenUv).xyz);
            FragColor = vec4(viewDirection * 0.5 + 0.5, 1.0);
            return;
        }

        if (RenderMode == 4)
        {
            vec2 uv = texture(GTexCoordTexture, screenUv).xy;
            FragColor = vec4(uv, 0.0, 1.0);
            return;
        }

        if (RenderMode == 5)
        {
            FragColor = sampleRawTexturePreview(ColorTexture, screenUv);
            return;
        }

        if (RenderMode == 6)
        {
            FragColor = sampleRawTexturePreview(NormalMapTexture, screenUv);
            return;
        }

        vec3 hdrColor = texture(LightingTexture, screenUv).rgb;
        vec3 mapped = vec3(1.0) - exp(-hdrColor * Exposure);
        mapped = pow(max(mapped, vec3(0.0)), vec3(1.0 / 2.2));

        FragColor = vec4(mapped, 1.0);
    }
)"
