#version 120

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex5;
uniform sampler2D colortex8;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform int worldTime;
uniform int isEyeInWater;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

varying vec2 texcoord;

#define COLOR_STYLE 0 // [0 1 2]
#define SATURATION 1.00 // [0.70 0.80 0.90 1.00 1.04 1.08 1.15 1.25]
#define CONTRAST 1.06 // [0.80 0.90 1.00 1.06 1.10 1.20]
#define HIGHLIGHT_LIFT 0.00 // [0.00 0.04 0.08 0.12 0.16 0.22]
#define VIGNETTE_STRENGTH 0.18 // [0.00 0.08 0.12 0.18 0.24 0.32]
#define UNDERWATER_TINT 0.32 // [0.00 0.15 0.25 0.32 0.45 0.60]
#define UNDERWATER_HAZE_STRENGTH 0.58 // [0.00 0.25 0.40 0.58 0.72 0.86]
#define UNDERWATER_BLUR_STRENGTH 0.60 // [0.00 0.25 0.45 0.60 0.86 1.10]
#define UNDERWATER_DISTORTION 0.32 // [0.00 0.16 0.25 0.32 0.50 0.70]
#define PASTEL_STRENGTH 0.00 // [0.00 0.22 0.42 0.48 0.58 0.74 0.90]
#define PASTEL_WASH 0.00 // [0.00 0.08 0.10 0.16 0.24 0.34]
#define SOFT_EDGE_STRENGTH 0.14 // [0.00 0.08 0.14 0.16 0.26 0.38]
#define SOFT_EDGE_THRESHOLD 0.13 // [0.06 0.09 0.13 0.18 0.24]
#define BLOOM_STRENGTH 0.28 // [0.00 0.12 0.20 0.28 0.38 0.52]
#define BLOOM_THRESHOLD 0.78 // [0.62 0.70 0.78 0.86 0.94]
#define BLOOM_RADIUS 2.80 // [1.50 2.20 2.80 3.50 3.80 4.40 5.60]
#define BLOOM_SOFT_KNEE 0.26 // [0.12 0.20 0.26 0.34 0.46]
#define BLOOM_NIGHT_DAMPING 0.38 // [0.00 0.16 0.28 0.38 0.52 0.68]
#define BLOOM_INTERIOR_DAMPING 0.42 // [0.00 0.18 0.30 0.42 0.58 0.76]
#define BLOOM_ADAPTATION_STRENGTH 0.58 // [0.00 0.28 0.44 0.58 0.72 0.86]
#define BLOOM_SOURCE_CONTRAST 0.62 // [0.20 0.38 0.50 0.62 0.78 0.94]
#define BLOOM_SKY_GLARE 0.16 // [0.00 0.08 0.16 0.26 0.38 0.52]
#define BLOOM_VEIL_STRENGTH 0.10 // [0.00 0.05 0.10 0.16 0.24 0.34]
#define BLOOM_GI_STRENGTH 0.12 // [0.00 0.06 0.12 0.18 0.26 0.36]
#define BLOOM_GI_RADIUS 18.0 // [8.0 12.0 18.0 26.0 36.0]
#define BLOOM_GI_SURFACE_CATCH 0.46 // [0.00 0.20 0.34 0.46 0.62 0.82]
#define BLOOM_GI_COLOR_PRESERVE 0.72 // [0.30 0.50 0.72 0.88 1.00]

#define VEGETATION_BOOST 0.45 // [0.00 0.25 0.45 0.70 0.90 1.15]
#define CYBER_BLOOM_STRENGTH 0.10 // [0.00 0.10 0.18 0.30 0.46 0.64]
#define SATURATION_BLOOM_STRENGTH 0.72 // [0.00 0.25 0.48 0.72 0.95 1.20]
#define AMBIENT_GLOW_STRENGTH 0.22 // [0.00 0.12 0.22 0.34 0.50 0.68]
#define GLASS_REFLECTION_STRENGTH 0.36 // [0.00 0.12 0.24 0.36 0.48 0.62]
#define METAL_REFLECTION_STRENGTH 0.36 // [0.00 0.14 0.24 0.36 0.50 0.68]
#define CYBER_REFLECTION_SPLIT 0.12 // [0.00 0.06 0.12 0.20 0.32 0.48]
#define CYBER_GLASS_TINT 0.12 // [0.00 0.06 0.12 0.20 0.32 0.48]
#define FRESNEL_POWER 2.60 // [1.40 1.90 2.60 3.40 4.60]
#define NEON_COLOR_BIAS 0.72 // [0.00 0.25 0.48 0.72 0.95 1.20]
#define CYBER_NEON_SURFACE_GAIN 0.42 // [0.00 0.18 0.30 0.42 0.58 0.78]
#define SUMMER_TONE_STRENGTH 0.12 // [0.00 0.12 0.22 0.30 0.42 0.56]
#define SUMMER_BLUE_TINT 0.08 // [0.00 0.08 0.14 0.18 0.26 0.36]
#define SUMMER_GREEN_LIFT 0.18 // [0.00 0.10 0.18 0.24 0.34 0.46]
#define TIME_NOON_BRIGHTNESS 0.13 // [0.00 0.06 0.10 0.13 0.18 0.24]
#define TIME_NIGHT_DARKNESS 0.18 // [0.00 0.08 0.14 0.18 0.24 0.32]
#define BF3_POST_STRENGTH 0.00 // [0.00 0.12 0.20 0.28 0.38 0.50]
#define BF3_BLUE_TINT 0.10 // [0.00 0.10 0.18 0.24 0.34 0.46]
#define BF3_ORANGE_HIGHLIGHTS 0.08 // [0.00 0.08 0.16 0.24 0.36 0.50]
#define BF3_CONTRAST_PUNCH 0.08 // [0.00 0.08 0.14 0.18 0.26 0.36]
#define BF3_BLOOM_GLARE 0.06 // [0.00 0.06 0.10 0.14 0.22 0.32]
#define BF3_CHROMATIC_ABERRATION 0.00 // [0.00 0.04 0.08 0.12 0.18 0.26]
#define RAIN_GLOOM_STRENGTH 0.30 // [0.00 0.18 0.30 0.42 0.56 0.72]
#define RAIN_NIGHT_GLOOM 0.24 // [0.00 0.14 0.24 0.34 0.46 0.60]
#define RAIN_GRAY_BLUE_TINT 0.18 // [0.00 0.18 0.30 0.40 0.54 0.70]
#define RAIN_SATURATION_DROP 0.18 // [0.00 0.10 0.18 0.28 0.40 0.54]
#define RAIN_BLOOM_DAMPING 0.32 // [0.00 0.12 0.22 0.32 0.44 0.58]
#define PREMIUM_IMAGE_STRENGTH 0.30 // [0.00 0.18 0.30 0.46 0.62 0.78]
#define ACES_TONEMAP_STRENGTH 0.42 // [0.00 0.24 0.42 0.58 0.74 0.90]
#define LOCAL_CONTRAST_STRENGTH 0.18 // [0.00 0.08 0.14 0.18 0.26 0.36]
#define CLARITY_SHARPEN_STRENGTH 0.12 // [0.00 0.05 0.09 0.12 0.18 0.26]
#define VIBRANCE_STRENGTH 0.12 // [0.00 0.08 0.12 0.16 0.24 0.34]
#define COLOR_DEPTH_STRENGTH 0.10 // [0.00 0.10 0.18 0.24 0.34 0.46]
#define HIGHLIGHT_ROLLOFF_STRENGTH 0.38 // [0.00 0.16 0.28 0.38 0.52 0.70]
#define LDR_SHADOW_DETAIL 0.72 // [0.00 0.30 0.52 0.72 0.88 1.00]
#define LDR_HIGHLIGHT_DETAIL 0.76 // [0.00 0.30 0.52 0.76 0.90 1.00]
#define LDR_LOCAL_DETAIL 0.18 // [0.00 0.08 0.14 0.18 0.26 0.38]
#define LDR_BLACK_FLOOR 0.0004 // [0.0000 0.0002 0.0004 0.0008 0.0012]
#define MATERIAL_SPECULAR_STRENGTH 0.30 // [0.00 0.12 0.22 0.30 0.42 0.56]
#define MATERIAL_SURFACE_CONTRAST 0.24 // [0.00 0.10 0.18 0.24 0.34 0.46]
#define MATERIAL_EMISSIVE_GLOW 0.34 // [0.00 0.12 0.22 0.34 0.48 0.66]
#define MATERIAL_FRESNEL_POLISH 0.28 // [0.00 0.12 0.20 0.28 0.40 0.54]
#define PBR_FINAL_REFLECTANCE_GAIN 0.34 // [0.00 0.14 0.24 0.34 0.48 0.66]
#define PBR_FINAL_NORMAL_FRESNEL 0.44 // [0.00 0.18 0.30 0.44 0.62 0.82]
#define PALE_SURFACE_ROLLOFF 0.46 // [0.00 0.18 0.30 0.46 0.62 0.80]
#define PALE_SURFACE_BLOOM_DAMPING 0.64 // [0.00 0.24 0.42 0.64 0.82 1.00]
#define WATER_DAY_POST_ROLLOFF 0.82 // [0.00 0.30 0.52 0.68 0.82 0.94]
#define WATER_DAY_BLOOM_DAMPING 0.88 // [0.00 0.30 0.52 0.70 0.88 1.00]
#define WATER_GEOMETRY_REFLECTION_FINAL_STRENGTH 0.90 // [0.00 0.28 0.48 0.72 0.90 1.10]
#define SKY_STAR_STRENGTH 1.10
#define SKY_MILKY_WAY_STRENGTH 1.05
#define SKY_SHOOTING_STAR_STRENGTH 1.25

