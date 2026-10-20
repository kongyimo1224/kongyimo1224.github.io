#version 420

in vec2 TexCoord;

uniform float iTime;

layout(location = 0) out vec4 FragColor;

float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p)
{
    float sum = 0.0;
    float weight = 0.5;

    for (int i = 0; i < 4; ++i)
    {
        sum += weight * noise(p);
        p = p * 2.02 + vec2(13.1, 7.7);
        weight *= 0.5;
    }

    return sum;
}

void main()
{
    vec2 uv = TexCoord * 2.0 - 1.0;
    float radius = length(uv);

    if (radius >= 1.0)
    {
        FragColor = vec4(0.0);
        return;
    }

    float angle = atan(uv.y, uv.x);
    float distortion = fbm(uv * 4.5 + vec2(iTime * 0.14, -iTime * 0.11));
    float swirl = 0.5 + 0.5 * sin(13.0 * angle + 16.0 * radius - iTime * 4.0 + distortion * 6.0);
    float tunnel = 0.5 + 0.5 * sin(20.0 * radius - 9.0 * angle - iTime * 5.0 + distortion * 4.0);

    float mask = 1.0 - smoothstep(0.80, 1.0, radius);
    float ring = smoothstep(0.62, 0.90, radius) * mask;
    float inner = 1.0 - smoothstep(0.0, 0.72, radius);

    vec3 deepBlue = vec3(0.05, 0.28, 0.82);
    vec3 cyan = vec3(0.12, 0.86, 0.90);
    vec3 aqua = vec3(0.30, 0.95, 0.72);
    vec3 lime = vec3(0.80, 1.00, 0.25);
    vec3 yellowGreen = vec3(0.98, 1.00, 0.48);

    vec3 coreColor = mix(deepBlue, cyan, swirl);
    coreColor = mix(coreColor, aqua, tunnel * 0.55 + inner * 0.25);

    vec3 rimColor = mix(lime, yellowGreen, 0.5 + 0.5 * sin(iTime * 3.0 + angle * 5.0));
    vec3 color = coreColor * (0.55 + 0.75 * mask);
    color += rimColor * ring * 2.0;
    color += vec3(0.75, 1.0, 0.45) * pow(ring, 2.5) * 0.45;

    float alpha = mask * (0.60 + 0.40 * swirl);
    alpha = max(alpha, ring * 0.96);

    FragColor = vec4(color, alpha);
}
