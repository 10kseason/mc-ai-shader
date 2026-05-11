#version 120

/* DRAWBUFFERS:5 */
/*
const int colortex5Format = RGBA16;
*/

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform int worldTime;
uniform int isEyeInWater;

varying vec2 texcoord;

#define BLOOM_THRESHOLD 0.78 // [0.62 0.70 0.78 0.86 0.94]
#define BLOOM_RADIUS 2.80 // [1.50 2.20 2.80 3.50 3.80 4.40 5.60]
#define BLOOM_SOFT_KNEE 0.26 // [0.12 0.20 0.26 0.34 0.46]
#define BLOOM_NIGHT_DAMPING 0.38 // [0.00 0.16 0.28 0.38 0.52 0.68]
#define BLOOM_INTERIOR_DAMPING 0.42 // [0.00 0.18 0.30 0.42 0.58 0.76]
#define BLOOM_ADAPTATION_STRENGTH 0.58 // [0.00 0.28 0.44 0.58 0.72 0.86]
#define BLOOM_SOURCE_CONTRAST 0.62 // [0.20 0.38 0.50 0.62 0.78 0.94]
#define BLOOM_SKY_GLARE 0.16 // [0.00 0.08 0.16 0.26 0.38 0.52]
#define RAIN_BLOOM_DAMPING 0.32 // [0.00 0.12 0.22 0.32 0.44 0.58]
#define SATURATION_BLOOM_STRENGTH 0.72 // [0.00 0.25 0.48 0.72 0.95 1.20]
#define NEON_COLOR_BIAS 0.72 // [0.00 0.25 0.48 0.72 0.95 1.20]

