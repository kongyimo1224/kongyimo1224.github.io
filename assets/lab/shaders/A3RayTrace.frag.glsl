/*!*****************************************************************************
\file main.cpp
\author Vadim Surov (vsurov@digipen.edu)
\co-author Yimo Kong (yimo.kong@digipen.edu)
\par Course: CSD2151
\par Assignment: 3 (Tabs)
\date 01/24/2026
\brief 3-tab fragment shader with tab indicator dots and mouse highlight.
*******************************************************************************/

R"(
#version 330 core

uniform vec2  iResolution;
uniform float iTime;
uniform int   ActiveTab;
uniform vec2  iMouse;

// 1 = child demo window (ray tracing), 0 = main window (tabs + dots)
uniform int   IsDemoWindow;

layout(location=0) out vec4 FragColor;

//------------------------------------------------------------
// Helpers used by the tab shader
//------------------------------------------------------------
float circle(vec2 uv, vec2 center, float radius)
{
    float dist = distance(uv, center);
    return 1.0 - smoothstep(radius - 0.002, radius + 0.002, dist);
}

float getCheckerboardMask(vec2 uv, float size)
{
    uv = uv * size;
    return mod(floor(uv.x) + floor(uv.y), 2.0);
}

float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

//------------------------------------------------------------
// Ray tracing helpers (closest-hit spheres)
//------------------------------------------------------------
float intersectSphere(vec3 ro, vec3 rd, vec3 c, float r)
{
    vec3 oc = ro - c;
    float b  = dot(oc, rd);
    float cc = dot(oc, oc) - r * r;
    float h  = b * b - cc;
    if (h < 0.0) return -1.0;

    float s  = sqrt(h);
    float t0 = -b - s;
    float t1 = -b + s;

    if (t0 > 0.0) return t0;
    if (t1 > 0.0) return t1;
    return -1.0;
}

vec3 lambert(vec3 albedo, vec3 N, vec3 pos, vec3 lightPos, vec3 lightColor)
{
    vec3 L = normalize(lightPos - pos);
    float diff = max(dot(N, L), 0.0);
    vec3 ambient = vec3(0.10);
    return albedo * (ambient + diff * lightColor);
}

//------------------------------------------------------------
// Child-window Ray Tracing render (Earth, Sun, Moon)
//------------------------------------------------------------
vec4 renderRayTrace(vec2 fragCoord)
{
    // Screen plane coords with correct aspect
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // Simple fixed camera
    vec3 ro = vec3(0.0, 0.0, -3.2);
    vec3 rd = normalize(vec3(p, 1.4));

    // Scene objects
    vec3 earthC = vec3(0.0, 0.0, 0.0);
    float earthR = 0.70;

    // Time-based orbits (frame-rate independent)
    float sunAngle  = iTime * 0.55;
    float moonAngle = iTime * 1.15;

    float sunOrbitR  = 1.85;
    float moonOrbitR = 1.10;

    vec3 sunC  = vec3(cos(sunAngle)  * sunOrbitR,  0.0, sin(sunAngle)  * sunOrbitR);
    vec3 moonC = vec3(cos(moonAngle) * moonOrbitR, 0.0, sin(moonAngle) * moonOrbitR);

    float sunR  = 0.25;
    float moonR = 0.22;

    // Intersections
    float tEarth = intersectSphere(ro, rd, earthC, earthR);
    float tSun   = intersectSphere(ro, rd, sunC,   sunR);
    float tMoon  = intersectSphere(ro, rd, moonC,  moonR);

    float t = -1.0;
    int hitId = -1; // 0=earth,1=sun,2=moon

    if (tEarth > 0.0) { t = tEarth; hitId = 0; }
    if (tSun   > 0.0 && (t < 0.0 || tSun  < t)) { t = tSun;  hitId = 1; }
    if (tMoon  > 0.0 && (t < 0.0 || tMoon < t)) { t = tMoon; hitId = 2; }

    // Background (space + sparse stars)
    if (hitId == -1)
    {
        float n = hash21(floor(fragCoord / 3.0));
        float star = step(0.9985, n) * 0.9;
        return vec4(vec3(star), 1.0);
    }

    vec3 pos = ro + rd * t;

    // Sun is the light source
    vec3 lightPos   = sunC;
    vec3 lightColor = vec3(1.0, 0.95, 0.85);

    if (hitId == 1)
    {
        // SUN emissive, with slight rim to show center/shape
        vec3 N = normalize(pos - sunC);
        float rim = pow(1.0 - max(dot(N, -rd), 0.0), 2.0);
        vec3 sunCol = vec3(1.0, 0.88, 0.25);
        vec3 col = clamp(sunCol + rim * vec3(0.15, 0.10, 0.05), 0.0, 1.0);
        return vec4(col, 1.0);
    }
    else if (hitId == 0)
    {
        // EARTH Lambert shading (no shadows)
        vec3 N = normalize(pos - earthC);

        float band = 0.5 + 0.5 * sin(8.0 * (pos.y + 0.15));
        vec3 ocean = vec3(0.12, 0.25, 0.85);
        vec3 land  = vec3(0.10, 0.55, 0.20);
        vec3 albedo = mix(ocean, land, smoothstep(0.55, 0.75, band));

        vec3 col = clamp(lambert(albedo, N, pos, lightPos, lightColor), 0.0, 1.0);
        return vec4(col, 1.0);
    }
    else
    {
        // MOON Lambert shading (no shadows)
        vec3 N = normalize(pos - moonC);

        float n = hash21(floor((pos.xy + pos.z) * 40.0));
        vec3 albedo = vec3(0.65) + (n - 0.5) * 0.08;

        vec3 col = clamp(lambert(albedo, N, pos, lightPos, lightColor), 0.0, 1.0);
        return vec4(col, 1.0);
    }
}