#define vegetationBoost VEGETATION_BOOST
#define bloomStrength CYBER_BLOOM_STRENGTH
#define saturationBloomStrength SATURATION_BLOOM_STRENGTH
#define ambientGlowStrength AMBIENT_GLOW_STRENGTH
#define glassReflectionStrength GLASS_REFLECTION_STRENGTH
#define fresnelPower FRESNEL_POWER
#define neonColorBias NEON_COLOR_BIAS

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

float getNoonExposureMask() {
    float elevation = max(getSunElevationCurve(), 0.0);
    return smoothstep(0.36, 0.98, elevation);
}

float getNightExposureMask() {
    return 1.0 - smoothstep(-0.18, 0.08, getSunElevationCurve());
}

float getSkyNightFeatureMask() {
    float t = getTime01();
    float afterDusk = smoothstep(0.54, 0.58, t);
    float beforeDawn = 1.0 - smoothstep(0.91, 0.97, t);
    return clamp(afterDusk * beforeDawn, 0.0, 1.0);
}

vec3 applyTimeExposureTone(vec3 color) {
    float noon = getNoonExposureMask();
    float night = getNightExposureMask();
    float exposure = 1.0 + noon * TIME_NOON_BRIGHTNESS - night * TIME_NIGHT_DARKNESS;

    vec3 nightTint = vec3(0.86, 0.91, 1.02);
    vec3 dayLift = vec3(1.03, 1.025, 0.985);
    vec3 timeTint = mix(vec3(1.0), nightTint, night * 0.28);
    timeTint = mix(timeTint, dayLift, noon * 0.18);

    return color * exposure * timeTint;
}

float getRainMood() {
    return clamp(max(rainStrength, wetness), 0.0, 1.0);
}

vec3 saturateColor(vec3 color, float amount) {
    float brightness = luma(color);
    return mix(vec3(brightness), color, amount);
}

vec3 acesTonemap(vec3 color) {
    color = max(color, vec3(0.0));
    return clamp((color * (2.51 * color + vec3(0.03))) /
                 (color * (2.43 * color + vec3(0.59)) + vec3(0.14)), 0.0, 1.0);
}

vec3 sampleLocalAverage(vec2 uv);

float applyLdrPrecisionCurve(float value) {
    float t = clamp(value, 0.0, 1.0);

    float shadowCurve = pow(max(t, 0.0), mix(1.0, 0.58, LDR_SHADOW_DETAIL));
    float shadowMask = 1.0 - smoothstep(0.055, 0.34, t);
    t = mix(t, shadowCurve, shadowMask * LDR_SHADOW_DETAIL * 0.68);

    float shoulderPower = mix(1.0, 0.62, LDR_HIGHLIGHT_DETAIL);
    float shoulder = 1.0 - pow(max(1.0 - t, 0.0), shoulderPower);
    float shoulderMask = smoothstep(0.58, 0.98, t);
    t = mix(t, shoulder, shoulderMask * LDR_HIGHLIGHT_DETAIL * 0.62);

    return clamp(t, 0.0, 1.0);
}

vec3 applyPrecisionLdrTone(vec3 color, vec2 uv, float depth, float waterMask) {
    color = clamp(color, 0.0, 1.0);
    float lum = max(luma(color), 0.000001);

    vec3 localAverage = clamp(sampleLocalAverage(uv), 0.0, 1.0);
    float localLum = max(luma(localAverage), 0.000001);
    float localContrast = clamp((lum - localLum) / (localLum + 0.045), -1.0, 1.0);
    float sceneMask = 1.0 - step(0.999999, depth);
    float detailGuard = smoothstep(LDR_BLACK_FLOOR, 0.18, lum) * (1.0 - smoothstep(0.74, 1.0, lum));
    detailGuard *= sceneMask * mix(1.0, 0.70, waterMask);
    color *= max(0.0, 1.0 + localContrast * LDR_LOCAL_DETAIL * detailGuard);
    color = clamp(color, 0.0, 1.0);

    lum = max(luma(color), 0.000001);
    float mappedLum = applyLdrPrecisionCurve(lum);
    vec3 chroma = color / lum;
    float highlightDesat = smoothstep(0.82, 1.0, mappedLum) * (1.0 - LDR_HIGHLIGHT_DETAIL * 0.30);
    chroma = mix(chroma, vec3(luma(chroma)), highlightDesat * 0.18);

    vec3 mapped = chroma * mappedLum;
    return clamp(mapped, LDR_BLACK_FLOOR * 0.25, 1.0);
}

vec3 applyContrast(vec3 color, float amount) {
    return (color - 0.5) * amount + 0.5;
}

vec3 applyToneStyle(vec3 color) {
#if COLOR_STYLE == 0
    return color;
#elif COLOR_STYLE == 2
    vec3 warm = vec3(1.04, 1.00, 0.94);
    return color * warm;
#else
    vec3 clean = vec3(0.98, 1.01, 1.04);
    return color * clean;
#endif
}

vec3 liftHighlights(vec3 color, float amount) {
    float brightness = max3(color);
    float mask = smoothstep(0.62, 1.00, brightness);
    vec3 glow = color * color;
    return mix(color, color + glow * amount, mask);
}

float getVegetationMask(vec3 color) {
    float brightness = luma(color);
    float saturation = colorSaturation(color);
    float greenLead = smoothstep(-0.02, 0.20, color.g - max(color.r * 0.86, color.b));
    float yellowGreen = smoothstep(-0.20, 0.12, color.r - color.g) * smoothstep(0.02, 0.24, color.g - color.b);
    float notBlue = 1.0 - smoothstep(0.00, 0.16, color.b - color.g);
    float visible = smoothstep(0.035, 0.18, brightness);
    return clamp(max(greenLead, yellowGreen) * smoothstep(0.08, 0.36, saturation) * notBlue * visible, 0.0, 1.0);
}