float luma(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float max3(vec3 color) {
    return max(max(color.r, color.g), color.b);
}

float min3(vec3 color) {
    return min(min(color.r, color.g), color.b);
}

float colorSaturation(vec3 color) {
    float mx = max3(color);
    float mn = min3(color);
    return clamp((mx - mn) / max(mx, 0.001), 0.0, 1.0);
}

float getTime01() {
    return mod(float(worldTime), 24000.0) / 24000.0;
}

float getSunElevationCurve() {
    return sin(getTime01() * 6.2831853);
}

float getNightMask() {
    return 1.0 - smoothstep(-0.18, 0.08, getSunElevationCurve());
}

float getRainMask() {
    return clamp(max(rainStrength, wetness), 0.0, 1.0);
}

float getNeonColorMask(vec3 color) {
    float saturation = colorSaturation(color);
    float intensity = max3(color);
    float redNeon = smoothstep(0.04, 0.30, color.r - max(color.g, color.b));
    float blueNeon = smoothstep(0.04, 0.26, color.b - max(color.r, color.g));
    float greenNeon = smoothstep(0.04, 0.24, color.g - max(color.r, color.b));
    float cyanNeon = smoothstep(0.72, 1.05, color.g / max(color.b, 0.001)) *
                     smoothstep(0.72, 1.05, color.b / max(color.g, 0.001)) *
                     smoothstep(0.05, 0.32, min(color.g, color.b) - color.r);
    float purpleNeon = smoothstep(0.62, 1.10, color.r / max(color.b, 0.001)) *
                       smoothstep(0.62, 1.10, color.b / max(color.r, 0.001)) *
                       smoothstep(0.05, 0.28, min(color.r, color.b) - color.g);
    float chroma = smoothstep(0.18, 0.58, saturation) * smoothstep(0.10, 0.85, intensity);
    return clamp(max(max(max(redNeon, blueNeon), max(greenNeon, cyanNeon)), purpleNeon) * chroma, 0.0, 1.0);
}

vec3 saturateColor(vec3 color, float amount) {
    float brightness = luma(color);
    return mix(vec3(brightness), color, amount);
}

float sampleSceneLuma(vec2 uv) {
    return luma(texture2D(colortex0, clamp(uv, vec2(0.001), vec2(0.999))).rgb);
}

float getAdaptedSceneLuma(vec2 uv) {
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    float nearLuma = sampleSceneLuma(uv) * 0.34;
    nearLuma += sampleSceneLuma(uv + vec2( px.x, 0.0) * 6.0) * 0.11;
    nearLuma += sampleSceneLuma(uv + vec2(-px.x, 0.0) * 6.0) * 0.11;
    nearLuma += sampleSceneLuma(uv + vec2(0.0,  px.y) * 6.0) * 0.11;
    nearLuma += sampleSceneLuma(uv + vec2(0.0, -px.y) * 6.0) * 0.11;
    nearLuma += sampleSceneLuma(uv + vec2( px.x,  px.y) * 12.0) * 0.055;
    nearLuma += sampleSceneLuma(uv + vec2(-px.x,  px.y) * 12.0) * 0.055;
    nearLuma += sampleSceneLuma(uv + vec2( px.x, -px.y) * 12.0) * 0.055;
    nearLuma += sampleSceneLuma(uv + vec2(-px.x, -px.y) * 12.0) * 0.055;

    float fieldLuma = sampleSceneLuma(uv) * 0.22;
    fieldLuma += sampleSceneLuma(uv + vec2( px.x, 0.0) * 32.0) * 0.13;
    fieldLuma += sampleSceneLuma(uv + vec2(-px.x, 0.0) * 32.0) * 0.13;
    fieldLuma += sampleSceneLuma(uv + vec2(0.0,  px.y) * 24.0) * 0.13;
    fieldLuma += sampleSceneLuma(uv + vec2(0.0, -px.y) * 24.0) * 0.13;
    fieldLuma += sampleSceneLuma(uv + vec2( px.x,  px.y) * 46.0) * 0.065;
    fieldLuma += sampleSceneLuma(uv + vec2(-px.x,  px.y) * 46.0) * 0.065;
    fieldLuma += sampleSceneLuma(uv + vec2( px.x, -px.y) * 46.0) * 0.065;
    fieldLuma += sampleSceneLuma(uv + vec2(-px.x, -px.y) * 46.0) * 0.065;

    return mix(nearLuma, fieldLuma, BLOOM_ADAPTATION_STRENGTH);
}

vec3 extractBloomAt(vec2 uv) {
    uv = clamp(uv, vec2(0.001), vec2(0.999));

    vec3 color = texture2D(colortex0, uv).rgb;
    float depth = texture2D(depthtex0, uv).r;
    vec4 material = texture2D(colortex1, uv);

    float brightness = luma(color);
    float intensity = max3(color);
    float saturation = colorSaturation(color);
    float neon = getNeonColorMask(color);
    float emission = clamp(material.b, 0.0, 1.0);
    float waterMask = step(0.5, material.r);
    float sceneMask = 1.0 - step(0.999999, depth);
    float skyMask = step(0.999999, depth);
    float rain = getRainMask();
    float night = getNightMask();
    float adaptedLuma = getAdaptedSceneLuma(uv);
    float lumaContrast = max(brightness - adaptedLuma, 0.0) / max(adaptedLuma + 0.08, 0.08);
    float sourceContrast = smoothstep(0.12, 1.18, lumaContrast * BLOOM_SOURCE_CONTRAST + emission * 0.92 + neon * 0.08);
    float broadBrightSurface = smoothstep(0.52, 1.02, adaptedLuma) * (1.0 - sourceContrast * 0.70) * (1.0 - emission * 0.60);
    float dimSurface = (1.0 - smoothstep(0.18, 0.58, brightness)) * sceneMask;
    float interiorGuard = dimSurface * (1.0 - emission * 0.82) * BLOOM_INTERIOR_DAMPING;

    float threshold = BLOOM_THRESHOLD;
    threshold += adaptedLuma * BLOOM_ADAPTATION_STRENGTH * 0.22;
    threshold += broadBrightSurface * 0.18;
    threshold += rain * RAIN_BLOOM_DAMPING * 0.22;
    threshold += night * BLOOM_NIGHT_DAMPING * 0.16;
    threshold += interiorGuard * 0.18;
    threshold += waterMask * 0.10;
    threshold -= sourceContrast * 0.10;
    threshold -= emission * 0.20;
    threshold = clamp(threshold, 0.38, 1.10);

    float colorEnergy = saturation * intensity;
    float overAdapted = max(brightness - adaptedLuma * 0.68, 0.0);
    float bloomSignal = brightness * (0.50 + sourceContrast * 0.44);
    bloomSignal += overAdapted * (0.48 + lumaContrast * 0.20);
    bloomSignal += neon * NEON_COLOR_BIAS * 0.05;
    bloomSignal += colorEnergy * SATURATION_BLOOM_STRENGTH * 0.025;
    bloomSignal += emission * (0.18 + brightness * 0.16);
    bloomSignal = mix(bloomSignal, bloomSignal * (0.42 + BLOOM_SKY_GLARE * 0.76), skyMask * (1.0 - sourceContrast * 0.55));

    float mask = smoothstep(threshold, threshold + BLOOM_SOFT_KNEE, bloomSignal);
    float weatherGuard = 1.0 - rain * RAIN_BLOOM_DAMPING * (0.42 + night * 0.20);
    float nightGuard = 1.0 - night * BLOOM_NIGHT_DAMPING * 0.26 * (1.0 - emission * 0.72);
    float interiorDamp = 1.0 - interiorGuard * 0.38;
    float broadSurfaceDamp = 1.0 - broadBrightSurface * (0.34 + BLOOM_INTERIOR_DAMPING * 0.18);
    float skyDamp = mix(1.0, 0.50 + BLOOM_SKY_GLARE * 0.58, skyMask * (1.0 - sourceContrast * 0.72));
    mask *= clamp(weatherGuard * nightGuard * interiorDamp * broadSurfaceDamp * skyDamp, 0.08, 1.0);

    vec3 glareColor = mix(vec3(brightness), color, 0.68 + emission * 0.18 + saturation * 0.10);
    glareColor = mix(glareColor, saturateColor(color, 1.08), neon * 0.22);
    vec3 bloom = glareColor * mask * (0.76 + sourceContrast * 0.24);

    if (isEyeInWater != 0) {
        bloom *= 0.55;
    }

    return bloom;
}

void main() {
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight) * BLOOM_RADIUS;
    vec3 bloom = extractBloomAt(texcoord) * 0.24;

    bloom += extractBloomAt(texcoord + vec2( px.x, 0.0)) * 0.12;
    bloom += extractBloomAt(texcoord + vec2(-px.x, 0.0)) * 0.12;
    bloom += extractBloomAt(texcoord + vec2(0.0,  px.y)) * 0.12;
    bloom += extractBloomAt(texcoord + vec2(0.0, -px.y)) * 0.12;

    bloom += extractBloomAt(texcoord + vec2( px.x,  px.y) * 1.35) * 0.07;
    bloom += extractBloomAt(texcoord + vec2(-px.x,  px.y) * 1.35) * 0.07;
    bloom += extractBloomAt(texcoord + vec2( px.x, -px.y) * 1.35) * 0.07;
    bloom += extractBloomAt(texcoord + vec2(-px.x, -px.y) * 1.35) * 0.07;

    gl_FragData[0] = vec4(clamp(bloom, 0.0, 1.0), 1.0);
}