//------------------------------------------------------------
// Main
//------------------------------------------------------------
void main()
{
    // REAL child window renders ray tracing full-screen
    if (IsDemoWindow == 1)
    {
        FragColor = renderRayTrace(gl_FragCoord.xy);
        return;
    }

    // Main window: tabs + dots (same as your A2 style)
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec4 finalColor = vec4(0.0);

    if (ActiveTab == 0)
    {
        vec2 movingUV = uv + vec2(iTime * 0.1, iTime * 0.1);
        float mask = getCheckerboardMask(movingUV, 10.0);
        float gray = mask / 5.0;
        finalColor = vec4(vec3(gray), 1.0);
    }
    else if (ActiveTab == 1)
    {
        vec3 darkBluePulse =
            (0.2 + 0.4 * cos(iTime + uv.xyx + vec3(0.0, 2.0, 4.0))) * vec3(0.1, 0.4, 1.0);

        float distBL = distance(uv, vec2(0.0, 0.0));
        float distTR = distance(uv, vec2(1.0, 1.0));

        float maskBL = smoothstep(0.7, 0.0, distBL);
        float maskTR = smoothstep(0.7, 0.0, distTR);

        float combinedMask = maskBL + maskTR;
        finalColor = vec4(darkBluePulse * combinedMask, 1.0);
    }
    else
    {
        float mask = getCheckerboardMask(uv, 10.0);
        float gray = mask / 5.0;
        vec3 baseColor = vec3(gray);

        float distToMouse = distance(uv, iMouse);
        float highlightRadius = 0.05;

        if (distToMouse < highlightRadius)
        {
            float glowIntensity = 1.0 - (distToMouse / highlightRadius);
            baseColor += vec3(1.0) * glowIntensity;
        }

        finalColor = vec4(baseColor, 1.0);
    }

    // Tab indicator dots (main window only)
    vec2 dot1Pos = vec2(0.45, 0.05);
    vec2 dot2Pos = vec2(0.50, 0.05);
    vec2 dot3Pos = vec2(0.55, 0.05);
    float radius = 0.015;

    float d1 = circle(uv, dot1Pos, radius);
    vec3 c1 = (ActiveTab == 0) ? vec3(1.0) : vec3(0.5);
    finalColor.rgb = mix(finalColor.rgb, c1, d1);

    float d2 = circle(uv, dot2Pos, radius);
    vec3 c2 = (ActiveTab == 1) ? vec3(1.0) : vec3(0.5);
    finalColor.rgb = mix(finalColor.rgb, c2, d2);

    float d3 = circle(uv, dot3Pos, radius);
    vec3 c3 = (ActiveTab == 2) ? vec3(1.0) : vec3(0.5);
    finalColor.rgb = mix(finalColor.rgb, c3, d3);

    FragColor = finalColor;
}
)"