vec3 applyVegetationColorLift(vec3 color) {
    float brightness = luma(color);
    float night = getNightExposureMask();
    float vegetation = getVegetationMask(color) * vegetationBoost * (1.0 - night * 0.68);
    float shadowMask = 1.0 - smoothstep(0.16, 0.52, brightness);
    float highlightMask = smoothstep(0.40, 0.92, brightness);

    vec3 blueGreenShadow = vec3(brightness * 0.48, brightness * 0.84, brightness * 0.80);
    blueGreenShadow = mix(blueGreenShadow, vec3(brightness * 0.42, brightness * 0.62, brightness * 0.54), night);
    vec3 yellowLift = vec3(brightness * 1.08, brightness * 1.18, brightness * 0.70);
    vec3 cyanLift = vec3(brightness * 0.58, brightness * 1.16, brightness * 1.08);
    vec3 brightHue = mix(yellowLift, cyanLift, smoothstep(0.52, 0.88, brightness));

    vec3 shifted = mix(color, blueGreenShadow, vegetation * shadowMask * 0.42);
    shifted = mix(shifted, max(shifted, brightHue), vegetation * highlightMask * 0.52);
    shifted = mix(shifted, saturateColor(shifted, 1.08), vegetation * 0.22);
    return shifted;
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

float getSaturationAwareBloomMask(vec3 color) {
    float brightness = luma(color);
    float saturation = colorSaturation(color);
    float intensity = max3(color);
    float neon = getNeonColorMask(color);
    float colorEnergy = saturation * intensity;
    float highlight = smoothstep(0.58, 1.00, intensity);

    float thresholdDrop = clamp(colorEnergy * saturationBloomStrength * 0.26 +
                               neon * neonColorBias * (0.32 + CYBER_NEON_SURFACE_GAIN * 0.08) +
                               highlight * ambientGlowStrength * 0.16, 0.0, 0.46);
    float threshold = max(0.10, BLOOM_THRESHOLD - thresholdDrop);
    float bloomSignal = max(brightness, intensity * mix(0.50, 0.82, saturation));
    bloomSignal += neon * neonColorBias * 0.18;

    return smoothstep(threshold, threshold + BLOOM_SOFT_KNEE, bloomSignal);
}

vec3 extractBloom(vec3 color) {
    float mask = getSaturationAwareBloomMask(color);
    vec3 neonTint = mix(color,
                        saturateColor(color, 1.25 + neonColorBias * 0.24 + CYBER_NEON_SURFACE_GAIN * 0.12),
                        getNeonColorMask(color) * (0.45 + CYBER_NEON_SURFACE_GAIN * 0.14));
    return neonTint * mask;
}

vec3 sampleBloom(vec2 uv) {
    vec2 px = vec2(2.0 / viewWidth, 2.0 / viewHeight) * max(BLOOM_RADIUS * 0.18, 0.50);
    vec3 bloom = texture2D(colortex5, uv).rgb * 0.50;

    bloom += texture2D(colortex5, clamp(uv + vec2( px.x, 0.0), vec2(0.001), vec2(0.999))).rgb * 0.10;
    bloom += texture2D(colortex5, clamp(uv + vec2(-px.x, 0.0), vec2(0.001), vec2(0.999))).rgb * 0.10;
    bloom += texture2D(colortex5, clamp(uv + vec2(0.0,  px.y), vec2(0.001), vec2(0.999))).rgb * 0.10;
    bloom += texture2D(colortex5, clamp(uv + vec2(0.0, -px.y), vec2(0.001), vec2(0.999))).rgb * 0.10;

    bloom += texture2D(colortex5, clamp(uv + vec2( px.x,  px.y), vec2(0.001), vec2(0.999))).rgb * 0.025;
    bloom += texture2D(colortex5, clamp(uv + vec2(-px.x,  px.y), vec2(0.001), vec2(0.999))).rgb * 0.025;
    bloom += texture2D(colortex5, clamp(uv + vec2( px.x, -px.y), vec2(0.001), vec2(0.999))).rgb * 0.025;
    bloom += texture2D(colortex5, clamp(uv + vec2(-px.x, -px.y), vec2(0.001), vec2(0.999))).rgb * 0.025;

    return bloom;
}

vec3 applyColoredAmbientGlow(vec3 color, vec3 bloomColor) {
    float colorGlow = clamp(luma(bloomColor) * 1.70 + colorSaturation(bloomColor) * max3(bloomColor) * 0.65, 0.0, 1.0);
    float surfaceCatch = smoothstep(0.08, 0.72, luma(color)) * (1.0 - smoothstep(0.96, 1.28, max3(color)));
    vec3 bounce = saturateColor(bloomColor, 1.14 + neonColorBias * 0.26) * (0.30 + surfaceCatch * 0.44);
    vec3 added = color + bounce * ambientGlowStrength;
    return mix(color, added, colorGlow * ambientGlowStrength);
}

vec3 sampleBloomGI(vec2 uv) {
    vec2 px = vec2(BLOOM_GI_RADIUS / viewWidth, BLOOM_GI_RADIUS / viewHeight);
    vec3 gi = texture2D(colortex5, uv).rgb * 0.18;

    gi += texture2D(colortex5, clamp(uv + vec2( px.x, 0.0), vec2(0.001), vec2(0.999))).rgb * 0.105;
    gi += texture2D(colortex5, clamp(uv + vec2(-px.x, 0.0), vec2(0.001), vec2(0.999))).rgb * 0.105;
    gi += texture2D(colortex5, clamp(uv + vec2(0.0,  px.y), vec2(0.001), vec2(0.999))).rgb * 0.105;
    gi += texture2D(colortex5, clamp(uv + vec2(0.0, -px.y), vec2(0.001), vec2(0.999))).rgb * 0.105;

    gi += texture2D(colortex5, clamp(uv + vec2( px.x,  px.y) * 0.78, vec2(0.001), vec2(0.999))).rgb * 0.075;
    gi += texture2D(colortex5, clamp(uv + vec2(-px.x,  px.y) * 0.78, vec2(0.001), vec2(0.999))).rgb * 0.075;
    gi += texture2D(colortex5, clamp(uv + vec2( px.x, -px.y) * 0.78, vec2(0.001), vec2(0.999))).rgb * 0.075;
    gi += texture2D(colortex5, clamp(uv + vec2(-px.x, -px.y) * 0.78, vec2(0.001), vec2(0.999))).rgb * 0.075;

    return gi;
}

vec3 applyBloomGlobalIllumination(vec3 color, vec2 uv, float depth, float waterMask) {
    if (BLOOM_GI_STRENGTH <= 0.001 || depth >= 0.999999) {
        return color;
    }

    vec3 indirect = sampleBloomGI(uv);
    float indirectEnergy = clamp(luma(indirect) * 1.30 + colorSaturation(indirect) * max3(indirect) * 0.46, 0.0, 1.0);
    float brightness = luma(color);
    float shadowCatch = 1.0 - smoothstep(0.18, 0.72, brightness);
    float midSurface = smoothstep(0.04, 0.42, brightness) * (1.0 - smoothstep(0.92, 1.22, max3(color)));
    float surfaceCatch = clamp(0.18 + shadowCatch * BLOOM_GI_SURFACE_CATCH + midSurface * 0.28, 0.0, 1.0);
    surfaceCatch *= mix(1.0, 0.66, waterMask);

    vec3 neutralBounce = vec3(luma(indirect));
    vec3 coloredBounce = mix(neutralBounce, indirect, BLOOM_GI_COLOR_PRESERVE);
    coloredBounce = saturateColor(coloredBounce, 1.04 + neonColorBias * 0.10);

    vec3 bounced = color + coloredBounce * (BLOOM_GI_STRENGTH * surfaceCatch);
    vec3 softMix = mix(color, max(color, bounced), indirectEnergy * BLOOM_GI_STRENGTH * 0.58);
    return mix(softMix, bounced, indirectEnergy * 0.34);
}

float getSoftEdge(vec2 uv) {
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);

    float d = texture2D(depthtex0, uv).r;

    vec3 cx1 = texture2D(colortex0, clamp(uv + vec2(px.x, 0.0), vec2(0.001), vec2(0.999))).rgb;
    vec3 cx2 = texture2D(colortex0, clamp(uv - vec2(px.x, 0.0), vec2(0.001), vec2(0.999))).rgb;
    vec3 cy1 = texture2D(colortex0, clamp(uv + vec2(0.0, px.y), vec2(0.001), vec2(0.999))).rgb;
    vec3 cy2 = texture2D(colortex0, clamp(uv - vec2(0.0, px.y), vec2(0.001), vec2(0.999))).rgb;

    float colorEdge = abs(luma(cx1) - luma(cx2)) + abs(luma(cy1) - luma(cy2));

    float dx1 = texture2D(depthtex0, clamp(uv + vec2(px.x, 0.0), vec2(0.001), vec2(0.999))).r;
    float dx2 = texture2D(depthtex0, clamp(uv - vec2(px.x, 0.0), vec2(0.001), vec2(0.999))).r;
    float dy1 = texture2D(depthtex0, clamp(uv + vec2(0.0, px.y), vec2(0.001), vec2(0.999))).r;
    float dy2 = texture2D(depthtex0, clamp(uv - vec2(0.0, px.y), vec2(0.001), vec2(0.999))).r;

    float depthEdge = (abs(dx1 - dx2) + abs(dy1 - dy2)) * 46.0;
    depthEdge *= 1.0 - step(0.999999, d);

    return smoothstep(SOFT_EDGE_THRESHOLD, SOFT_EDGE_THRESHOLD * 2.8, colorEdge + depthEdge);
}

vec3 sampleLocalAverage(vec2 uv) {
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec3 avg = texture2D(colortex0, uv).rgb * 0.36;
    avg += texture2D(colortex0, clamp(uv + vec2( px.x, 0.0) * 1.35, vec2(0.001), vec2(0.999))).rgb * 0.16;
    avg += texture2D(colortex0, clamp(uv + vec2(-px.x, 0.0) * 1.35, vec2(0.001), vec2(0.999))).rgb * 0.16;
    avg += texture2D(colortex0, clamp(uv + vec2(0.0,  px.y) * 1.35, vec2(0.001), vec2(0.999))).rgb * 0.16;
    avg += texture2D(colortex0, clamp(uv + vec2(0.0, -px.y) * 1.35, vec2(0.001), vec2(0.999))).rgb * 0.16;
    return avg;
}

vec3 applyAdaptiveVibrance(vec3 color, float amount) {
    float saturation = colorSaturation(color);
    float brightness = luma(color);
    float highlightProtect = 1.0 - smoothstep(0.78, 1.16, max3(color));
    float vibrance = amount * (1.0 - saturation) * smoothstep(0.05, 0.64, brightness) * highlightProtect;
    return saturateColor(color, 1.0 + vibrance);
}

