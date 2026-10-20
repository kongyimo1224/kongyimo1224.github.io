R"(
#version 330 core

uniform vec2 iResolution;
uniform float iTime;
uniform int ActiveTab;
uniform vec2 iMouse;
uniform int SelectedCell;

layout(location=0) out vec4 FragColor;

float circle(vec2 uv, vec2 center, float radius)
{
    float dist = distance(uv, center);
    return 1.0 - smoothstep(radius - 0.002, radius + 0.002, dist);
}

float circlePixels(vec2 p, vec2 center, float radius)
{
    float dist = distance(p, center);
    return 1.0 - smoothstep(radius - 1.5, radius + 1.5, dist);
}

float checkerboard(vec2 uv, float size)
{
    vec2 scaled = floor(uv * size);
    return mod(scaled.x + scaled.y, 2.0);
}

float rectMask(vec2 uv, vec2 minCorner, vec2 maxCorner)
{
    vec2 lo = step(minCorner, uv);
    vec2 hi = step(uv, maxCorner);
    return lo.x * lo.y * hi.x * hi.y;
}

float rectOutline(vec2 uv, vec2 minCorner, vec2 maxCorner, float thickness)
{
    float outer = rectMask(uv, minCorner, maxCorner);
    float inner = rectMask(uv, minCorner + vec2(thickness), maxCorner - vec2(thickness));
    return max(0.0, outer - inner);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec2 p = gl_FragCoord.xy;
    vec3 color = vec3(0.0);

    if (ActiveTab == 0)
    {
        vec2 movingUV = uv + vec2(iTime * 0.10, iTime * 0.10);
        float mask = checkerboard(movingUV, 10.0);
        float gray = mask / 5.0;
        color = vec3(gray);
    }
    else if (ActiveTab == 1)
    {
        vec3 pulse = (0.2 + 0.4 * cos(iTime + uv.xyx + vec3(0.0, 2.0, 4.0))) * vec3(0.1, 0.4, 1.0);
        float distBL = distance(uv, vec2(0.0, 0.0));
        float distTR = distance(uv, vec2(1.0, 1.0));
        float maskBL = smoothstep(0.7, 0.0, distBL);
        float maskTR = smoothstep(0.7, 0.0, distTR);
        color = pulse * (maskBL + maskTR);
    }
    else
    {
        float mask = checkerboard(uv, 10.0);
        float gray = mask / 5.0;
        color = vec3(gray);

        float distToMouse = distance(uv, iMouse);
        float highlightRadius = 0.05;
        if (distToMouse < highlightRadius)
        {
            float glow = 1.0 - (distToMouse / highlightRadius);
            color += vec3(glow);
        }

        vec2 frameMin = vec2(0.06, 0.14);
        vec2 frameMax = vec2(0.94, 0.92);
        vec2 cellSize = (frameMax - frameMin) / 3.0;
        const float gap = 0.010;
        const float thickness = 0.004;

        for (int row = 0; row < 3; ++row)
        {
            for (int col = 0; col < 3; ++col)
            {
                int index = row * 3 + col;
                vec2 cellMin = frameMin + vec2(float(col), float(2 - row)) * cellSize + vec2(gap);
                vec2 cellMax = frameMin + vec2(float(col + 1), float(3 - row)) * cellSize - vec2(gap);
                float outline = rectOutline(uv, cellMin, cellMax, thickness);
                vec3 outlineColor = (index == SelectedCell) ? vec3(1.0) : vec3(0.45, 0.55, 0.75);
                color = mix(color, outlineColor, outline * (index == SelectedCell ? 0.90 : 0.35));
            }
        }
    }

    float radius = 12.0;
    float spacing = 28.0;
    vec2 dot1 = vec2(iResolution.x * 0.5 - spacing, 28.0);
    vec2 dot2 = vec2(iResolution.x * 0.5,           28.0);
    vec2 dot3 = vec2(iResolution.x * 0.5 + spacing, 28.0);

    float d1 = circlePixels(p, dot1, radius);
    float d2 = circlePixels(p, dot2, radius);
    float d3 = circlePixels(p, dot3, radius);

    color = mix(color, (ActiveTab == 0) ? vec3(1.0) : vec3(0.5), d1);
    color = mix(color, (ActiveTab == 1) ? vec3(1.0) : vec3(0.5), d2);
    color = mix(color, (ActiveTab == 2) ? vec3(1.0) : vec3(0.5), d3);

    FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
)"
