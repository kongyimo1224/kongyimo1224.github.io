/*!*****************************************************************************
\file main.cpp
\author Vadim Surov (vsurov@digipen.edu)
\co-author Yimo Kong (yimo.kong@digipen.edu)
\par Course: CSD2151
\par Assignment: 2 (Tabs)
\date 01/17/2026
\brief 3-tab fragment shader with tab indicator dots and mouse highlight.
*******************************************************************************/

R"(
#version 330 core

uniform vec2 iResolution;
uniform float iTime;
uniform int ActiveTab;
uniform vec2 iMouse;

// If 1: render the RayCasting demo full-screen (no dots, no other tabs)
uniform int IsDemoWindow;

// RayCasting camera
uniform vec2 playerPos;
uniform vec2 playerDir;
uniform vec2 playerPlane;

layout(location=0) out vec4 FragColor;

//------------------------------------------------------------
// Helpers used by the original tab shader
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

//------------------------------------------------------------
// RayCasting map + DDA
//------------------------------------------------------------
const int MAP_W = 16;
const int MAP_H = 16;

const int MAP_DATA[256] = int[256](
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,2,2,2,0,0,3,3,3,0,0,0,1,
    1,0,0,0,2,0,0,0,0,0,0,3,0,0,0,1,
    1,0,0,0,2,0,0,0,0,0,0,3,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,5,0,0,0,0,0,0,4,0,0,0,1,
    1,0,0,0,5,0,0,0,0,0,0,4,0,0,0,1,
    1,0,0,0,5,5,5,0,0,4,4,4,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
);

int mapAt(int x, int y)
{
    if (x < 0 || x >= MAP_W || y < 0 || y >= MAP_H) return 1;
    return MAP_DATA[y * MAP_W + x];
}

//------------------------------------------------------------
// Procedural wall textures by ID
//------------------------------------------------------------
vec3 wallTextureById(int id, float u, float v)
{
    vec2 uv = vec2(u, v);
    uv = clamp(uv, 0.0, 1.0);

    if (id == 1)
    {
        // Brick-like: offset rows + mortar
        vec2 p = uv * vec2(7.0, 4.0);
        float row = floor(p.y);
        if (mod(row, 2.0) > 0.5) p.x += 0.5;
        vec2 f = fract(p);

        float mortar = 0.0;
        mortar += step(f.x, 0.08);
        mortar += step(f.y, 0.08);
        mortar += step(0.92, f.x);
        mortar += step(0.92, f.y);
        mortar = clamp(mortar, 0.0, 1.0);

        vec3 brick = vec3(0.62, 0.22, 0.18);
        vec3 grout = vec3(0.10, 0.10, 0.10);
        return mix(brick, grout, mortar);
    }
    else if (id == 2)
    {
        // Vertical stripes
        float s = step(0.5, fract(uv.x * 12.0));
        vec3 a = vec3(0.10, 0.45, 0.20);
        vec3 b = vec3(0.05, 0.20, 0.10);
        return mix(a, b, s);
    }
    else if (id == 3)
    {
        // Checker tiles
        vec2 p = floor(uv * 8.0);
        float m = mod(p.x + p.y, 2.0);
        vec3 a = vec3(0.55, 0.55, 0.65);
        vec3 b = vec3(0.25, 0.25, 0.30);
        return mix(a, b, m);
    }
    else if (id == 4)
    {
        // Diagonal bands
        float bands = step(0.5, fract((uv.x + uv.y) * 10.0));
        vec3 a = vec3(0.70, 0.55, 0.15);
        vec3 b = vec3(0.25, 0.18, 0.05);
        return mix(a, b, bands);
    }
    else if (id == 5)
    {
        // Dots
        vec2 p = fract(uv * 7.0) - 0.5;
        float d = length(p);
        float dot = 1.0 - smoothstep(0.18, 0.22, d);
        vec3 base = vec3(0.25, 0.20, 0.55);
        vec3 ink  = vec3(0.85, 0.85, 0.95);
        return mix(base, ink, dot);
    }

    return vec3(0.75, 0.75, 0.75);
}