vec3 applyPremiumImagePipeline(vec3 color, vec2 uv, float depth, float waterMask, vec3 bloomColor) {
    if (PREMIUM_IMAGE_STRENGTH <= 0.001) {
        return color;
    }

    vec3 original = color;
    float sceneMask = 1.0 - step(0.999999, depth);
    float edgeSafe = 1.0 - getSoftEdge(uv) * 0.62;
    float rain = getRainMood();
    float night = getNightExposureMask();
    float noon = getNoonExposureMask();
    float brightness = luma(color);

    vec3 centerRaw = texture2D(colortex0, uv).rgb;
    vec3 localAvg = sampleLocalAverage(uv);
    vec3 detail = centerRaw - localAvg;
    color += detail * CLARITY_SHARPEN_STRENGTH * sceneMask * edgeSafe;

    float localLuma = luma(localAvg);
    float contrastDelta = brightness - localLuma;
    color += color * contrastDelta * LOCAL_CONTRAST_STRENGTH * sceneMask * edgeSafe;

    color = applyAdaptiveVibrance(color, VIBRANCE_STRENGTH * (0.72 + noon * 0.22) * (1.0 - rain * 0.32));

    float shadow = 1.0 - smoothstep(0.12, 0.56, luma(color));
    float highlight = smoothstep(0.48, 1.10, max3(color));
    vec3 coolDepth = color * vec3(0.78, 0.90, 1.12) + vec3(0.000, 0.006, 0.020);
    vec3 warmShoulder = color * vec3(1.12, 1.04, 0.88) + vec3(0.030, 0.016, 0.000);
    vec3 colorDepth = mix(color, coolDepth, COLOR_DEPTH_STRENGTH * (shadow + night * 0.28) * (1.0 - rain * 0.38));
    colorDepth = mix(colorDepth, max(colorDepth, warmShoulder), COLOR_DEPTH_STRENGTH * highlight * (0.55 + noon * 0.22) * (1.0 - rain * 0.30));
    color = mix(color, colorDepth, PREMIUM_IMAGE_STRENGTH);

    vec3 aces = acesTonemap(color * (1.0 + PREMIUM_IMAGE_STRENGTH * 0.10));
    float rolloffMask = smoothstep(0.68, 1.32, max3(color));
    color = mix(color, aces, ACES_TONEMAP_STRENGTH * (0.34 + rolloffMask * HIGHLIGHT_ROLLOFF_STRENGTH));

    vec3 polishedGlow = saturateColor(bloomColor, 1.04) * vec3(0.92, 0.98, 1.08);
    color += polishedGlow * PREMIUM_IMAGE_STRENGTH * 0.045 * (1.0 - rain * 0.34 + waterMask * 0.18);

    return mix(original, color, PREMIUM_IMAGE_STRENGTH);
}

vec3 applyPastelTone(vec3 color) {
    float brightness = luma(color);
    vec3 lifted = mix(color, sqrt(clamp(color, 0.0, 1.0)), 0.36);
    lifted = mix(lifted, vec3(brightness), 0.08);
    lifted = mix(lifted, vec3(0.88, 0.94, 1.0), PASTEL_WASH * (1.0 - smoothstep(0.72, 1.0, brightness)));
    lifted *= vec3(1.02, 1.012, 1.045);
    lifted = saturateColor(lifted, 1.05);
    return mix(color, lifted, PASTEL_STRENGTH);
}

vec3 applySummerBlueTone(vec3 color) {
    float brightness = luma(color);
    float vegetation = getVegetationMask(color);
    float highlight = smoothstep(0.38, 0.92, brightness);
    float shadow = 1.0 - smoothstep(0.10, 0.52, brightness);

    vec3 sunLift = color * vec3(1.045, 1.060, 0.985) + vec3(0.010, 0.014, 0.004) * highlight;
    vec3 summerGreen = vec3(max(color.r, brightness * 0.54), max(color.g, brightness * 1.10), max(color.b, brightness * 0.58));
    sunLift = mix(sunLift, max(sunLift, summerGreen), vegetation * SUMMER_GREEN_LIFT);

    vec3 blueWash = color * vec3(0.94, 0.985, 1.095) + vec3(0.006, 0.014, 0.034);
    vec3 toned = mix(sunLift, blueWash, SUMMER_BLUE_TINT * (0.42 + shadow * 0.34));
    return mix(color, toned, SUMMER_TONE_STRENGTH);
}

float getPaleSurfaceMask(vec3 color, float depth, float waterMask) {
    if (depth >= 0.999999 || waterMask > 0.05) {
        return 0.0;
    }

    float brightness = luma(color);
    float saturation = colorSaturation(color);
    float intensity = max3(color);
    float pale = smoothstep(0.48, 0.88, brightness) * (1.0 - smoothstep(0.14, 0.42, saturation));
    float warmSand = smoothstep(-0.04, 0.18, color.r - color.b) *
                     smoothstep(-0.06, 0.22, color.g - color.b) *
                     (1.0 - smoothstep(0.18, 0.48, abs(color.r - color.g)));
    float blown = smoothstep(0.72, 1.10, intensity);
    return clamp(pale * warmSand * (0.48 + blown * 0.84), 0.0, 1.0);
}

vec3 applyPaleSurfaceRolloff(vec3 color, float depth, float waterMask) {
    float mask = getPaleSurfaceMask(color, depth, waterMask) * PALE_SURFACE_ROLLOFF;
    if (mask <= 0.001) {
        return color;
    }

    float intensity = max3(color);
    float blown = smoothstep(0.70, 1.12, intensity);
    vec3 compressed = color / (vec3(1.0) + color * (0.34 + blown * 0.72) * PALE_SURFACE_ROLLOFF);
    vec3 sandNeutral = vec3(luma(compressed)) * vec3(1.04, 0.98, 0.86);
    compressed = mix(compressed, sandNeutral, 0.10 + blown * 0.12);
    return mix(color, compressed, clamp(mask, 0.0, 0.82));
}

vec3 applyWaterDayPostRolloff(vec3 color, float waterMask) {
    float noon = getNoonExposureMask();
    if (waterMask <= 0.001 || noon <= 0.001) {
        return color;
    }

    float intensity = max3(color);
    float blown = smoothstep(0.62, 1.05, intensity);
    float mask = clamp(waterMask * noon * WATER_DAY_POST_ROLLOFF * (0.62 + blown * 0.38), 0.0, 0.94);
    vec3 compressed = color / (vec3(1.0) + color * (0.38 + blown * 0.52 + noon * 1.08));
    vec3 blueBalanced = vec3(luma(compressed)) * vec3(0.72, 0.84, 1.02);
    compressed = mix(compressed, blueBalanced, noon * 0.18);
    return mix(color, compressed, mask);
}

vec4 sampleResolvedGeometryReflection(vec2 uv) {
    vec2 px = vec2(1.25 / viewWidth, 1.25 / viewHeight);
    vec4 reflection = texture2D(colortex8, clamp(uv, vec2(0.001), vec2(0.999))) * 0.50;
    reflection += texture2D(colortex8, clamp(uv + vec2( px.x, 0.0), vec2(0.001), vec2(0.999))) * 0.13;
    reflection += texture2D(colortex8, clamp(uv + vec2(-px.x, 0.0), vec2(0.001), vec2(0.999))) * 0.13;
    reflection += texture2D(colortex8, clamp(uv + vec2(0.0,  px.y), vec2(0.001), vec2(0.999))) * 0.08;
    reflection += texture2D(colortex8, clamp(uv + vec2(0.0, -px.y), vec2(0.001), vec2(0.999))) * 0.08;
    reflection += texture2D(colortex8, clamp(uv + vec2(0.0,  px.y * 2.5), vec2(0.001), vec2(0.999))) * 0.04;
    reflection += texture2D(colortex8, clamp(uv + vec2(0.0, -px.y * 2.5), vec2(0.001), vec2(0.999))) * 0.04;
    return reflection;
}

