/*!*****************************************************************************
\file main.cpp
\author Vadim Surov (vsurov@digipen.edu)
\co-author Yimo Kong (yimo.kong@digipen.edu)
\par Course: CSD2151
\par Assignment: 1 (Tabs)
\date 01/04/2026
\brief 3-tab fragment shader with tab indicator dots and mouse highlight.
*******************************************************************************/

R"(
#version 330 core

uniform vec2 iResolution;
uniform float iTime;
uniform int ActiveTab;
uniform vec2 iMouse;

layout(location=0) out vec4 FragColor;

/*
 * circle - Draws a smooth circle at specified position
 * @param uv: current fragment coordinates
 * @param center: center position of circle
 * @param radius: radius of circle
 * @return: circle mask value (0.0 to 1.0)
 */
float circle(vec2 uv, vec2 center, float radius) {
    float dist = distance(uv, center);
    return 1.0 - smoothstep(radius - 0.002, radius + 0.002, dist);
}

float circlePixels(vec2 p, vec2 center, float radius) {
    float dist = distance(p, center);
    return 1.0 - smoothstep(radius - 1.5, radius + 1.5, dist);
}

/*
 * getCheckerboardMask - Creates a checkerboard pattern
 */
float getCheckerboardMask(vec2 uv, float size) {
    uv = uv * size;
    return mod(floor(uv.x) + floor(uv.y), 2.0f); 
}

void main() {
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec2 p = gl_FragCoord.xy;
    vec4 finalColor = vec4(0.0);

    // ====================================================================
    // TAB CONTENT RENDERING
    // ====================================================================
    
    if(ActiveTab == 0) {
        // TAB 0: animated checkerboard pattern (moves diagonally)
        vec2 movingUV = uv + vec2(iTime * 0.1f, iTime * 0.1f); 
        float mask = getCheckerboardMask(movingUV, 10.0f);
        float gray = mask / 5.0f; 
        finalColor = vec4(gray, gray, gray, 1.0f);
    }
    else if(ActiveTab == 1) {
        // TAB 1: blue gradient effect in diagonal corners
        
        vec3 darkBluePulse = (0.2 + 0.4 * cos(iTime + uv.xyx + vec3(0, 2, 4))) * vec3(0.1, 0.4, 1.0);
        
        // calculate distance from corners
        float distBL = distance(uv, vec2(0.0, 0.0));
        float distTR = distance(uv, vec2(1.0, 1.0));
        
        float maskBL = smoothstep(0.7, 0.0, distBL);
        float maskTR = smoothstep(0.7, 0.0, distTR);
        
        float combinedMask = maskBL + maskTR;
        
        finalColor = vec4(darkBluePulse * combinedMask, 1.0f);
    }
    else {
        // TAB 2: static checkerboard with interactive mouse highlight
        float mask = getCheckerboardMask(uv, 10.0f);
        float gray = mask / 5.0f; 
        vec3 baseColor = vec3(gray);

        // apply mouse highlight effect
        float distToMouse = distance(uv, iMouse);
        float highlightRadius = 0.05f; 

        if(distToMouse < highlightRadius) {
            float glowIntensity = 1.0 - (distToMouse / highlightRadius);
            vec3 highlightColor = vec3(1.0, 1.0, 1.0); 
            baseColor += highlightColor * glowIntensity;
        }

        finalColor = vec4(baseColor, 1.0f);
    }

    // ====================================================================
    // TAB INDICATOR DOTS
    // ====================================================================
    
    float radius = 12.0;
    float spacing = 28.0;
    vec2 dot1Pos = vec2(iResolution.x * 0.5 - spacing, 28.0);
    vec2 dot2Pos = vec2(iResolution.x * 0.5,           28.0);
    vec2 dot3Pos = vec2(iResolution.x * 0.5 + spacing, 28.0);

    // render dot 1
    float d1 = circlePixels(p, dot1Pos, radius);
    vec3 c1 = (ActiveTab == 0) ? vec3(1.0) : vec3(0.5);
    finalColor.rgb = mix(finalColor.rgb, c1, d1);

    // render dot 2
    float d2 = circlePixels(p, dot2Pos, radius);
    vec3 c2 = (ActiveTab == 1) ? vec3(1.0) : vec3(0.5);
    finalColor.rgb = mix(finalColor.rgb, c2, d2);

    // render dot 3
    float d3 = circlePixels(p, dot3Pos, radius);
    vec3 c3 = (ActiveTab == 2) ? vec3(1.0) : vec3(0.5);
    finalColor.rgb = mix(finalColor.rgb, c3, d3);

    FragColor = finalColor;
}
)"