//------------------------------------------------------------
// Ray casting (DDA)
//------------------------------------------------------------
void castRay(float screenX, out float dist, out int id, out float texU, out int side)
{
    // Column in [-1,1]
    float cameraX = (2.0 * screenX / iResolution.x) - 1.0;

    vec2 rayDir = normalize(playerDir + playerPlane * cameraX);

    ivec2 mapPos = ivec2(int(floor(playerPos.x)), int(floor(playerPos.y)));

    // Robust delta distances (avoid div-by-zero)
    float dx = max(abs(rayDir.x), 1e-6);
    float dy = max(abs(rayDir.y), 1e-6);
    vec2 deltaDist = vec2(1.0 / dx, 1.0 / dy);

    ivec2 stepDir;
    vec2 sideDist;

    if (rayDir.x < 0.0)
    {
        stepDir.x = -1;
        sideDist.x = (playerPos.x - float(mapPos.x)) * deltaDist.x;
    }
    else
    {
        stepDir.x = 1;
        sideDist.x = (float(mapPos.x) + 1.0 - playerPos.x) * deltaDist.x;
    }

    if (rayDir.y < 0.0)
    {
        stepDir.y = -1;
        sideDist.y = (playerPos.y - float(mapPos.y)) * deltaDist.y;
    }
    else
    {
        stepDir.y = 1;
        sideDist.y = (float(mapPos.y) + 1.0 - playerPos.y) * deltaDist.y;
    }

    id = 0;
    side = 0;

    // DDA
    for (int i = 0; i < 128; ++i)
    {
        if (sideDist.x < sideDist.y)
        {
            sideDist.x += deltaDist.x;
            mapPos.x += stepDir.x;
            side = 0;
        }
        else
        {
            sideDist.y += deltaDist.y;
            mapPos.y += stepDir.y;
            side = 1;
        }

        id = mapAt(mapPos.x, mapPos.y);
        if (id != 0) break;
    }

    // Perpendicular wall distance (fish-eye fix)
    if (side == 0)
        dist = (float(mapPos.x) - playerPos.x + (1.0 - float(stepDir.x)) * 0.5) / rayDir.x;
    else
        dist = (float(mapPos.y) - playerPos.y + (1.0 - float(stepDir.y)) * 0.5) / rayDir.y;

    dist = max(abs(dist), 0.001);

    // Wall hit position to get U in [0,1]
    float wallX;
    if (side == 0) wallX = playerPos.y + dist * rayDir.y;
    else           wallX = playerPos.x + dist * rayDir.x;
    wallX -= floor(wallX);
    texU = wallX;
}

//------------------------------------------------------------
// Render raycast scene
//------------------------------------------------------------
vec4 renderRaycast(vec2 fragCoord)
{
    float x = fragCoord.x;
    float y = fragCoord.y;

    float dist;
    int id;
    float u;
    int side;
    castRay(x, dist, id, u, side);

    // Wall height proportional to distance, symmetric about center
    float lineHeight = iResolution.y / dist;
    float drawStart = -lineHeight * 0.5 + iResolution.y * 0.5;
    float drawEnd   =  lineHeight * 0.5 + iResolution.y * 0.5;

    drawStart = clamp(drawStart, 0.0, iResolution.y);
    drawEnd   = clamp(drawEnd,   0.0, iResolution.y);

    // Distance-based brightness (walls darker with distance)
    float brightness = 1.0 / (1.0 + dist * 0.35);
    if (side == 1) brightness *= 0.78;

    // Ceiling + optional mild shading
    vec3 ceilingCol = vec3(0.90, 0.90, 0.93);

    // Floor base
    vec3 floorColBase = vec3(0.20, 0.20, 0.22);

    if (y > drawEnd)
    {
        // Ceiling
        return vec4(ceilingCol, 1.0);
    }
    else if (y >= drawStart)
    {
        // Wall
        float v = (y - drawStart) / max(lineHeight, 1.0);
        vec3 wallCol = wallTextureById(id, u, v) * brightness;
        return vec4(wallCol, 1.0);
    }
    else
    {
        // Floor + faded reflection of walls
        float distFromWall = (drawStart - y);

        float refl = clamp(1.0 - (distFromWall / (iResolution.y * 0.55)), 0.0, 1.0);
        refl = refl * refl * 0.38;

        // Mirror y into wall space to sample reflected wall color
        float vRef = distFromWall / max(lineHeight, 1.0);
        vec3 reflCol = wallTextureById(id, u, vRef) * brightness;

        float floorShade = clamp(1.0 - distFromWall / (iResolution.y * 0.9), 0.0, 1.0);
        vec3 floorCol = floorColBase * (0.65 + 0.35 * floorShade);

        vec3 finalFloor = mix(floorCol, reflCol, refl);
        return vec4(finalFloor, 1.0);
    }
}

//------------------------------------------------------------
// Main
//------------------------------------------------------------
void main()
{
    // Child demo window: render RayCasting only.
    if (IsDemoWindow == 1)
    {
        FragColor = renderRaycast(gl_FragCoord.xy);
        return;
    }

    // Main window tabs
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