vec3 applyResolvedWaterGeometryReflection(vec3 color, vec2 uv, float depth, float waterMask) {
    if (waterMask <= 0.001 || isEyeInWater != 0 || depth >= 0.999999 ||
        WATER_GEOMETRY_REFLECTION_FINAL_STRENGTH <= 0.001) {
        return color;
    }

    vec4 reflection = sampleResolvedGeometryReflection(uv);
    if (reflection.a <= 0.001) {
        return color;
    }

    float noon = getNoonExposureMask();
    float night = getNightExposureMask();
    float rain = getRainMood();
    float edgeFade = smoothstep(0.00, 0.08, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
    float alpha = clamp(reflection.a * WATER_GEOMETRY_REFLECTION_FINAL_STRENGTH, 0.0, 0.86);
    alpha *= 1.0 - noon * 0.08;
    alpha *= 1.0 - rain * 0.18;
    alpha *= 0.84 + night * 0.12;
    alpha *= 0.76 + edgeFade * 0.24;

    vec3 reflected = clamp(reflection.rgb * vec3(0.82, 0.94, 1.08), 0.0, 1.0);
    reflected = mix(vec3(luma(reflected)) * vec3(0.72, 0.86, 1.08), reflected, 0.78);
    reflected = mix(reflected, reflected * vec3(0.68, 0.80, 1.10), rain * 0.16 + night * 0.12);
    vec3 lifted = max(color * (0.96 - alpha * 0.06), reflected);
    vec3 blended = mix(color, lifted, alpha * 0.82);
    blended += reflected * alpha * (0.030 + night * 0.020);
    return clamp(blended, 0.0, 1.0);
}

vec3 sampleBattlefieldLensFringe(vec3 color, vec2 uv) {
    vec2 center = uv - vec2(0.5);
    float edge = smoothstep(0.16, 0.72, dot(center, center) * 2.3);
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec2 offset = center * px * (2.2 + edge * 7.0) * BF3_CHROMATIC_ABERRATION;

    vec3 fringe = color;
    fringe.r = texture2D(colortex0, clamp(uv - offset, vec2(0.001), vec2(0.999))).r;
    fringe.b = texture2D(colortex0, clamp(uv + offset, vec2(0.001), vec2(0.999))).b;
    return mix(color, fringe, edge * BF3_CHROMATIC_ABERRATION * 0.55);
}

vec3 applyBattlefieldThreePost(vec3 color, vec2 uv, float depth, float waterMask, vec3 bloomColor) {
    float brightness = luma(color);
    float intensity = max3(color);
    float shadow = 1.0 - smoothstep(0.12, 0.54, brightness);
    float mid = smoothstep(0.06, 0.42, brightness) * (1.0 - smoothstep(0.72, 1.08, intensity));
    float highlight = smoothstep(0.52, 1.05, intensity);
    float sceneMask = mix(1.0, 0.72, step(0.999999, depth));

    vec3 coolTint = vec3(0.82, 0.96, 1.18);
    float coolAmount = BF3_BLUE_TINT * (0.28 + shadow * 0.58 + mid * 0.20 + waterMask * 0.18);
    vec3 graded = color * mix(vec3(1.0), coolTint, clamp(coolAmount, 0.0, 1.0));
    graded += vec3(0.000, 0.010, 0.036) * BF3_BLUE_TINT * (shadow + mid * 0.45);

    vec3 amberHighlight = graded * vec3(1.14, 1.035, 0.82) + vec3(0.050, 0.027, 0.000) * highlight;
    graded = mix(graded, max(graded, amberHighlight), highlight * BF3_ORANGE_HIGHLIGHTS);

    vec3 contrast = (graded - 0.5) * (1.0 + BF3_CONTRAST_PUNCH * 0.58) + 0.5;
    contrast = max(contrast - vec3(shadow * BF3_CONTRAST_PUNCH * 0.07), vec3(0.0));
    vec3 filmic = contrast * (1.0 + contrast * 0.10) / (1.0 + contrast * 0.20);
    graded = mix(contrast, filmic, 0.52);

    vec3 glareTint = saturateColor(bloomColor, 1.05 + BF3_BLUE_TINT * 0.28) * vec3(0.82, 0.98, 1.22);
    graded += glareTint * BF3_BLOOM_GLARE * (0.42 + highlight * 0.48 + waterMask * 0.18);

    graded = sampleBattlefieldLensFringe(graded, uv);

    vec2 p = uv * (1.0 - uv.yx);
    float vignetteEdge = 1.0 - smoothstep(0.16, 1.00, p.x * p.y * 16.0);
    graded *= 1.0 - vignetteEdge * BF3_POST_STRENGTH * 0.16;

    return mix(color, graded, BF3_POST_STRENGTH * sceneMask);
}

float getRainBloomVisibility() {
    float rain = getRainMood();
    float night = getNightExposureMask();
    float visibility = 1.0 - rain * RAIN_BLOOM_DAMPING * (0.72 + night * 0.46);
    visibility -= night * BLOOM_NIGHT_DAMPING * 0.22;
    return clamp(visibility, 0.18, 1.0);
}

vec3 applyPhysicalBloomComposite(vec3 color, vec3 bloomColor, vec2 uv, float depth, float waterMask) {
    float sceneLuma = luma(color);
    float adaptedLuma = mix(sceneLuma, luma(sampleLocalAverage(uv)), BLOOM_ADAPTATION_STRENGTH);
    float bloomLuma = luma(bloomColor);
    float sourceOverAdapted = smoothstep(0.015, 0.30, bloomLuma - adaptedLuma * 0.10);
    float brightSurface = smoothstep(0.70, 1.16, max3(color));
    float skyMask = step(0.999999, depth);
    float rain = getRainMood();
    float night = getNightExposureMask();

    float eyeProtection = 1.0 / (1.0 + adaptedLuma * (0.44 + BLOOM_ADAPTATION_STRENGTH * 0.52));
    float surfaceCatch = 1.0 - brightSurface * (0.22 + waterMask * 0.34 + skyMask * 0.26);
    float weatherScatter = 1.0 - rain * RAIN_BLOOM_DAMPING * (0.24 + night * 0.18);
    float coloredScatter = (BLOOM_STRENGTH + bloomStrength * 0.36) * eyeProtection * surfaceCatch * weatherScatter;

    vec3 veilColor = vec3(bloomLuma) * mix(vec3(1.0), vec3(0.82, 0.90, 1.06), night * 0.32 + rain * 0.18);
    vec3 veilingGlare = veilColor * BLOOM_VEIL_STRENGTH * sourceOverAdapted * (0.36 + eyeProtection * 0.64);
    veilingGlare *= 1.0 - waterMask * 0.42;

    return color + bloomColor * coloredScatter + veilingGlare;
}

vec3 applyRainGloomTone(vec3 color, float depth, float waterMask) {
    float rain = getRainMood();
    if (rain <= 0.001) {
        return color;
    }

    float night = getNightExposureMask();
    float morningEvening = 1.0 - getNoonExposureMask();
    float skyMask = step(0.999999, depth);
    float sceneMask = mix(1.0, 0.84, skyMask);
    float wetSurface = mix(1.0, 0.86, waterMask);

    float gloom = rain * (RAIN_GLOOM_STRENGTH + night * RAIN_NIGHT_GLOOM);
    gloom *= sceneMask * wetSurface * (0.88 + morningEvening * 0.16);
    gloom = clamp(gloom, 0.0, 0.86);

    float brightness = luma(color);
    vec3 overcastGray = vec3(brightness) * vec3(0.76, 0.84, 0.98) + vec3(0.006, 0.012, 0.026);
    vec3 nightRainBlue = vec3(brightness) * vec3(0.50, 0.58, 0.78) + vec3(0.000, 0.004, 0.018);
    vec3 rainTint = mix(overcastGray, nightRainBlue, night);

    vec3 toned = mix(color, rainTint, gloom * RAIN_GRAY_BLUE_TINT);
    toned = saturateColor(toned, max(0.0, 1.0 - gloom * RAIN_SATURATION_DROP));

    float darken = gloom * (0.34 + night * 0.30);
    toned *= 1.0 - darken;

    float highlightDamping = smoothstep(0.42, 1.08, max3(toned)) * gloom * (0.10 + night * 0.08);
    toned = mix(toned, vec3(luma(toned)) * vec3(0.72, 0.80, 0.96), highlightDamping);

    return toned;
}

float getScreenSpaceFresnel(vec2 uv, float depth) {
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    float dR = texture2D(depthtex0, clamp(uv + vec2(px.x, 0.0), vec2(0.001), vec2(0.999))).r;
    float dL = texture2D(depthtex0, clamp(uv - vec2(px.x, 0.0), vec2(0.001), vec2(0.999))).r;
    float dU = texture2D(depthtex0, clamp(uv + vec2(0.0, px.y), vec2(0.001), vec2(0.999))).r;
    float dD = texture2D(depthtex0, clamp(uv - vec2(0.0, px.y), vec2(0.001), vec2(0.999))).r;
    vec2 slope = vec2(dR - dL, dU - dD) * 90.0;
    vec3 normal = normalize(vec3(-slope.x, -slope.y, 1.0));
    float facing = clamp(normal.z, 0.0, 1.0);
    float objectMask = 1.0 - step(0.999999, depth);
    return pow(1.0 - facing, fresnelPower) * objectMask;
}

float getExplicitGlassMaterial(vec4 material, vec4 extra, float waterMask) {
    float marker = smoothstep(0.66, 0.71, extra.b) * (1.0 - smoothstep(0.74, 0.82, extra.b));
    float smoothSurface = smoothstep(0.78, 0.93, material.g);
    float sealedSurface = 1.0 - smoothstep(0.025, 0.15, material.a);
    float nonMetal = 1.0 - smoothstep(0.54, 0.78, extra.r);
    return clamp(marker * smoothSurface * sealedSurface * nonMetal * (1.0 - waterMask), 0.0, 1.0);
}

float getExplicitMetalMaterial(vec4 material, vec4 extra, float waterMask) {
    float marker = smoothstep(0.82, 0.86, extra.b) * (1.0 - smoothstep(0.90, 0.94, extra.b));
    float conductive = smoothstep(0.58, 0.78, extra.r);
    float smoothSurface = smoothstep(0.58, 0.88, material.g);
    float sealedSurface = 1.0 - smoothstep(0.04, 0.22, material.a);
    return clamp(marker * max(conductive, smoothSurface * 0.72) * sealedSurface * (1.0 - waterMask), 0.0, 1.0);
}

float getExplicitStoneMaterial(vec4 material, vec4 extra, float waterMask) {
    float marker = smoothstep(0.54, 0.58, extra.b) * (1.0 - smoothstep(0.62, 0.66, extra.b));
    float roughSurface = 1.0 - smoothstep(0.42, 0.72, material.g);
    float porousSurface = smoothstep(0.28, 0.58, material.a);
    return clamp(marker * max(roughSurface, porousSurface * 0.82) * (1.0 - waterMask), 0.0, 1.0);
}

float getPbrAwareFresnel(vec2 uv, float depth, float waterMask) {
    float screenFresnel = getScreenSpaceFresnel(uv, depth);
    vec4 normalData = texture2D(colortex2, uv);
    vec4 extra = texture2D(colortex3, uv);
    vec4 material = texture2D(colortex1, uv);
    float pbrPresence = clamp(extra.b, 0.0, 1.0) * (1.0 - waterMask);
    float smoothness = clamp(material.g, 0.0, 1.0) * (1.0 - waterMask);
    float glassMaterial = getExplicitGlassMaterial(material, extra, waterMask);
    float reflectiveSurface = smoothstep(0.66, 0.92, smoothness);
    vec3 storedNormal = normalize(normalData.rgb * 2.0 - 1.0);
    float normalFresnel = pow(1.0 - clamp(abs(storedNormal.z), 0.0, 1.0), fresnelPower);
    float normalMix = pbrPresence * PBR_FINAL_NORMAL_FRESNEL * (1.0 - reflectiveSurface * 0.45);
    normalMix *= 1.0 - glassMaterial * 0.55;
    return mix(screenFresnel, max(screenFresnel, normalFresnel), normalMix);
}

vec3 applyCyberpunkGlassReflection(vec3 color, vec2 uv, float depth, float waterMask) {
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    float fresnel = getPbrAwareFresnel(uv, depth, waterMask);
    vec4 material = texture2D(colortex1, uv);
    vec4 pbrExtra = texture2D(colortex3, uv);
    float smoothness = clamp(material.g, 0.0, 1.0) * (1.0 - waterMask);
    float emission = clamp(material.b, 0.0, 1.0) * (1.0 - waterMask);
    float reflectance = clamp(pbrExtra.r, 0.0, 1.0);
    float pbrPresence = clamp(pbrExtra.b, 0.0, 1.0) * (1.0 - waterMask);
    float glassMaterial = getExplicitGlassMaterial(material, pbrExtra, waterMask);
    float metalMaterial = getExplicitMetalMaterial(material, pbrExtra, waterMask);
    float stoneMaterial = getExplicitStoneMaterial(material, pbrExtra, waterMask);
    float saturation = colorSaturation(color);
    float intensity = max3(color);
    float neutralSurface = 1.0 - smoothstep(0.16, 0.54, saturation);
    float highReflectance = smoothstep(0.22, 0.78, reflectance) * (0.45 + pbrPresence * 0.55);
    float fallbackMetal = smoothstep(0.52, 0.90, smoothness) * neutralSurface * smoothstep(0.18, 0.72, intensity) * (1.0 - pbrPresence);
    float metalMask = max(max(smoothstep(0.26, 0.82, smoothness) * highReflectance * neutralSurface,
                              fallbackMetal * 0.42),
                          metalMaterial * (0.68 + smoothness * 0.32)) * METAL_REFLECTION_STRENGTH;
    metalMask *= (1.0 - glassMaterial) * (1.0 - stoneMaterial * 0.86);
    float highlightSpec = smoothstep(0.48, 0.96, intensity) * smoothstep(0.08, 0.42, saturation);
    highlightSpec = max(highlightSpec, smoothness * (0.16 + fresnel * 0.72));
    float noon = getNoonExposureMask();
    float waterGlass = waterMask * mix(0.72, 0.24, noon);
    float explicitGlassMask = glassMaterial * (0.52 + fresnel * 0.92);
    float inferredGlassMask = highlightSpec * (0.20 + fresnel * 1.42) * (1.0 - glassMaterial * 0.35);
    inferredGlassMask *= (1.0 - metalMaterial * 0.60) * (1.0 - stoneMaterial * 0.72);
    float glassMask = clamp(max(waterGlass, max(explicitGlassMask, inferredGlassMask)), 0.0, 1.0);
    float reflectiveMask = clamp(max(glassMask * glassReflectionStrength, metalMask * (0.62 + fresnel * 0.72)), 0.0, 1.0);

    vec2 centerDir = normalize((uv - vec2(0.5)) + vec2(0.0001, 0.0002));
    vec2 sideDir = normalize(vec2(centerDir.y, -centerDir.x) + centerDir * 0.45);
    float offsetSize = (2.0 + fresnel * 8.0 + smoothness * 3.0) * max(glassReflectionStrength, metalMask * 0.68);
    offsetSize *= mix(1.0, 0.58 + fresnel * 0.18, glassMaterial);
    vec2 offset = sideDir * px * offsetSize;
    float splitStrength = CYBER_REFLECTION_SPLIT * (1.0 - glassMaterial * 0.82);
    vec2 splitOffset = sideDir * px * (offsetSize * (1.0 + splitStrength * 0.90));

    vec3 reflectionA = texture2D(colortex0, clamp(uv + offset, vec2(0.001), vec2(0.999))).rgb;
    vec3 reflectionB = texture2D(colortex0, clamp(uv - offset * 0.55, vec2(0.001), vec2(0.999))).rgb;
    vec3 reflectionC = texture2D(colortex0, clamp(uv + splitOffset * vec2(0.55, -0.38), vec2(0.001), vec2(0.999))).rgb;
    vec3 reflection = mix(mix(reflectionA, reflectionB, 0.35), reflectionC, splitStrength * 0.24);
    vec3 cyanTint = reflection * vec3(0.58, 1.08, 1.26);
    vec3 magentaTint = reflection * vec3(1.22, 0.52, 1.14);
    vec3 steelReflection = mix(reflection, vec3(luma(reflection)) * vec3(0.82, 0.96, 1.15), metalMask);
    vec3 neonReflection = mix(cyanTint, magentaTint, smoothstep(0.35, 0.95, color.r + color.b - color.g));
    neonReflection = mix(neonReflection, max(neonReflection, steelReflection), metalMask * 0.58);
    neonReflection = mix(neonReflection, vec3(luma(reflection)) * vec3(0.70, 0.76, 0.84), stoneMaterial * 0.70);
    vec3 realisticReflection = mix(reflection, vec3(luma(reflection)) * vec3(0.90, 0.98, 1.07), 0.42 + fresnel * 0.22);
    neonReflection = mix(neonReflection, realisticReflection, glassMaterial);

    float streakAxis = abs(dot(normalize((uv - vec2(0.5)) + vec2(0.001)), sideDir));
    float neonStreak = smoothstep(0.82, 1.0, streakAxis) * smoothstep(0.42, 1.05, intensity + emission);
    neonStreak *= 1.0 - glassMaterial * 0.85;
    neonReflection += vec3(0.32, 0.74, 1.18) * neonStreak * splitStrength * (0.10 + fresnel * 0.22) * (1.0 + CYBER_NEON_SURFACE_GAIN * 0.42);

    float edgeFade = smoothstep(0.00, 0.08, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
    float mask = clamp(reflectiveMask * edgeFade * (0.26 + fresnel * 1.38 + metalMask * 0.36), 0.0, mix(0.84, 0.62, glassMaterial));
    vec3 glassTint = mix(color, color * vec3(0.70, 1.02, 1.18) + vec3(0.00, 0.016, 0.040), CYBER_GLASS_TINT * glassMask * (1.0 - metalMask));
    vec3 realGlassTint = color * vec3(0.94, 1.00, 1.04) + vec3(0.004, 0.010, 0.016);
    glassTint = mix(glassTint, realGlassTint, glassMaterial);
    color = mix(color, glassTint, max(glassMask * 0.26, glassMaterial * (0.24 + fresnel * 0.18)));
    vec3 reflectedColor = mix(color, max(color, neonReflection), mask);
    reflectedColor += neonReflection * mask * mix(0.12 + metalMask * 0.08, 0.030, waterMask * noon);
    return reflectedColor;
}

vec3 applyMaterialFinish(vec3 color, vec2 uv, float depth, float waterMask, vec3 bloomColor) {
    if (depth >= 0.999999 || isEyeInWater != 0) {
        return color;
    }

    vec4 material = texture2D(colortex1, uv);
    vec4 pbrExtra = texture2D(colortex3, uv);
    float smoothness = clamp(material.g, 0.0, 1.0) * (1.0 - waterMask);
    float emission = clamp(material.b, 0.0, 1.0) * (1.0 - waterMask);
    float porosity = clamp(material.a, 0.0, 1.0) * (1.0 - waterMask);
    float reflectance = clamp(pbrExtra.r, 0.0, 1.0);
    float pbrPresence = clamp(pbrExtra.b, 0.0, 1.0) * (1.0 - waterMask);
    float upward = clamp(pbrExtra.a, 0.0, 1.0) * (1.0 - waterMask);
    float glassMaterial = getExplicitGlassMaterial(material, pbrExtra, waterMask);
    float metalMaterial = getExplicitMetalMaterial(material, pbrExtra, waterMask);
    float stoneMaterial = getExplicitStoneMaterial(material, pbrExtra, waterMask);
    float rain = getRainMood();

    if (smoothness <= 0.001 && emission <= 0.001 && rain <= 0.001) {
        return color;
    }

    float fresnel = getPbrAwareFresnel(uv, depth, waterMask);
    float brightness = luma(color);
    float roughness = 1.0 - smoothness;

    vec3 polished = applyContrast(color, 1.0 + smoothness * MATERIAL_SURFACE_CONTRAST * 0.56);
    polished = mix(polished, sqrt(clamp(polished, 0.0, 1.0)), roughness * MATERIAL_SURFACE_CONTRAST * (0.12 + porosity * 0.22));
    polished = mix(polished, color * vec3(0.94, 1.00, 1.035) + bloomColor * 0.040, glassMaterial * 0.62);
    polished = mix(polished, polished * vec3(0.92, 0.94, 0.98), stoneMaterial * (0.16 + porosity * 0.18));

    vec3 sheenTint = saturateColor(max(bloomColor, color * 0.32), 1.0 + smoothness * 0.18);
    float reflectanceBoost = mix(0.70, 1.88, reflectance) * (1.0 + pbrPresence * PBR_FINAL_REFLECTANCE_GAIN);
    reflectanceBoost = mix(reflectanceBoost, reflectanceBoost * 0.42, stoneMaterial);
    reflectanceBoost = mix(reflectanceBoost, max(reflectanceBoost, 1.92), metalMaterial);
    float sheen = smoothness * (0.18 + fresnel * 1.20) * MATERIAL_SPECULAR_STRENGTH * reflectanceBoost;
    sheen = mix(sheen, smoothness * (0.08 + fresnel * 1.05) * MATERIAL_SPECULAR_STRENGTH, glassMaterial);
    sheen = mix(sheen, sheen * 0.38, stoneMaterial);
    sheen = max(sheen, metalMaterial * METAL_REFLECTION_STRENGTH * (0.12 + fresnel * 0.86));
    sheen += rain * upward * (1.0 - porosity * 0.58) * (0.08 + fresnel * 0.62) * MATERIAL_FRESNEL_POLISH;
    sheen *= 1.0 - glassMaterial * rain * 0.55;
    sheen *= 1.0 - stoneMaterial * rain * 0.20;
    polished = mix(polished, max(polished, sheenTint), clamp(sheen, 0.0, 0.62));

    float neonMask = getNeonColorMask(color);
    vec3 warmEmission = max(color, vec3(brightness) * vec3(1.22, 0.92, 0.58));
    vec3 neonEmission = saturateColor(max(color, bloomColor * (0.72 + neonColorBias * 0.16)), 1.04 + neonColorBias * 0.24);
    neonEmission = max(neonEmission, vec3(brightness) * vec3(0.44, 0.78, 1.18));
    vec3 emissionTint = mix(warmEmission, neonEmission, neonMask * CYBER_NEON_SURFACE_GAIN);
    polished += emissionTint * emission * MATERIAL_EMISSIVE_GLOW * (0.24 + smoothstep(0.08, 0.72, brightness) * 0.58);
    polished += neonEmission * neonMask * CYBER_NEON_SURFACE_GAIN * smoothness * 0.018;

    return mix(color, polished, clamp(smoothness + emission + rain * upward * (1.0 - porosity * 0.42) * 0.32, 0.0, 1.0));
}

float vignette(vec2 uv, float strength) {
    vec2 p = uv * (1.0 - uv.yx);
    float v = p.x * p.y * 16.0;
    return mix(1.0, smoothstep(0.18, 1.0, v), strength);
}

vec2 getUnderwaterFlowOffset(vec2 uv, float distanceMask) {
    vec2 center = uv - vec2(0.5);
    float t = frameTimeCounter;
    float waveA = sin(uv.y * 13.0 + uv.x * 4.0 + t * 0.74);
    float waveB = cos(uv.x * 11.0 - uv.y * 5.0 - t * 0.52);
    float noise = texture2D(noisetex, uv * 1.75 + vec2(t * 0.013, -t * 0.009)).r - 0.5;
    float edge = smoothstep(0.10, 0.74, length(center) * 1.42);
    vec2 drift = vec2(waveA * 0.65 + noise, waveB * 0.45 - noise * 0.65);
    return drift * vec2(1.0 / viewWidth, 1.0 / viewHeight) *
           (2.0 + distanceMask * 7.0) * UNDERWATER_DISTORTION * (0.55 + edge * 0.45);
}

vec3 sampleUnderwaterSoftScene(vec2 uv, float distanceMask) {
    float radius = UNDERWATER_BLUR_STRENGTH * (1.15 + distanceMask * 5.25);
    vec2 px = vec2(radius / viewWidth, radius / viewHeight);
    vec2 diag = px * 0.74;

    vec3 soft = texture2D(colortex0, uv).rgb * 0.28;
    soft += texture2D(colortex0, clamp(uv + vec2( px.x, 0.0), vec2(0.001), vec2(0.999))).rgb * 0.12;
    soft += texture2D(colortex0, clamp(uv + vec2(-px.x, 0.0), vec2(0.001), vec2(0.999))).rgb * 0.12;
    soft += texture2D(colortex0, clamp(uv + vec2(0.0,  px.y), vec2(0.001), vec2(0.999))).rgb * 0.12;
    soft += texture2D(colortex0, clamp(uv + vec2(0.0, -px.y), vec2(0.001), vec2(0.999))).rgb * 0.12;
    soft += texture2D(colortex0, clamp(uv + diag, vec2(0.001), vec2(0.999))).rgb * 0.06;
    soft += texture2D(colortex0, clamp(uv - diag, vec2(0.001), vec2(0.999))).rgb * 0.06;
    soft += texture2D(colortex0, clamp(uv + vec2(diag.x, -diag.y), vec2(0.001), vec2(0.999))).rgb * 0.06;
    soft += texture2D(colortex0, clamp(uv + vec2(-diag.x, diag.y), vec2(0.001), vec2(0.999))).rgb * 0.06;
    return soft;
}

vec3 applyUnderwaterView(vec3 color, vec2 uv, float depth) {
    if (isEyeInWater != 1) {
        return color;
    }

    float skyMask = step(0.999999, depth);
    float distanceMask = max(smoothstep(0.72, 0.9992, depth), skyMask);
    float edgeMilk = smoothstep(0.14, 0.84, length(uv - vec2(0.5)) * 1.45);
    float suspended = smoothstep(0.20, 0.86, texture2D(noisetex, uv * 2.0 + vec2(frameTimeCounter * 0.006, frameTimeCounter * -0.004)).r);

    vec2 warpedUv = clamp(uv + getUnderwaterFlowOffset(uv, distanceMask), vec2(0.001), vec2(0.999));
    vec3 blurred = sampleUnderwaterSoftScene(warpedUv, distanceMask);
    vec3 tint = vec3(0.52, 0.82, 1.08);
    blurred = mix(blurred, blurred * tint, clamp(UNDERWATER_TINT * 1.10, 0.0, 1.0));

    float blurMix = clamp(UNDERWATER_BLUR_STRENGTH * (0.18 + distanceMask * 0.58 + edgeMilk * 0.10), 0.0, 0.86);
    vec3 softened = mix(color, blurred, blurMix);

    float night = getNightExposureMask();
    float noon = getNoonExposureMask();
    vec3 shallowHaze = vec3(0.52, 0.82, 0.94);
    vec3 deepHaze = vec3(0.12, 0.34, 0.54);
    vec3 hazeColor = mix(shallowHaze, deepHaze, clamp(distanceMask * 0.82 + night * 0.22, 0.0, 1.0));
    hazeColor = mix(hazeColor, vec3(0.68, 0.91, 1.00), noon * 0.14);

    float haze = UNDERWATER_HAZE_STRENGTH * (0.20 + distanceMask * 0.78 + edgeMilk * 0.20);
    haze *= 0.92 + suspended * 0.18;
    haze = clamp(haze, 0.0, 0.88);

    vec3 milky = mix(max(softened, hazeColor * 0.08), hazeColor, haze);
    float clarityDrop = clamp(haze * 0.42 + UNDERWATER_BLUR_STRENGTH * 0.12, 0.0, 0.62);
    milky = saturateColor(milky, 1.0 - clarityDrop);
    milky = mix(milky, vec3(luma(milky)) * vec3(0.62, 0.84, 1.02), haze * 0.18);
    milky += vec3(0.02, 0.06, 0.10) * (0.08 + edgeMilk * 0.12 + suspended * 0.08) * UNDERWATER_HAZE_STRENGTH;
    return clamp(milky, 0.0, 1.0);
}

float skyHash21(vec2 p) {
    return fract(sin(dot(p, vec2(41.27, 289.53))) * 48371.5317);
}

vec3 getSkyDirection(vec2 uv) {
    vec4 clip = vec4(uv * 2.0 - 1.0, 1.0, 1.0);
    vec4 view = gbufferProjectionInverse * clip;
    view.xyz /= max(abs(view.w), 0.000001);
    vec3 viewDir = normalize(view.xyz);
    return normalize((gbufferModelViewInverse * vec4(viewDir, 0.0)).xyz);
}

vec2 getSkyUv(vec3 dir) {
    float yaw = atan(dir.z, dir.x) / 6.2831853 + 0.5;
    float pitch = asin(clamp(dir.y, -1.0, 1.0)) / 3.1415927 + 0.5;
    float celestialDrift = getTime01() * 0.12;
    return vec2(fract(yaw + celestialDrift), pitch);
}

float getStarLayer(vec2 skyUv, float scale, float threshold, float sizeBias) {
    vec2 p = skyUv * vec2(scale, scale * 0.58);
    vec2 cell = floor(p);
    vec2 local = fract(p) - 0.5;
    float seed = skyHash21(cell);
    float starPick = step(threshold, seed);
    float radius = mix(0.018, 0.052, skyHash21(cell + 17.31)) * sizeBias;
    float star = 1.0 - smoothstep(radius, radius * 2.4, length(local));
    float twinkle = 0.70 + 0.30 * sin(frameTimeCounter * mix(1.6, 4.8, seed) + seed * 6.2831853);
    return star * starPick * twinkle;
}

float getMilkyWayBand(vec2 skyUv) {
    vec2 p = skyUv - vec2(0.48, 0.56);
    p.x = fract(p.x + 0.5) - 0.5;

    float angle = -0.64;
    float c = cos(angle);
    float s = sin(angle);
    vec2 q = vec2(c * p.x - s * p.y, s * p.x + c * p.y);

    float waviness = sin(q.x * 9.0 + 0.6) * 0.030 + sin(q.x * 23.0) * 0.012;
    float bandDist = abs(q.y + waviness);
    float broad = 1.0 - smoothstep(0.12, 0.38, bandDist);
    float core = 1.0 - smoothstep(0.036, 0.130, bandDist);
    float dust = texture2D(noisetex, fract(q * vec2(1.8, 3.6) + vec2(0.18, 0.47))).r;
    float knots = texture2D(noisetex, fract(q * vec2(7.0, 12.0) + vec2(0.61, 0.12))).r;
    float darkRift = smoothstep(0.50, 0.84, dust) * (1.0 - smoothstep(0.012, 0.064, abs(q.y - waviness * 0.62)));
    return clamp((broad * 0.34 + core * (0.56 + knots * 0.28)) * (1.0 - darkRift * 0.58), 0.0, 1.0);
}

float getShootingStarLayer(vec2 skyUv, float period, vec2 salt) {
    float eventTime = frameTimeCounter / period;
    float event = floor(eventTime);
    float phase = fract(eventTime);
    float seed = skyHash21(vec2(event, period) + salt);

    vec2 head = vec2(0.10 + skyHash21(vec2(event, 1.7) + salt) * 0.80,
                     0.80 + skyHash21(vec2(event, 5.3) + salt) * 0.16);
    vec2 dir = normalize(vec2(0.66 + seed * 0.20, -0.36 - seed * 0.18));
    head += dir * (phase * 1.04);

    vec2 delta = skyUv - head;
    float behind = dot(delta, -dir);
    float cross = abs(dot(delta, vec2(-dir.y, dir.x)));
    float tail = (1.0 - smoothstep(0.000, 0.014, cross)) *
                 smoothstep(0.010, 0.040, behind) *
                 (1.0 - smoothstep(0.24, 0.46, behind));
    float headGlow = 1.0 - smoothstep(0.008, 0.042, length(delta));
    float life = smoothstep(0.02, 0.12, phase) * (1.0 - smoothstep(0.56, 0.82, phase));
    return (tail + headGlow * 0.70) * life;
}

vec3 applyNightSkyFeatures(vec3 color, vec2 uv, float depth) {
    if (depth < 0.999999 || isEyeInWater != 0) {
        return color;
    }

    vec3 skyDir = getSkyDirection(uv);
    float altitude = smoothstep(-0.02, 0.48, skyDir.y);
    float night = getSkyNightFeatureMask();
    float clearSky = 1.0 - getRainMood() * 0.86;
    float visibility = clamp(night * clearSky * altitude, 0.0, 1.0);
    if (visibility <= 0.001) {
        return color;
    }

    vec2 skyUv = getSkyUv(skyDir);
    float milky = getMilkyWayBand(skyUv) * SKY_MILKY_WAY_STRENGTH;
    float stars = getStarLayer(skyUv, 155.0, 0.980, 1.08);
    stars += getStarLayer(skyUv + vec2(0.37, 0.11), 92.0, 0.964, 1.30) * 0.72;
    stars *= SKY_STAR_STRENGTH;

    float shooting = getShootingStarLayer(skyUv, 4.8, vec2(0.0, 0.0));
    shooting += getShootingStarLayer(skyUv + vec2(0.31, 0.0), 8.6, vec2(19.2, 4.7)) * 0.72;
    shooting *= SKY_SHOOTING_STAR_STRENGTH;

    vec3 milkyColor = vec3(0.18, 0.24, 0.42) + vec3(0.20, 0.18, 0.28) * milky;
    vec3 starColor = vec3(0.74, 0.86, 1.00);
    vec3 meteorColor = vec3(0.92, 0.96, 1.00);
    vec3 skyGlow = milkyColor * milky + starColor * stars + meteorColor * shooting;
    return clamp(color + skyGlow * visibility, 0.0, 1.0);
}

void main() {
    vec4 source = texture2D(colortex0, texcoord);
    float depth = texture2D(depthtex0, texcoord).r;
    float waterMask = step(0.5, texture2D(colortex1, texcoord).r);
    vec3 color = source.rgb;

    color = applyCyberpunkGlassReflection(color, texcoord, depth, waterMask);
    color = applyVegetationColorLift(color);
    color = applyToneStyle(color);
    color = saturateColor(color, SATURATION);
    color = applyContrast(color, CONTRAST);
    color = liftHighlights(color, HIGHLIGHT_LIFT);
    color = applyPastelTone(color);
    color = applySummerBlueTone(color);
    color = applyPaleSurfaceRolloff(color, depth, waterMask);
    color = applyWaterDayPostRolloff(color, waterMask);
    color = applyResolvedWaterGeometryReflection(color, texcoord, depth, waterMask);

    float paleSurfaceMask = getPaleSurfaceMask(color, depth, waterMask);
    float bloomVisibility = getRainBloomVisibility();
    vec3 bloomColor = sampleBloom(texcoord) * bloomVisibility;
    bloomColor *= 1.0 - paleSurfaceMask * PALE_SURFACE_BLOOM_DAMPING;
    bloomColor *= 1.0 - clamp(waterMask * mix(0.12, WATER_DAY_BLOOM_DAMPING, getNoonExposureMask()), 0.0, 0.92);
    color = applyMaterialFinish(color, texcoord, depth, waterMask, bloomColor);
    color = applyColoredAmbientGlow(color, bloomColor);
    color = applyBloomGlobalIllumination(color, texcoord, depth, waterMask);
    color = applyPhysicalBloomComposite(color, bloomColor, texcoord, depth, waterMask);
    color = applyTimeExposureTone(color);
    color = applyBattlefieldThreePost(color, texcoord, depth, waterMask, bloomColor);
    color = applyRainGloomTone(color, depth, waterMask);
    color = applyPremiumImagePipeline(color, texcoord, depth, waterMask, bloomColor);
    color = applyWaterDayPostRolloff(color, waterMask);
    color = applyPrecisionLdrTone(color, texcoord, depth, waterMask);

    float edge = getSoftEdge(texcoord);
    vec3 ink = mix(vec3(0.055, 0.070, 0.095), color * 0.68, 0.42);
    color = mix(color, ink, edge * SOFT_EDGE_STRENGTH);
    color = applyUnderwaterView(color, texcoord, depth);
    color = applyNightSkyFeatures(color, texcoord, depth);

    color *= vignette(texcoord, VIGNETTE_STRENGTH);

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), source.a);
}
