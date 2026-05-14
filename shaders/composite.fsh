#version 120

/* DRAWBUFFERS:0 */
/*
const int colortex0Format = RGBA16;
const int colortex1Format = RGBA16;
const int colortex2Format = RGBA16;
const int colortex3Format = RGBA16;
const int colortex4Format = RGBA16;
*/

const int shadowMapResolution = 2048; // [1024 2048 4096]
const float shadowDistance = 96.0; // [48.0 96.0 128.0 160.0]
const float shadowIntervalSize = 3.0;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex0;
uniform sampler2D noisetex;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform int worldTime;
uniform int isEyeInWater;

varying vec2 texcoord;

#define DEBUG_VIEW 0 // [0 1 2 3 4 5 6 7 8 9 10 11]
#define SHADOW_STRENGTH 0.42 // [0.00 0.18 0.28 0.42 0.55 0.70]
#define SHADOW_SOFTNESS 1.20 // [0.50 0.75 1.20 1.80 2.60]
#define SHADOW_BIAS 0.0020 // [0.0010 0.0014 0.0020 0.0026 0.0032]
#define SHADOW_STABILITY 0.22
#define SUNLIGHT_TINT_STRENGTH 0.46 // [0.00 0.18 0.32 0.46 0.62 0.80]
#define SUNLIGHT_SATURATION 0.65 // [0.40 0.50 0.65 0.80 1.00]
#define SUNSET_WARMTH 0.78 // [0.00 0.35 0.55 0.78 0.95 1.15]
#define MOONLIGHT_TINT_STRENGTH 0.34 // [0.00 0.14 0.24 0.34 0.48 0.64]
#define TIME_LIGHT_EXPOSURE 1.00 // [0.82 0.92 1.00 1.08 1.16]
#define LDR_SCENE_WHITE 1.00 // [0.92 0.96 1.00]
#define WATER_REFLECTION_STRENGTH 0.92 // [0.00 0.20 0.34 0.58 0.70 0.76 0.92]
#define WATER_SURFACE_BRIGHTNESS 0.70 // [0.65 0.70 0.72 0.76 0.80]
#define WATER_SUNSET_TINT 0.72 // [0.00 0.35 0.55 0.72 0.92 1.00]
#define WATER_HORIZON_GLOW 0.52 // [0.00 0.18 0.28 0.52 0.78 1.00]
#define WATER_RIPPLE_STRENGTH 0.72 // [0.00 0.22 0.48 0.72 1.00]
#define WATER_WAVE_SPEED 0.72 // [0.20 0.40 0.58 0.72 0.90 1.15]
#define WATER_WAVE_SCALE 1.00 // [0.55 0.75 1.00 1.30 1.70]
#define WATER_REFLECTION_BLUR 0.85 // [0.50 0.85 1.25 1.80 2.50]
#define WATER_SSR_STRENGTH 1.00 // [0.00 0.30 0.52 0.74 0.88 1.00]
#define WATER_SSR_STEPS 32 // [8 12 18 24 32]
#define WATER_SSR_MAX_DISTANCE 64.0 // [18.0 28.0 42.0 64.0 96.0]
#define WATER_SSR_THICKNESS 1.20 // [0.20 0.35 0.55 0.80 1.20]
#define WATER_REFLECTION_FLOOR 0.34 // [0.00 0.16 0.26 0.34 0.46 0.60]
#define WATER_SKY_REFLECTION_BOOST 0.38 // [0.00 0.18 0.28 0.38 0.52 0.70]
#define WATER_DYNAMIC_REFLECTION_STRENGTH 1.00 // [0.00 0.30 0.52 0.72 0.88 1.00]
#define WATER_DYNAMIC_REFLECTION_DETAIL 0.90 // [0.00 0.24 0.46 0.62 0.74 0.90]
#define WATER_AMBIENT_REFLECTION_DAMPING 0.58 // [0.00 0.18 0.30 0.44 0.58 0.72]
#define WATER_SUN_SPECULAR_STRENGTH 1.28 // [0.40 0.72 1.00 1.28 1.60 2.00]
#define WATER_SUN_PATH_STRENGTH 0.46 // [0.00 0.18 0.32 0.46 0.64 0.86]
#define WATER_DISTANT_DETAIL_FADE 0.70 // [0.00 0.30 0.50 0.70 0.86 1.00]
#define WATER_DEPTH_CURVATURE 0.86 // [0.00 0.24 0.46 0.64 0.86 1.10]
#define WATER_DEPTH_ABSORPTION 0.48 // [0.00 0.20 0.34 0.48 0.62 0.78]
#define WATER_REFRACTION_DISTORTION 0.16 // [0.00 0.06 0.10 0.16 0.24 0.34]
#define WATER_SHORE_CLARITY 0.38 // [0.00 0.18 0.28 0.38 0.52 0.68]
#define WATER_SHORE_SAND_BLEND 0.24 // [0.00 0.10 0.18 0.24 0.34 0.46]
#define WATER_CAUSTICS_STRENGTH 0.14 // [0.00 0.06 0.10 0.14 0.22 0.32]
#define WATER_DEEP_REFLECTION_BOOST 0.72 // [0.00 0.22 0.42 0.58 0.72 0.92]
#define WATER_REFLECTION_CONTRAST 0.78 // [0.00 0.22 0.42 0.58 0.78 1.00]
#define WATER_DAY_REFLECTION_DAMPING 0.42 // [0.00 0.24 0.42 0.62 0.78 0.92]
#define WATER_DAY_HIGHLIGHT_ROLLOFF 0.46 // [0.00 0.28 0.46 0.62 0.78 0.92]
#define WATER_NOON_VISIBILITY_FLOOR 0.58 // [0.00 0.24 0.42 0.58 0.72 0.88]
#define WATER_SHADOW_SPARKLE_DAMPING 0.72 // [0.00 0.35 0.52 0.72 0.86 1.00]
#define RAIN_REFLECTION_STRENGTH 0.22 // [0.00 0.10 0.22 0.36 0.52]
#define RAIN_PUDDLE_COVERAGE 0.58 // [0.20 0.38 0.58 0.78 1.00]
#define RAIN_RIPPLE_STRENGTH 0.65 // [0.00 0.35 0.65 1.00]
#define RAIN_REFLECTION_FADE 0.62 // [0.35 0.50 0.62 0.78 0.92]
#define RAIN_SSR_STRENGTH 0.72 // [0.00 0.28 0.48 0.72 0.92 1.12]
#define RAIN_SSR_STEPS 18 // [6 10 14 18 24]
#define RAIN_SSR_MAX_DISTANCE 34.0 // [12.0 20.0 34.0 52.0 72.0]
#define RAIN_SSR_THICKNESS 0.78 // [0.24 0.42 0.60 0.78 1.10]
#define RAIN_CLOUD_OCCLUSION 0.82 // [0.00 0.35 0.58 0.82 1.00]
#define RAIN_DIRECT_LIGHT_DAMPING 0.86 // [0.00 0.35 0.58 0.72 0.86 1.00]
#define RAIN_SHADOW_SOFTENING 0.78 // [0.00 0.30 0.52 0.78 0.92 1.00]
#define RAIN_DIFFUSE_SKYLIGHT 0.22 // [0.00 0.10 0.16 0.22 0.32 0.44]
#define RAIN_OVERCAST_MIST 0.24 // [0.00 0.10 0.18 0.24 0.36 0.52]
#define RAIN_SUN_SPECULAR_DAMPING 0.86 // [0.00 0.35 0.58 0.72 0.86 1.00]
#define RAIN_SKY_DESATURATION 0.42 // [0.00 0.18 0.30 0.42 0.56 0.72]
#define SSAO_STRENGTH 0.34 // [0.00 0.18 0.26 0.34 0.46 0.60]
#define SSAO_RADIUS 4.50 // [2.00 3.00 4.50 6.00 8.00]
#define SSAO_BIAS 0.04 // [0.01 0.025 0.04 0.07 0.10]
#define SSAO_DEPTH_SCALE 1.20 // [0.60 0.90 1.20 1.60 2.20]
#define SSAO_STABLE_STRENGTH_CAP 0.24
#define SSAO_STABLE_RADIUS_CAP 3.20
#define SCREEN_GI_STRENGTH 0.14 // [0.00 0.06 0.10 0.14 0.22 0.34]
#define SCREEN_GI_RADIUS 10.0 // [4.0 7.0 10.0 14.0 20.0]
#define RT_LOCAL_LIGHT_STRENGTH 0.48 // [0.00 0.18 0.32 0.48 0.66 0.86]
#define RT_LOCAL_SHADOW_STRENGTH 0.08 // [0.00 0.06 0.08 0.12 0.22 0.32 0.46]
#define RT_LOCAL_SCREEN_RADIUS 112.0 // [48.0 72.0 96.0 112.0 144.0 192.0]
#define RT_LOCAL_MAX_DISTANCE 24.0 // [8.0 12.0 18.0 24.0 32.0 48.0]
#define RT_LOCAL_TRACE_STEPS 8 // [4 6 8 10 12]
#define RT_LOCAL_SAMPLE_QUALITY 2 // [1 2 3]
#define RT_LOCAL_SOURCE_THRESHOLD 0.66 // [0.44 0.54 0.66 0.78 0.88]
#define RT_LOCAL_WARMTH 0.82 // [0.00 0.35 0.58 0.82 1.00]
#define RT_LOCAL_NEON_STRENGTH 0.58 // [0.00 0.20 0.38 0.58 0.78 1.00]
#define RT_LOCAL_NEON_SPILL 0.34 // [0.00 0.16 0.26 0.34 0.48 0.64]
#define RT_BLOCKLIGHT_FIELD_STRENGTH 0.22 // [0.00 0.10 0.16 0.22 0.32 0.46]
#define RT_BLOCKLIGHT_FIELD_SHADOW 0.04 // [0.00 0.04 0.08 0.12 0.18 0.26]
#define RT_BLOCKLIGHT_FIELD_RADIUS 5.0 // [2.0 3.5 5.0 7.0 10.0]
#define RT_WEATHER_LOCAL_CONTRAST 0.16 // [0.00 0.08 0.16 0.24 0.36]
#define RT_LOCAL_SHADOW_STABLE_CAP 0.08
#define RT_BLOCKLIGHT_SHADOW_STABLE_CAP 0.04
#define VOLUMETRIC_FOG_STRENGTH 0.12 // [0.00 0.08 0.12 0.18 0.26 0.34 0.48]
#define VOLUMETRIC_FOG_DENSITY 0.006 // [0.004 0.006 0.010 0.014 0.018 0.026 0.036]
#define VOLUMETRIC_FOG_DISTANCE 116.0 // [48.0 76.0 92.0 116.0 144.0 180.0]
#define VOLUMETRIC_FOG_BLUE_TINT 0.12 // [0.00 0.12 0.24 0.26 0.34 0.48 0.64]
#define VOLUMETRIC_FOG_NOISE 0.18 // [0.00 0.10 0.18 0.28 0.40 0.56]
#define WEATHER_VOLUME_SCATTER 0.24 // [0.00 0.10 0.16 0.24 0.36 0.52]
#define FOG_SKY_WATER_BLEND 0.34 // [0.00 0.20 0.34 0.46 0.60 0.76]
#define FOG_GRAY_WALL_REDUCTION 0.72 // [0.00 0.24 0.40 0.56 0.72 0.90]
#define HORIZON_BLEND_STRENGTH 0.30 // [0.00 0.12 0.22 0.30 0.42 0.56]
#define HORIZON_BLEND_WIDTH 0.34 // [0.18 0.26 0.34 0.44 0.56]
#define HORIZON_WATER_MIST 0.28 // [0.00 0.10 0.18 0.28 0.40 0.54]
#define CLOUD_DEPTH_STRENGTH 0.32 // [0.00 0.14 0.24 0.32 0.44 0.58]
#define CLOUD_SHADOW_STRENGTH 0.28 // [0.00 0.12 0.20 0.28 0.40 0.54]
#define CLOUD_DENSITY_VARIATION 0.36 // [0.00 0.16 0.28 0.36 0.50 0.68]
#define CLOUD_SUN_SCATTER 0.30 // [0.00 0.12 0.22 0.30 0.42 0.58]
#define GODRAY_STRENGTH 0.38 // [0.00 0.16 0.26 0.38 0.54 0.72]
#define GODRAY_SUN_STRENGTH 0.50 // [0.00 0.20 0.35 0.50 0.70 0.90]
#define GODRAY_MOON_STRENGTH 0.34 // [0.00 0.14 0.24 0.34 0.50 0.70]
#define GODRAY_DECAY 0.76 // [0.55 0.66 0.76 0.84 0.90]
#define GODRAY_LENGTH 0.42 // [0.18 0.28 0.42 0.58 0.76]
#define GODRAY_BLUE_TINT 0.30 // [0.00 0.12 0.22 0.30 0.44 0.60]
#define RAIN_LIGHT_DAMPING 0.36 // [0.00 0.14 0.24 0.36 0.50 0.66]
#define RAIN_NIGHT_LIGHT_DAMPING 0.26 // [0.00 0.10 0.18 0.26 0.38 0.52]
#define RAIN_GODRAY_DAMPING 0.58 // [0.00 0.24 0.40 0.58 0.74 0.90]
#define SUN_HALO_STRENGTH 0.24 // [0.00 0.10 0.18 0.24 0.34 0.48]
#define SUN_HALO_RADIUS 0.34 // [0.18 0.26 0.34 0.46 0.60]
#define SUN_HAZE_SCATTER 0.20 // [0.00 0.08 0.14 0.20 0.30 0.42]
#define ATMOSPHERIC_PERSPECTIVE_STRENGTH 0.18 // [0.00 0.10 0.18 0.24 0.34 0.46]
#define ATMOSPHERIC_BLUE_SHIFT 0.12 // [0.00 0.12 0.22 0.30 0.44 0.60]
#define ATMOSPHERIC_SUN_GLOW 0.24 // [0.00 0.10 0.18 0.24 0.34 0.48]
#define MATERIAL_SPECULAR_STRENGTH 0.30 // [0.00 0.12 0.22 0.30 0.42 0.56]
#define MATERIAL_WET_SURFACE_BOOST 0.34 // [0.00 0.14 0.24 0.34 0.48 0.64]
#define MATERIAL_EMISSIVE_LIGHT 0.20 // [0.00 0.08 0.14 0.20 0.30 0.42]
#define MATERIAL_ROUGHNESS_RESPONSE 0.32 // [0.00 0.14 0.24 0.32 0.44 0.58]
#define LEAF_SSS_STRENGTH 0.26 // [0.00 0.12 0.18 0.26 0.38 0.52]
#define PBR_MATERIAL_AO_STRENGTH 0.58 // [0.00 0.30 0.46 0.58 0.72 0.90]
#define PBR_NORMAL_DETAIL_STRENGTH 0.52 // [0.00 0.24 0.38 0.52 0.68 0.84]
#define PBR_REFLECTANCE_RESPONSE 0.42 // [0.00 0.18 0.30 0.42 0.58 0.76]
#define PBR_HEIGHT_REFLECTION_WARP 0.18 // [0.00 0.08 0.14 0.18 0.26 0.36]
#define PBR_POROSITY_RAIN_DAMPING 0.34 // [0.00 0.16 0.24 0.34 0.48 0.66]
#define GLASS_REFLECTION_STRENGTH 0.18 // [0.00 0.08 0.12 0.18 0.28 0.40]
#define METAL_REFLECTION_STRENGTH 0.36 // [0.00 0.14 0.24 0.36 0.50 0.68]

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
    vec4 homPos = projectionMatrix * vec4(position, 1.0);
    return homPos.xyz / homPos.w;
}

vec3 getViewPosition(vec2 uv, float depth) {
    vec3 ndcPos = vec3(uv, depth) * 2.0 - 1.0;
    return projectAndDivide(gbufferProjectionInverse, ndcPos);
}

vec3 getPlayerPosition(vec2 uv, float depth) {
    vec3 viewPos = getViewPosition(uv, depth);
    return (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
}

vec3 getWorldPosition(vec2 uv, float depth) {
    return getPlayerPosition(uv, depth) + cameraPosition;
}

vec3 projectViewToScreen(vec3 viewPos) {
    vec3 ndcPos = projectAndDivide(gbufferProjection, viewPos);
    return vec3(ndcPos.xy * 0.5 + 0.5, ndcPos.z * 0.5 + 0.5);
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float maxComponent(vec3 color) {
    return max(max(color.r, color.g), color.b);
}

float minComponent(vec3 color) {
    return min(min(color.r, color.g), color.b);
}

float colorSaturation(vec3 color) {
    float mx = maxComponent(color);
    float mn = minComponent(color);
    return clamp((mx - mn) / max(mx, 0.001), 0.0, 1.0);
}

float getTime01() {
    return mod(float(worldTime), 24000.0) / 24000.0;
}

float getSunElevationCurve() {
    return sin(getTime01() * 6.2831853);
}

float getDayVisibility() {
    return smoothstep(-0.06, 0.18, getSunElevationCurve());
}

float getSunPresence() {
    return smoothstep(-0.18, 0.10, getSunElevationCurve());
}

float getNightVisibility() {
    return 1.0 - smoothstep(-0.10, 0.08, getSunElevationCurve());
}

float getHorizonSunWarmth() {
    float elevation = getSunElevationCurve();
    float lowSun = 1.0 - smoothstep(0.02, 0.55, abs(elevation));
    return clamp(lowSun * getSunPresence() * SUNSET_WARMTH, 0.0, 1.0);
}

float getRainAmount() {
    return clamp(max(rainStrength, wetness), 0.0, 1.0);
}

float getRainCloudOcclusion() {
    float rain = smoothstep(0.04, 0.92, getRainAmount());
    float cloudMass = rain * (0.78 + getSunPresence() * 0.10 + getHorizonSunWarmth() * 0.12);
    return clamp(cloudMass * RAIN_CLOUD_OCCLUSION, 0.0, 0.94);
}

float getDirectSunTransmission() {
    return clamp(1.0 - getRainCloudOcclusion() * RAIN_DIRECT_LIGHT_DAMPING, 0.06, 1.0);
}

float getWaterNoonMask() {
    return smoothstep(0.30, 0.96, max(getSunElevationCurve(), 0.0));
}

float getWaterAmbientVisibility() {
    float day = getDayVisibility();
    float sun = getSunPresence();
    float night = getNightVisibility();
    float horizon = getHorizonSunWarmth();
    float twilight = (1.0 - night) * (1.0 - getWaterNoonMask());
    float ambient = max(day * 0.72 + sun * 0.16, twilight * 0.52 + horizon * 0.22);
    ambient = mix(ambient, max(ambient, day * 0.48), getRainCloudOcclusion() * 0.38);
    return clamp(ambient, 0.0, 1.0);
}

vec3 applyWaterDayHighlightRolloff(vec3 color, float noonMask) {
    float noon = clamp(noonMask, 0.0, 1.0);
    float lum = luminance(color);
    float highlightOnly = smoothstep(0.42, 0.92, lum) * smoothstep(0.50, 1.00, max(max(color.r, color.g), color.b));
    float mask = clamp(noon * WATER_DAY_HIGHLIGHT_ROLLOFF * highlightOnly, 0.0, 0.82);
    vec3 compressed = color / (vec3(1.0) + color * (0.42 + noonMask * 1.10));
    vec3 balanced = vec3(luminance(compressed)) * vec3(0.74, 0.84, 1.00);
    compressed = mix(compressed, balanced, noon * 0.20);
    compressed = max(compressed, color * (0.86 + noon * 0.08));
    return mix(color, compressed, mask);
}

vec3 normalizeLightTint(vec3 color) {
    return color / max(luminance(color), 0.001);
}

vec3 getOvercastSkyTint() {
    vec3 dayOvercast = vec3(0.58, 0.68, 0.84);
    vec3 nightOvercast = vec3(0.30, 0.38, 0.58);
    return normalizeLightTint(mix(dayOvercast, nightOvercast, getNightVisibility()));
}

vec3 getPhysicalSunColor() {
    float elevation = getSunElevationCurve();
    float noon = smoothstep(0.30, 0.96, elevation);
    float horizon = getHorizonSunWarmth();

    vec3 noonWhite = vec3(1.00, 0.965, 0.875);
    vec3 lowGolden = vec3(1.00, 0.700, 0.390);
    vec3 deepSunset = vec3(1.00, 0.430, 0.205);
    vec3 daylight = mix(lowGolden, noonWhite, noon);
    daylight = mix(daylight, deepSunset, horizon);
    daylight = mix(vec3(luminance(daylight)), daylight, SUNLIGHT_SATURATION);

    vec3 moonlight = vec3(0.455, 0.560, 0.970);
    vec3 twilight = vec3(0.600, 0.700, 1.000);
    vec3 nightColor = mix(moonlight, twilight, 1.0 - getNightVisibility());

    return mix(nightColor, daylight, getSunPresence());
}

vec3 getPhysicalSunTint() {
    return normalizeLightTint(getPhysicalSunColor());
}

vec3 getTimeShadowTint() {
    vec3 dayShadow = vec3(0.880, 0.940, 1.050);
    vec3 nightShadow = vec3(0.540, 0.620, 1.080);
    vec3 sunsetShadow = vec3(0.760, 0.650, 0.980);
    vec3 shadowTint = mix(nightShadow, dayShadow, getDayVisibility());
    return normalizeLightTint(mix(shadowTint, sunsetShadow, getHorizonSunWarmth() * 0.45));
}

float screenEdgeFade(vec2 uv) {
    vec2 edge = min(uv, 1.0 - uv);
    return smoothstep(0.00, 0.075, min(edge.x, edge.y));
}

vec2 stabilizeShadowUv(vec2 uv) {
    float shadowRes = float(shadowMapResolution);
    vec2 texelCenter = (floor(uv * shadowRes) + vec2(0.5)) / shadowRes;
    return mix(uv, texelCenter, SHADOW_STABILITY);
}

float sampleShadow(vec3 shadowScreenPos, vec2 offset) {
    vec2 sampleUv = clamp(shadowScreenPos.xy + offset, vec2(0.001), vec2(0.999));
    float depth = texture2D(shadowtex0, sampleUv).r;
    float receiverDepth = shadowScreenPos.z - SHADOW_BIAS;
    float compareWidth = max(0.00025, (0.00030 + SHADOW_SOFTNESS * 0.00012) * (1.0 + SHADOW_STABILITY));
    return smoothstep(receiverDepth - compareWidth, receiverDepth + compareWidth, depth);
}

float sampleShadowPcf(vec3 shadowScreenPos, float texel) {
    float shadow = sampleShadow(shadowScreenPos, vec2(0.0));
    shadow += sampleShadow(shadowScreenPos, vec2( texel, 0.0)) * 0.86;
    shadow += sampleShadow(shadowScreenPos, vec2(-texel, 0.0)) * 0.86;
    shadow += sampleShadow(shadowScreenPos, vec2(0.0,  texel)) * 0.86;
    shadow += sampleShadow(shadowScreenPos, vec2(0.0, -texel)) * 0.86;
    shadow += sampleShadow(shadowScreenPos, vec2( texel,  texel)) * 0.62;
    shadow += sampleShadow(shadowScreenPos, vec2(-texel,  texel)) * 0.62;
    shadow += sampleShadow(shadowScreenPos, vec2( texel, -texel)) * 0.62;
    shadow += sampleShadow(shadowScreenPos, vec2(-texel, -texel)) * 0.62;

    vec2 wide = vec2(texel * 1.85, 0.0);
    shadow += sampleShadow(shadowScreenPos,  wide) * 0.30;
    shadow += sampleShadow(shadowScreenPos, -wide) * 0.30;
    shadow += sampleShadow(shadowScreenPos,  wide.yx) * 0.30;
    shadow += sampleShadow(shadowScreenPos, -wide.yx) * 0.30;
    return shadow / 8.12;
}

float getShadowFactor(vec2 uv, float depth) {
    if (depth >= 0.999999) {
        return 1.0;
    }

    vec3 feetPlayerPos = getPlayerPosition(uv, depth);
    vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
    vec3 shadowScreenPos = projectAndDivide(shadowProjection, shadowViewPos) * 0.5 + 0.5;

    if (shadowScreenPos.x <= 0.001 || shadowScreenPos.x >= 0.999 ||
        shadowScreenPos.y <= 0.001 || shadowScreenPos.y >= 0.999 ||
        shadowScreenPos.z <= 0.001 || shadowScreenPos.z >= 0.999) {
        return 1.0;
    }

    shadowScreenPos.xy = stabilizeShadowUv(shadowScreenPos.xy);
    float texel = SHADOW_SOFTNESS * (1.0 + getRainCloudOcclusion() * 1.65) / float(shadowMapResolution);
    float shadow = sampleShadowPcf(shadowScreenPos, texel);
    float effectiveShadowStrength = SHADOW_STRENGTH * (1.0 - getRainCloudOcclusion() * RAIN_SHADOW_SOFTENING);
    return mix(1.0 - effectiveShadowStrength, 1.0, shadow);
}

vec3 applyTimeOfDayLighting(vec3 color, vec2 uv, float depth) {
    if (depth >= 0.999999) {
        return color;
    }

    float rain = getRainAmount();
    float overcast = getRainCloudOcclusion();
    float directSun = getDirectSunTransmission();

    float shadowFactor = getShadowFactor(uv, depth);
    float litAmount = clamp((shadowFactor - (1.0 - SHADOW_STRENGTH)) / max(SHADOW_STRENGTH, 0.001), 0.0, 1.0);
    litAmount = mix(litAmount, 0.56, overcast * 0.74);
    shadowFactor = mix(shadowFactor, 0.94, overcast * RAIN_SHADOW_SOFTENING * 0.62);

    vec3 overcastTint = getOvercastSkyTint();
    vec3 sunTint = mix(getPhysicalSunTint(), overcastTint, overcast * 0.68);
    vec3 shadowTint = getTimeShadowTint();
    vec3 timeTint = mix(shadowTint, sunTint, litAmount);

    float day = getSunPresence();
    float tintStrength = mix(MOONLIGHT_TINT_STRENGTH, SUNLIGHT_TINT_STRENGTH * directSun, day);
    tintStrength = mix(tintStrength, max(tintStrength, SUNLIGHT_TINT_STRENGTH * 1.14 * directSun), getHorizonSunWarmth() * directSun);
    tintStrength *= 1.0 - overcast * 0.32;

    float night = getNightVisibility();
    vec3 rainLightTint = getOvercastSkyTint();
    timeTint = mix(timeTint, rainLightTint, clamp(rain * (0.22 + night * 0.16) + overcast * 0.42, 0.0, 0.82));

    float rainDim = 1.0 - rain * (RAIN_LIGHT_DAMPING * (0.62 + day * 0.28) + RAIN_NIGHT_LIGHT_DAMPING * night);
    rainDim = clamp(rainDim, 0.40, 1.0);

    vec3 result = color * shadowFactor * mix(vec3(1.0), timeTint, tintStrength) * TIME_LIGHT_EXPOSURE * rainDim;
    vec3 diffuseTarget = color * mix(vec3(1.0), rainLightTint, 0.30) * TIME_LIGHT_EXPOSURE * clamp(0.76 - rain * 0.12, 0.50, 1.0);
    return mix(result, max(result, diffuseTarget), overcast * RAIN_DIFFUSE_SKYLIGHT);
}

float puddleNoise(vec2 uv) {
    float slow = texture2D(noisetex, uv * 1.8 + vec2(0.0, frameTimeCounter * 0.012)).r;
    float fine = texture2D(noisetex, uv * 8.0 - vec2(frameTimeCounter * 0.015, 0.0)).g;
    return mix(slow, fine, 0.28);
}

vec3 sampleSoftReflection(vec2 uv, float blur) {
    vec2 px = vec2(blur / viewWidth, blur / viewHeight);
    vec3 reflected = texture2D(colortex0, uv).rgb * 0.42;
    reflected += texture2D(colortex0, uv + vec2( px.x, 0.0)).rgb * 0.16;
    reflected += texture2D(colortex0, uv + vec2(-px.x, 0.0)).rgb * 0.16;
    reflected += texture2D(colortex0, uv + vec2(0.0,  px.y)).rgb * 0.13;
    reflected += texture2D(colortex0, uv + vec2(0.0, -px.y)).rgb * 0.13;
    return reflected;
}

float getWaterSceneAmbient(vec2 uv, vec3 refractedScene) {
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec3 avg = refractedScene * 0.34;
    avg += texture2D(colortex0, clamp(uv + vec2( px.x * 10.0, 0.0), vec2(0.001), vec2(0.999))).rgb * 0.13;
    avg += texture2D(colortex0, clamp(uv + vec2(-px.x * 10.0, 0.0), vec2(0.001), vec2(0.999))).rgb * 0.13;
    avg += texture2D(colortex0, clamp(uv + vec2(0.0,  px.y * 8.0), vec2(0.001), vec2(0.999))).rgb * 0.18;
    avg += texture2D(colortex0, clamp(uv + vec2(0.0, -px.y * 8.0), vec2(0.001), vec2(0.999))).rgb * 0.12;
    avg += texture2D(colortex0, clamp(uv + vec2( px.x * 18.0,  px.y * 12.0), vec2(0.001), vec2(0.999))).rgb * 0.05;
    avg += texture2D(colortex0, clamp(uv + vec2(-px.x * 18.0,  px.y * 12.0), vec2(0.001), vec2(0.999))).rgb * 0.05;

    float sceneLum = clamp(luminance(avg), 0.0, 1.0);
    float timeAmbient = getWaterAmbientVisibility();
    float night = getNightVisibility();
    float sceneLift = smoothstep(0.10, 0.62, sceneLum) * (0.18 + timeAmbient * 0.32);
    sceneLift *= mix(0.32, 1.0, clamp(timeAmbient + (1.0 - night) * 0.35, 0.0, 1.0));
    return clamp(timeAmbient + sceneLift, 0.0, 1.0);
}

vec2 getWorldWaterSlope(vec2 worldXZ) {
    vec2 p = worldXZ * 0.052 * WATER_WAVE_SCALE;
    float t = frameTimeCounter * WATER_WAVE_SPEED;

    vec2 d0 = normalize(vec2(0.82, 0.24));
    vec2 d1 = normalize(vec2(-0.36, 0.93));
    vec2 d2 = normalize(vec2(0.55, -0.78));

    float w0 = dot(p, d0) * 7.0 + t * 1.35;
    float w1 = dot(p, d1) * 11.0 - t * 1.72;
    float w2 = dot(p, d2) * 17.0 + t * 2.10;

    vec2 slope = d0 * cos(w0) * 0.58;
    slope += d1 * cos(w1) * 0.34;
    slope += d2 * cos(w2) * 0.22;

    vec2 noiseCoord = p * 1.8 + vec2(t * 0.035, -t * 0.025);
    float n0 = texture2D(noisetex, noiseCoord).r - 0.5;
    float n1 = texture2D(noisetex, noiseCoord * 2.35 + vec2(0.21, 0.47)).g - 0.5;
    slope += vec2(n0, n1) * 0.62;

    return slope * WATER_RIPPLE_STRENGTH;
}

float getApparentWaterDepth(vec2 uv, float depth, vec3 waterColor) {
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    float floorDepth = texture2D(depthtex1, uv).r;
    vec3 waterViewPos = getViewPosition(uv, depth);
    vec3 floorViewPos = getViewPosition(uv, floorDepth);

    float waterLinear = -waterViewPos.z;
    float floorLinear = -floorViewPos.z;
    float physicalDepth = max(floorLinear - waterLinear, 0.0);
    float physicalMask = smoothstep(0.10, 7.50, physicalDepth);
    float validFloor = step(depth + 0.000001, floorDepth) * (1.0 - step(0.999999, floorDepth));

    float dR = texture2D(depthtex1, clamp(uv + vec2(px.x, 0.0) * 2.0, vec2(0.001), vec2(0.999))).r;
    float dL = texture2D(depthtex1, clamp(uv - vec2(px.x, 0.0) * 2.0, vec2(0.001), vec2(0.999))).r;
    float dU = texture2D(depthtex1, clamp(uv + vec2(0.0, px.y) * 2.0, vec2(0.001), vec2(0.999))).r;
    float dD = texture2D(depthtex1, clamp(uv - vec2(0.0, px.y) * 2.0, vec2(0.001), vec2(0.999))).r;

    float brightnessDepth = 1.0 - smoothstep(0.50, 0.88, luminance(waterColor));
    float distanceDepth = smoothstep(0.42, 0.98, depth);
    float basinShape = smoothstep(0.0008, 0.022, abs(dR - dL) + abs(dU - dD));
    float fallbackDepth = clamp(brightnessDepth * 0.42 + distanceDepth * 0.24 + basinShape * 0.34, 0.0, 1.0);
    return clamp(mix(fallbackDepth, max(physicalMask, basinShape * 0.45), validFloor), 0.0, 1.0);
}

float getPhysicalWaterDepth01(vec2 uv, float depth) {
    float floorDepth = texture2D(depthtex1, uv).r;
    vec3 waterViewPos = getViewPosition(uv, depth);
    vec3 floorViewPos = getViewPosition(uv, floorDepth);

    float waterLinear = -waterViewPos.z;
    float floorLinear = -floorViewPos.z;
    float physicalDepth = max(floorLinear - waterLinear, 0.0);
    float validFloor = step(depth + 0.000001, floorDepth) * (1.0 - step(0.999999, floorDepth));
    float distanceFallback = smoothstep(0.36, 0.96, depth) * 0.42;
    return mix(distanceFallback, smoothstep(0.08, 8.80, physicalDepth), validFloor);
}

vec2 getLayeredWaterCurvature(vec2 uv, vec2 worldXZ, float depthFactor) {
    float t = frameTimeCounter * WATER_WAVE_SPEED;
    vec2 p0 = worldXZ * (0.018 * WATER_WAVE_SCALE);
    vec2 p1 = worldXZ * (0.043 * WATER_WAVE_SCALE);
    vec2 p2 = worldXZ * (0.115 * WATER_WAVE_SCALE);

    vec2 broad = texture2D(noisetex, p0 + vec2( t * 0.010, -t * 0.007)).rg - vec2(0.5);
    vec2 mid = texture2D(noisetex, p1 + vec2(-t * 0.022,  t * 0.016)).gb - vec2(0.5);
    vec2 fine = texture2D(noisetex, p2 + vec2( t * 0.050,  t * 0.037)).br - vec2(0.5);

    vec2 d0 = normalize(vec2(0.72, 0.38));
    vec2 d1 = normalize(vec2(-0.30, 0.95));
    vec2 sheet = d0 * sin(dot(worldXZ, d0) * 0.090 + t * 1.25);
    sheet += d1 * cos(dot(worldXZ, d1) * 0.142 - t * 1.70);

    vec2 curvature = broad * 0.84 + mid * (0.58 + depthFactor * 0.42) + fine * depthFactor * 0.44;
    curvature += sheet * (0.16 + depthFactor * 0.30);
    return curvature * WATER_DEPTH_CURVATURE * (0.38 + depthFactor * 1.18);
}

vec3 getDynamicWaterEnvironmentReflection(vec3 worldPos, vec3 waterNormal, vec2 ripple, vec2 curvature, float waveBreakup, float depthFactor) {
    float t = frameTimeCounter * WATER_WAVE_SPEED;
    vec2 envUv = worldPos.xz * (0.010 * WATER_WAVE_SCALE) + ripple * 0.075 + curvature * 0.110;

    float broadCloud = texture2D(noisetex, envUv * 0.55 + vec2( t * 0.006, -t * 0.004)).r;
    float midCloud = texture2D(noisetex, envUv * 1.35 + vec2(-t * 0.013,  t * 0.008)).g;
    float fineCloud = texture2D(noisetex, envUv * 3.80 + vec2( t * 0.028,  t * 0.021)).b;
    float cloudField = broadCloud * 0.50 + midCloud * 0.38 + fineCloud * 0.12;
    float cloudMask = smoothstep(0.28, 0.70, cloudField) * (0.55 + WATER_DYNAMIC_REFLECTION_DETAIL * 0.55);
    float cloudEdge = smoothstep(0.46, 0.88, midCloud * 0.66 + fineCloud * 0.34) *
                      (1.0 - cloudMask * 0.20);

    float day = getSunPresence();
    float night = getNightVisibility();
    float noon = getWaterNoonMask();
    float dayDamp = 1.0 - noon * WATER_DAY_REFLECTION_DAMPING;
    float horizonWarmth = getHorizonSunWarmth();
    float rain = getRainAmount();
    float overcast = getRainCloudOcclusion();
    float directSun = getDirectSunTransmission();
    float ambientDay = getWaterAmbientVisibility();
    float waterNight = clamp(night * (1.0 - ambientDay * 0.82), 0.0, 1.0);

    vec3 daySky = mix(vec3(0.22, 0.46, 0.84), vec3(0.58, 0.76, 0.94), 0.36 + WATER_SUNSET_TINT * 0.12);
    vec3 nightSky = vec3(0.12, 0.18, 0.38);
    vec3 sky = mix(daySky, nightSky, waterNight * 0.92);
    sky = mix(sky, normalizeLightTint(getPhysicalSunColor()) * vec3(0.86, 0.80, 0.70), horizonWarmth * 0.24 * directSun);
    sky = mix(sky, vec3(luminance(sky)) * vec3(0.68, 0.82, 1.08), rain * RAIN_SKY_DESATURATION);
    sky *= (0.66 + ambientDay * 0.34) * (0.84 + dayDamp * 0.16);

    vec3 dayCloud = mix(vec3(0.62, 0.72, 0.88), vec3(0.96, 0.82, 0.62), horizonWarmth * 0.38);
    vec3 nightCloud = vec3(0.28, 0.34, 0.52);
    vec3 cloud = mix(dayCloud, nightCloud, waterNight);
    cloud = mix(cloud, getOvercastSkyTint() * vec3(0.56, 0.68, 0.92), overcast * 0.72);
    cloudMask = max(cloudMask, overcast * 0.54);
    vec3 reflected = mix(sky, cloud, cloudMask);
    reflected += cloud * cloudEdge * (0.07 + depthFactor * 0.06) * (0.62 + dayDamp * 0.22);
    reflected *= 1.0 - WATER_AMBIENT_REFLECTION_DAMPING * (0.38 + noon * 0.20 + rain * 0.10);

    vec3 sunDir = sunPosition / max(length(sunPosition), 0.001);
    vec3 moonDir = moonPosition / max(length(moonPosition), 0.001);
    vec3 sunPlayerDir = normalize((gbufferModelViewInverse * vec4(sunDir, 0.0)).xyz);
    vec3 moonPlayerDir = normalize((gbufferModelViewInverse * vec4(moonDir, 0.0)).xyz);
    vec3 lightDir = normalize(mix(moonPlayerDir, sunPlayerDir, day));
    float normalLight = clamp(dot(waterNormal, lightDir) * 0.5 + 0.5, 0.0, 1.0);
    vec3 viewDir = normalize(cameraPosition - worldPos);
    float sunSpec = pow(max(dot(reflect(-sunPlayerDir, waterNormal), viewDir), 0.0), 96.0 + depthFactor * 64.0);
    sunSpec *= day * directSun * (0.55 + horizonWarmth * 0.26) * screenEdgeFade(projectViewToScreen((gbufferModelView * vec4(worldPos - cameraPosition, 1.0)).xyz).xy);
    float streakNoise = texture2D(noisetex, envUv * 6.20 + curvature * 0.38 + vec2(t * 0.044, -t * 0.027)).r;
    float sheetLine = smoothstep(0.58, 0.96, abs(curvature.x - curvature.y) * 1.10 + fineCloud * 0.42);
    float glint = smoothstep(0.58, 0.98, waveBreakup * 0.42 + fineCloud * 0.24 + normalLight * 0.34);
    glint *= 0.70 + streakNoise * 0.76 + horizonWarmth * 0.34 + depthFactor * 0.32;
    glint *= 0.44 + dayDamp * 0.56;
    reflected += normalizeLightTint(getPhysicalSunColor()) * (sunSpec * WATER_SUN_SPECULAR_STRENGTH + glint * 0.22 * (1.0 - overcast * RAIN_SUN_SPECULAR_DAMPING * 0.52)) * WATER_DYNAMIC_REFLECTION_STRENGTH;
    reflected += vec3(0.66, 0.78, 0.98) * sheetLine * WATER_REFLECTION_CONTRAST * (0.035 + depthFactor * 0.055) * (0.58 + dayDamp * 0.24);

    float rippleEnergy = clamp(length(ripple) * 0.42, 0.0, 1.0);
    reflected *= 1.0 + WATER_REFLECTION_CONTRAST * (0.04 + depthFactor * WATER_DEEP_REFLECTION_BOOST * 0.08) * (0.62 + dayDamp * 0.22);
    reflected = mix(reflected, reflected * vec3(0.72, 0.90, 1.18), rippleEnergy * 0.18);
    reflected = mix(reflected, vec3(luminance(reflected)) * vec3(0.68, 0.78, 0.94), rain * 0.34);

    return applyWaterDayHighlightRolloff(reflected, noon * day);
}

vec3 estimateViewNormal(vec2 uv, float depth) {
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec3 center = getViewPosition(uv, depth);

    vec2 rightUv = clamp(uv + vec2(px.x, 0.0), vec2(0.001), vec2(0.999));
    vec2 upUv = clamp(uv + vec2(0.0, px.y), vec2(0.001), vec2(0.999));
    vec3 rightPos = getViewPosition(rightUv, texture2D(depthtex0, rightUv).r);
    vec3 upPos = getViewPosition(upUv, texture2D(depthtex0, upUv).r);

    vec3 normal = normalize(cross(rightPos - center, upPos - center));
    return normal.z > 0.0 ? -normal : normal;
}

vec2 getWorldRainSlope(vec2 worldXZ, float rain) {
    vec2 p = worldXZ * 0.076;
    float t = frameTimeCounter;

    float r0 = sin(dot(p, vec2(1.72, 0.34)) * 8.0 + t * 4.10);
    float r1 = cos(dot(p, vec2(-0.42, 1.38)) * 9.5 - t * 3.65);
    float r2 = sin(dot(p, vec2(0.82, -1.12)) * 13.0 + t * 5.35);

    vec2 noiseCoord = p * 1.9 + vec2(t * 0.018, -t * 0.014);
    vec2 n = texture2D(noisetex, noiseCoord).rg - vec2(0.5);

    vec2 slope = vec2(r0 + r2 * 0.32, r1 - r2 * 0.26) * 0.34 + n * 0.72;
    return slope * RAIN_RIPPLE_STRENGTH * rain;
}

vec4 traceRainSSR(vec2 uv, vec3 viewPos, vec3 viewNormal, vec2 ripple, float fresnel) {
    if (RAIN_SSR_STRENGTH <= 0.001) {
        return vec4(0.0);
    }

    vec3 viewDir = normalize(viewPos);
    vec3 rayDir = normalize(reflect(viewDir, viewNormal));

    if (abs(rayDir.z) < 0.010) {
        return vec4(0.0);
    }

    vec3 rayOrigin = viewPos + viewNormal * 0.06 + rayDir * 0.10;

    for (int i = 0; i < 24; i++) {
        if (i >= RAIN_SSR_STEPS) {
            break;
        }

        float stepRatio = (float(i) + 1.0) / float(RAIN_SSR_STEPS);
        float rayDistance = mix(0.16, RAIN_SSR_MAX_DISTANCE, stepRatio * stepRatio);
        vec3 rayPos = rayOrigin + rayDir * rayDistance;
        vec3 rayScreen = projectViewToScreen(rayPos);

        if (rayScreen.x <= 0.001 || rayScreen.x >= 0.999 ||
            rayScreen.y <= 0.001 || rayScreen.y >= 0.999 ||
            rayScreen.z <= 0.001 || rayScreen.z >= 0.999) {
            break;
        }

        float sceneDepth = texture2D(depthtex0, rayScreen.xy).r;
        if (sceneDepth >= 0.999999) {
            continue;
        }

        vec3 scenePos = getViewPosition(rayScreen.xy, sceneDepth);
        float rayLinearDepth = -rayPos.z;
        float sceneLinearDepth = -scenePos.z;
        float depthDelta = abs(rayLinearDepth - sceneLinearDepth);
        float thickness = RAIN_SSR_THICKNESS * (1.0 + sceneLinearDepth * 0.026);

        if (depthDelta < thickness) {
            vec2 hitUv = clamp(rayScreen.xy + ripple * vec2(0.0045, 0.0060), vec2(0.001), vec2(0.999));
            vec3 hitColor = texture2D(colortex0, hitUv).rgb * 0.70;
            hitColor += sampleSoftReflection(hitUv, WATER_REFLECTION_BLUR * 0.24) * 0.30;
            hitColor *= vec3(0.76, 0.86, 1.08);

            float hitFade = screenEdgeFade(rayScreen.xy);
            hitFade *= 1.0 - smoothstep(1.0, RAIN_SSR_MAX_DISTANCE, rayDistance);
            hitFade *= mix(0.44, 1.0, 1.0 - smoothstep(0.0, thickness, depthDelta));
            hitFade *= 0.56 + fresnel * 0.58;

            return vec4(hitColor, clamp(hitFade * RAIN_SSR_STRENGTH, 0.0, 1.0));
        }
    }

    return vec4(0.0);
}

float ssaoSample(vec3 center, vec2 uv, vec2 offset) {
    vec2 sampleUv = clamp(uv + offset, vec2(0.001), vec2(0.999));
    float sampleDepth = texture2D(depthtex0, sampleUv).r;

    if (sampleDepth >= 0.999999) {
        return 0.0;
    }

    vec3 samplePos = getViewPosition(sampleUv, sampleDepth);
    float depthDiff = samplePos.z - center.z;
    float occluder = smoothstep(SSAO_BIAS, SSAO_BIAS + 1.20, depthDiff);
    float range = 1.0 / (1.0 + abs(depthDiff) * SSAO_DEPTH_SCALE);
    float discontinuityFade = 1.0 - smoothstep(0.42, 1.35, abs(depthDiff));

    return occluder * range * discontinuityFade;
}

float getSSAO(vec2 uv, float depth, float waterMask) {
    if (depth >= 0.999999 || SSAO_STRENGTH <= 0.001) {
        return 1.0;
    }

    vec3 center = getViewPosition(uv, depth);
    float stableRadius = min(SSAO_RADIUS, SSAO_STABLE_RADIUS_CAP);
    float viewDepth = max(-center.z, 1.0);
    float distanceScale = clamp(5.0 / viewDepth, 0.40, 1.0);
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight) * stableRadius * distanceScale;

    float ao = 0.0;
    ao += ssaoSample(center, uv, vec2( px.x, 0.0));
    ao += ssaoSample(center, uv, vec2(-px.x, 0.0));
    ao += ssaoSample(center, uv, vec2(0.0,  px.y));
    ao += ssaoSample(center, uv, vec2(0.0, -px.y));
    ao += ssaoSample(center, uv, vec2( px.x,  px.y) * 0.75);
    ao += ssaoSample(center, uv, vec2(-px.x,  px.y) * 0.75);
    ao += ssaoSample(center, uv, vec2( px.x, -px.y) * 0.75);
    ao += ssaoSample(center, uv, vec2(-px.x, -px.y) * 0.75);
    ao += ssaoSample(center, uv, vec2( px.x, 0.0) * 1.65);
    ao += ssaoSample(center, uv, vec2(-px.x, 0.0) * 1.65);
    ao += ssaoSample(center, uv, vec2(0.0,  px.y) * 1.65);
    ao += ssaoSample(center, uv, vec2(0.0, -px.y) * 1.65);

    float stableStrength = min(SSAO_STRENGTH, SSAO_STABLE_STRENGTH_CAP);
    float visibility = 1.0 - clamp((ao / 12.0) * stableStrength * 1.55, 0.0, 0.32);
    return mix(visibility, 1.0, waterMask * 0.82);
}

float getExplicitGlassMaterial(vec4 material, vec4 extra, float waterMask) {
    float marker = smoothstep(0.66, 0.71, extra.b) * (1.0 - smoothstep(0.74, 0.82, extra.b));
    float smoothSurface = smoothstep(0.70, 0.86, material.g);
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

vec3 getMaterialClassDebug(vec4 material, vec4 extra, float waterMask) {
    float smoothness = clamp(material.g, 0.0, 1.0) * (1.0 - waterMask);
    float emission = clamp(material.b, 0.0, 1.0) * (1.0 - waterMask);
    float porosity = clamp(material.a, 0.0, 1.0) * (1.0 - waterMask);
    float reflectance = clamp(extra.r, 0.0, 1.0) * (1.0 - waterMask);
    float pbrPresence = clamp(extra.b, 0.0, 1.0) * (1.0 - waterMask);
    float upward = clamp(extra.a, 0.0, 1.0) * (1.0 - waterMask);
    float glassMaterial = getExplicitGlassMaterial(material, extra, waterMask);
    float metalMaterial = getExplicitMetalMaterial(material, extra, waterMask);
    float stoneMaterial = getExplicitStoneMaterial(material, extra, waterMask);
    float metalLike = max(metalMaterial, smoothstep(0.62, 0.92, reflectance) * smoothstep(0.42, 0.92, smoothness)) * (1.0 - glassMaterial);
    float emissive = smoothstep(0.10, 0.72, emission);
    float porous = smoothstep(0.16, 0.68, porosity) * (1.0 - waterMask);
    float pbrSurface = smoothstep(0.18, 0.92, pbrPresence) * (1.0 - glassMaterial);

    vec3 base = vec3(0.030, 0.035, 0.042);
    base = mix(base, vec3(0.00, 0.42, 1.00), waterMask);
    base = mix(base, vec3(0.72, 0.96, 1.00), glassMaterial);
    base = mix(base, vec3(0.44, 0.42, 0.38), stoneMaterial);
    base = mix(base, vec3(0.92, 0.24, 1.00), metalLike);
    base = mix(base, vec3(1.00, 0.58, 0.10), emissive);
    base = mix(base, vec3(0.48, 0.28, 0.10), porous * (1.0 - emissive));
    base = mix(base, vec3(0.26, 0.78, 0.32), pbrSurface * (1.0 - max(max(waterMask, glassMaterial), max(metalLike, emissive))));
    base += vec3(0.08, 0.10, 0.12) * upward;
    return clamp(base, 0.0, 1.0);
}

vec3 getMaterialDebugView(vec2 uv, float waterMask, int mode) {
    vec4 material = texture2D(colortex1, uv);
    vec4 normalData = texture2D(colortex2, uv);
    vec4 extra = texture2D(colortex3, uv);
    float notWater = 1.0 - waterMask;

    float blockLight = clamp((material.r / 0.46) * notWater, 0.0, 1.0);
    float smoothness = clamp(material.g, 0.0, 1.0) * notWater;
    float emission = clamp(material.b, 0.0, 1.0) * notWater;
    float porosity = clamp(material.a, 0.0, 1.0) * notWater;
    float reflectance = clamp(extra.r, 0.0, 1.0) * notWater;
    float height = clamp(extra.g, 0.0, 1.0) * notWater;
    float pbrPresence = clamp(extra.b, 0.0, 1.0) * notWater;
    float upward = clamp(extra.a, 0.0, 1.0) * notWater;
    float materialAo = clamp(normalData.a, 0.0, 1.0) * notWater + waterMask;
    float glassMaterial = getExplicitGlassMaterial(material, extra, waterMask);
    float metalMaterial = getExplicitMetalMaterial(material, extra, waterMask);
    float stoneMaterial = getExplicitStoneMaterial(material, extra, waterMask);

    if (mode == 5) {
        return getMaterialClassDebug(material, extra, waterMask);
    } else if (mode == 6) {
        return vec3(max(smoothness, metalMaterial), max(1.0 - smoothness, stoneMaterial), glassMaterial);
    } else if (mode == 7) {
        return vec3(reflectance, height, pbrPresence);
    } else if (mode == 8) {
        return vec3(blockLight, emission, porosity);
    } else if (mode == 9) {
        vec3 normal = normalize(normalData.rgb * 2.0 - 1.0);
        return mix(normal * 0.5 + 0.5, vec3(materialAo), 0.22);
    } else if (mode == 10) {
        return vec3(max(glassMaterial, metalMaterial * 0.72), max(upward, stoneMaterial * 0.72), waterMask);
    } else if (mode == 11) {
        vec3 normal = normalize(normalData.rgb * 2.0 - 1.0);
        float bumpVector = smoothstep(0.04, 0.42, length(normal.xy));
        float heightRelief = smoothstep(0.006, 0.080, abs(height - 0.5));
        float pbrSurface = smoothstep(0.84, 0.99, pbrPresence) * (1.0 - glassMaterial);
        return vec3(bumpVector, heightRelief, pbrSurface) * notWater;
    }

    return vec3(0.0);
}

float getFoliageSurfaceMask(vec3 baseColor, vec4 material, float waterMask) {
    float greenLead = smoothstep(0.02, 0.26, baseColor.g - max(baseColor.r * 0.92, baseColor.b));
    float naturalSaturation = smoothstep(0.10, 0.46, colorSaturation(baseColor));
    float visible = smoothstep(0.035, 0.42, luminance(baseColor));
    float notSmooth = 1.0 - smoothstep(0.52, 0.90, material.g);
    float porosityAssist = 0.62 + clamp(material.a, 0.0, 1.0) * 0.38;
    return clamp(greenLead * naturalSaturation * visible * notSmooth * porosityAssist * (1.0 - waterMask), 0.0, 1.0);
}

vec3 decodeStoredPbrNormal(vec2 uv, float depth, float waterMask) {
    vec3 estimated = estimateViewNormal(uv, depth);
    vec4 normalData = texture2D(colortex2, uv);
    vec4 extra = texture2D(colortex3, uv);
    vec4 material = texture2D(colortex1, uv);
    vec3 baseColor = texture2D(colortex0, uv).rgb;
    float pbrPresence = clamp(extra.b, 0.0, 1.0) * (1.0 - waterMask);
    float smoothness = clamp(material.g, 0.0, 1.0) * (1.0 - waterMask);
    float reflectance = clamp(extra.r, 0.0, 1.0);
    float metalLike = max(getExplicitMetalMaterial(material, extra, waterMask), smoothstep(0.72, 0.92, reflectance));
    float stoneMaterial = getExplicitStoneMaterial(material, extra, waterMask);
    float smoothSurface = smoothstep(0.66, 0.92, smoothness);
    float glassMaterial = getExplicitGlassMaterial(material, extra, waterMask);
    float foliageMaterial = getFoliageSurfaceMask(baseColor, material, waterMask);
    float detailStrength = PBR_NORMAL_DETAIL_STRENGTH * (1.0 - pbrPresence * smoothSurface * (0.35 + metalLike * 0.25));
    detailStrength *= 1.0 - glassMaterial * 0.72;
    detailStrength *= 1.0 - foliageMaterial * (0.58 + getNightVisibility() * 0.34);
    detailStrength = mix(detailStrength, detailStrength * 1.16, stoneMaterial);

    vec3 stored = normalize(normalData.rgb * 2.0 - 1.0);
    stored = dot(stored, estimated) < 0.0 ? -stored : stored;
    return normalize(mix(estimated, stored, pbrPresence * detailStrength));
}

float getPbrMaterialAO(vec2 uv, float waterMask) {
    vec4 normalData = texture2D(colortex2, uv);
    vec4 extra = texture2D(colortex3, uv);
    vec4 material = texture2D(colortex1, uv);
    float pbrPresence = clamp(extra.b, 0.0, 1.0) * (1.0 - waterMask);
    float stoneMaterial = getExplicitStoneMaterial(material, extra, waterMask);
    float materialAo = mix(1.0, clamp(normalData.a, 0.0, 1.0), pbrPresence * PBR_MATERIAL_AO_STRENGTH);
    return mix(materialAo, materialAo * 0.94, stoneMaterial);
}

float getAmbientOcclusion(vec2 uv, float depth, float waterMask) {
    if (waterMask > 0.001) {
        return 1.0;
    }

    return getSSAO(uv, depth, waterMask) *
           getPbrMaterialAO(uv, waterMask);
}

float sampleRtBlocker(vec3 rayPos, vec2 sampleUv) {
    sampleUv = clamp(sampleUv, vec2(0.001), vec2(0.999));
    float sceneDepth = texture2D(depthtex0, sampleUv).r;
    if (sceneDepth >= 0.999999) {
        return 0.0;
    }

    vec3 scenePos = getViewPosition(sampleUv, sceneDepth);
    float rayLinearDepth = -rayPos.z;
    float sceneLinearDepth = -scenePos.z;
    float depthDelta = rayLinearDepth - sceneLinearDepth;

    float blocker = smoothstep(0.050, 0.420, depthDelta);
    blocker *= 1.0 - smoothstep(1.60, 4.20, depthDelta);
    return blocker;
}

float sampleRtBlockerPcf(vec3 rayPos, vec2 rayUv) {
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight) * 1.5;
    float blocker = sampleRtBlocker(rayPos, rayUv) * 0.36;
    blocker += sampleRtBlocker(rayPos, rayUv + vec2( px.x, 0.0)) * 0.16;
    blocker += sampleRtBlocker(rayPos, rayUv + vec2(-px.x, 0.0)) * 0.16;
    blocker += sampleRtBlocker(rayPos, rayUv + vec2(0.0,  px.y)) * 0.16;
    blocker += sampleRtBlocker(rayPos, rayUv + vec2(0.0, -px.y)) * 0.16;
    return blocker;
}

float traceRtLocalVisibility(vec3 center, vec3 normal, vec3 lightPos) {
    vec3 origin = center + normal * 0.060;
    float visibility = 1.0;

    for (int i = 0; i < 12; i++) {
        if (i >= RT_LOCAL_TRACE_STEPS) {
            break;
        }

        float t = (float(i) + 1.0) / (float(RT_LOCAL_TRACE_STEPS) + 1.0);
        vec3 rayPos = mix(origin, lightPos, t);
        vec3 rayScreen = projectViewToScreen(rayPos);

        if (rayScreen.x <= 0.001 || rayScreen.x >= 0.999 ||
            rayScreen.y <= 0.001 || rayScreen.y >= 0.999 ||
            rayScreen.z <= 0.001 || rayScreen.z >= 0.999) {
            visibility *= 0.82;
            continue;
        }

        float blocker = sampleRtBlockerPcf(rayPos, rayScreen.xy);
        blocker *= screenEdgeFade(rayScreen.xy);
        visibility = min(visibility, 1.0 - blocker * 0.92);
    }

    return clamp(visibility, 0.0, 1.0);
}

float getRtWarmSourceMask(vec3 sourceColor) {
    float brightness = luminance(sourceColor);
    float warmLead = smoothstep(0.02, 0.24, sourceColor.r - max(sourceColor.g * 0.82, sourceColor.b * 1.20));
    float flameYellow = smoothstep(0.58, 1.18, sourceColor.r / max(sourceColor.g, 0.001)) *
                        smoothstep(0.10, 0.52, sourceColor.g - sourceColor.b);
    float visible = smoothstep(0.10, 0.86, brightness);
    return clamp(max(warmLead, flameYellow) * visible, 0.0, 1.0);
}

float getRtNeonSourceMask(vec3 sourceColor) {
    float brightness = luminance(sourceColor);
    float saturation = colorSaturation(sourceColor);
    float cyan = smoothstep(0.04, 0.28, sourceColor.g - sourceColor.r * 0.74) *
                 smoothstep(0.04, 0.28, sourceColor.b - sourceColor.r * 0.74);
    float blue = smoothstep(0.05, 0.30, sourceColor.b - max(sourceColor.r, sourceColor.g) * 0.82);
    float magenta = smoothstep(0.04, 0.28, sourceColor.r - sourceColor.g * 0.76) *
                    smoothstep(0.04, 0.28, sourceColor.b - sourceColor.g * 0.76);
    float neonHue = max(max(cyan, blue), magenta);
    float visible = smoothstep(0.09, 0.76, brightness) * smoothstep(0.12, 0.48, saturation);
    return clamp(neonHue * visible, 0.0, 1.0);
}

vec3 getRtCyberTint(vec3 sourceColor, float warmSource, float neonSource) {
    vec3 warmTint = normalizeLightTint(mix(sourceColor, vec3(1.00, 0.58, 0.22), RT_LOCAL_WARMTH));
    vec3 neonBase = sourceColor;
    float cyanBias = smoothstep(0.04, 0.28, min(sourceColor.g, sourceColor.b) - sourceColor.r * 0.72);
    float magentaBias = smoothstep(0.04, 0.28, min(sourceColor.r, sourceColor.b) - sourceColor.g * 0.72);
    neonBase = mix(neonBase, sourceColor * vec3(0.74, 1.10, 1.28), cyanBias * 0.44);
    neonBase = mix(neonBase, sourceColor * vec3(1.22, 0.62, 1.18), magentaBias * 0.36);
    vec3 neonTint = normalizeLightTint(max(neonBase, vec3(luminance(sourceColor)) * vec3(0.36, 0.70, 1.12)));
    float neonBlend = clamp(neonSource * RT_LOCAL_NEON_STRENGTH * (0.42 + colorSaturation(sourceColor) * 0.58), 0.0, 1.0);
    neonBlend *= 1.0 - warmSource * 0.38;
    return normalizeLightTint(mix(warmTint, neonTint, neonBlend));
}

float getEncodedBlockLight(vec2 uv) {
    vec4 material = texture2D(colortex1, clamp(uv, vec2(0.001), vec2(0.999)));
    float notWater = 1.0 - step(0.5, material.r);
    return clamp((material.r / 0.46) * notWater, 0.0, 1.0);
}

vec4 getRtBlockLightField(vec2 uv, float depth, float waterMask) {
    if (RT_BLOCKLIGHT_FIELD_STRENGTH <= 0.001 || depth >= 0.999999 || isEyeInWater != 0 || waterMask > 0.001) {
        return vec4(0.0);
    }

    vec3 center = getViewPosition(uv, depth);
    vec3 normal = decodeStoredPbrNormal(uv, depth, waterMask);
    vec2 px = vec2(RT_BLOCKLIGHT_FIELD_RADIUS / viewWidth, RT_BLOCKLIGHT_FIELD_RADIUS / viewHeight);

    float c = getEncodedBlockLight(uv);
    float r = getEncodedBlockLight(uv + vec2( px.x, 0.0));
    float l = getEncodedBlockLight(uv + vec2(-px.x, 0.0));
    float u = getEncodedBlockLight(uv + vec2(0.0,  px.y));
    float d = getEncodedBlockLight(uv + vec2(0.0, -px.y));
    float ru = getEncodedBlockLight(uv + vec2( px.x,  px.y) * 0.72);
    float lu = getEncodedBlockLight(uv + vec2(-px.x,  px.y) * 0.72);
    float rd = getEncodedBlockLight(uv + vec2( px.x, -px.y) * 0.72);
    float ld = getEncodedBlockLight(uv + vec2(-px.x, -px.y) * 0.72);

    float nearAverage = (r + l + u + d + ru + lu + rd + ld) * 0.125;
    float maxNeighbor = max(max(max(r, l), max(u, d)), max(max(ru, lu), max(rd, ld)));
    vec2 gradient = vec2(r - l + (ru + rd - lu - ld) * 0.35,
                         u - d + (ru + lu - rd - ld) * 0.35);
    float gradientEnergy = clamp(length(gradient) * 1.65, 0.0, 1.0);

    float field = smoothstep(0.10, 0.82, max(c, nearAverage * 0.72));
    float receiver = smoothstep(0.03, 0.44, c);
    float normalCatch = 0.62 + clamp(normal.y * 0.22 + abs(normal.z) * 0.16, 0.0, 0.34);
    float distanceDamp = 1.0 / (1.0 + length(center) * 0.018);
    vec3 warmField = vec3(1.00, 0.55, 0.23) * field * receiver * normalCatch * distanceDamp * RT_BLOCKLIGHT_FIELD_STRENGTH;

    float edgeBlock = smoothstep(0.12, 0.48, maxNeighbor - c) * gradientEnergy * receiver;
    float shadow = edgeBlock * min(RT_BLOCKLIGHT_FIELD_SHADOW, RT_BLOCKLIGHT_SHADOW_STABLE_CAP);
    return vec4(warmField, shadow);
}

vec4 sampleRtLocalLight(vec2 uv, vec3 center, vec3 normal, vec2 offset, float weight) {
    vec2 sourceUv = clamp(uv + offset, vec2(0.001), vec2(0.999));
    float sourceDepth = texture2D(depthtex0, sourceUv).r;
    if (sourceDepth >= 0.999999) {
        return vec4(0.0);
    }

    vec4 sourceMaterial = texture2D(colortex1, sourceUv);
    vec3 sourceColor = texture2D(colortex0, sourceUv).rgb;
    float emission = clamp(sourceMaterial.b, 0.0, 1.0);
    float warmSource = getRtWarmSourceMask(sourceColor);
    float neonSource = getRtNeonSourceMask(sourceColor);
    float sourceMask = max(warmSource, neonSource * RT_LOCAL_NEON_STRENGTH);
    float neonThreshold = max(0.36, RT_LOCAL_SOURCE_THRESHOLD - 0.14 * RT_LOCAL_NEON_STRENGTH);
    float threshold = mix(RT_LOCAL_SOURCE_THRESHOLD, neonThreshold, clamp(neonSource * RT_LOCAL_NEON_STRENGTH, 0.0, 1.0));
    float sourceEnergy = smoothstep(threshold, 1.0, emission) * sourceMask * weight;
    if (sourceEnergy <= 0.0001) {
        return vec4(0.0);
    }

    vec3 lightPos = getViewPosition(sourceUv, sourceDepth);
    vec3 toLight = lightPos - center;
    float distanceToLight = length(toLight);
    if (distanceToLight <= 0.050 || distanceToLight >= RT_LOCAL_MAX_DISTANCE) {
        return vec4(0.0);
    }

    vec3 lightDir = toLight / distanceToLight;
    float facing = smoothstep(-0.08, 0.42, dot(normal, lightDir));
    float range = 1.0 / (1.0 + distanceToLight * distanceToLight * 0.075);
    range *= 1.0 - smoothstep(RT_LOCAL_MAX_DISTANCE * 0.58, RT_LOCAL_MAX_DISTANCE, distanceToLight);
    range *= screenEdgeFade(sourceUv);

    float visibility = traceRtLocalVisibility(center, normal, lightPos);
    vec3 torchTint = getRtCyberTint(sourceColor, warmSource, neonSource);
    float energy = sourceEnergy * facing * range;
    float neonBoost = 1.0 + neonSource * RT_LOCAL_NEON_STRENGTH * RT_LOCAL_NEON_SPILL;
    vec3 light = torchTint * energy * visibility * RT_LOCAL_LIGHT_STRENGTH * neonBoost;
    float shadowSource = smoothstep(0.26, 0.78, sourceEnergy);
    float blockedShadow = energy * shadowSource * (1.0 - visibility) * (1.0 - neonSource * 0.24);

    return vec4(light, blockedShadow);
}

vec4 getRtLocalLighting(vec2 uv, float depth, float waterMask) {
    if (RT_LOCAL_LIGHT_STRENGTH <= 0.001 || depth >= 0.999999 || isEyeInWater != 0) {
        return vec4(0.0);
    }

    vec3 center = getViewPosition(uv, depth);
    vec3 normal = decodeStoredPbrNormal(uv, depth, waterMask);
    vec2 px = vec2(RT_LOCAL_SCREEN_RADIUS / viewWidth, RT_LOCAL_SCREEN_RADIUS / viewHeight);

    vec4 light = vec4(0.0);
    light += sampleRtLocalLight(uv, center, normal, vec2( 1.000,  0.000) * px * 0.42, 1.00);
    light += sampleRtLocalLight(uv, center, normal, vec2(-1.000,  0.000) * px * 0.42, 1.00);
    light += sampleRtLocalLight(uv, center, normal, vec2( 0.000,  1.000) * px * 0.42, 0.94);
    light += sampleRtLocalLight(uv, center, normal, vec2( 0.000, -1.000) * px * 0.42, 0.94);
#if RT_LOCAL_SAMPLE_QUALITY >= 2
    light += sampleRtLocalLight(uv, center, normal, vec2( 0.707,  0.707) * px * 0.62, 0.82);
    light += sampleRtLocalLight(uv, center, normal, vec2(-0.707,  0.707) * px * 0.62, 0.82);
    light += sampleRtLocalLight(uv, center, normal, vec2( 0.707, -0.707) * px * 0.62, 0.82);
    light += sampleRtLocalLight(uv, center, normal, vec2(-0.707, -0.707) * px * 0.62, 0.82);
#endif
#if RT_LOCAL_SAMPLE_QUALITY >= 3
    light += sampleRtLocalLight(uv, center, normal, vec2( 0.940,  0.342) * px, 0.56);
    light += sampleRtLocalLight(uv, center, normal, vec2(-0.342,  0.940) * px, 0.56);
    light += sampleRtLocalLight(uv, center, normal, vec2(-0.940, -0.342) * px, 0.56);
    light += sampleRtLocalLight(uv, center, normal, vec2( 0.342, -0.940) * px, 0.56);
#endif

    return light;
}

vec3 applyRtLocalEmissionLight(vec3 color, vec2 uv, float depth, float waterMask) {
    vec4 localLight = getRtLocalLighting(uv, depth, waterMask);
    vec4 blockField = getRtBlockLightField(uv, depth, waterMask);
    float weatherContrast = 1.0 + getRainCloudOcclusion() * RT_WEATHER_LOCAL_CONTRAST;
    float localShadowStrength = min(RT_LOCAL_SHADOW_STRENGTH, RT_LOCAL_SHADOW_STABLE_CAP);
    float shadow = clamp(localLight.a * localShadowStrength + blockField.a, 0.0, 0.32);
    shadow *= mix(1.0, 0.40, waterMask);

    vec3 shadowed = color * (1.0 - shadow);
    color = mix(color, shadowed, smoothstep(0.006, 0.12, localLight.a + blockField.a));
    color += localLight.rgb * (0.68 + (1.0 - luminance(color)) * 0.42) * weatherContrast;
    color += blockField.rgb * (0.42 + (1.0 - luminance(color)) * 0.24) * weatherContrast;
    return color;
}

vec4 sampleScreenGiTap(vec2 uv, vec3 center, vec3 normal, vec2 offset, float weight) {
    vec2 sampleUv = clamp(uv + offset, vec2(0.001), vec2(0.999));
    float sampleDepth = texture2D(depthtex0, sampleUv).r;
    if (sampleDepth >= 0.999999) {
        return vec4(0.0);
    }

    vec3 samplePos = getViewPosition(sampleUv, sampleDepth);
    vec3 delta = samplePos - center;
    float distanceToSample = length(delta);
    if (distanceToSample <= 0.025) {
        return vec4(0.0);
    }

    vec3 sampleDir = delta / distanceToSample;
    float normalCatch = smoothstep(-0.18, 0.48, dot(normal, sampleDir));
    float range = 1.0 / (1.0 + distanceToSample * distanceToSample * 0.055);
    float depthCoherence = 1.0 - smoothstep(18.0, 62.0, distanceToSample);
    float contribution = weight * normalCatch * range * depthCoherence;

    vec3 sampleColor = texture2D(colortex0, sampleUv).rgb;
    float colorEnergy = clamp(luminance(sampleColor) * 1.20 + colorSaturation(sampleColor) * 0.28, 0.0, 1.0);
    return vec4(sampleColor * contribution * (0.35 + colorEnergy * 0.65), contribution);
}

vec3 applyScreenSpaceGlobalIllumination(vec3 color, vec2 uv, float depth, float waterMask) {
    if (SCREEN_GI_STRENGTH <= 0.001 || depth >= 0.999999 || isEyeInWater != 0) {
        return color;
    }

    vec3 center = getViewPosition(uv, depth);
    vec3 normal = decodeStoredPbrNormal(uv, depth, waterMask);
    vec2 px = vec2(SCREEN_GI_RADIUS / viewWidth, SCREEN_GI_RADIUS / viewHeight);
    vec2 normalBias = normal.xy * px * 0.42;

    vec4 gi = vec4(0.0);
    gi += sampleScreenGiTap(uv, center, normal, normalBias + vec2( 1.00,  0.00) * px * 0.62, 1.00);
    gi += sampleScreenGiTap(uv, center, normal, normalBias + vec2(-1.00,  0.00) * px * 0.62, 1.00);
    gi += sampleScreenGiTap(uv, center, normal, normalBias + vec2( 0.00,  1.00) * px * 0.62, 0.92);
    gi += sampleScreenGiTap(uv, center, normal, normalBias + vec2( 0.00, -1.00) * px * 0.62, 0.92);
    gi += sampleScreenGiTap(uv, center, normal, normalBias + vec2( 0.71,  0.71) * px * 0.92, 0.72);
    gi += sampleScreenGiTap(uv, center, normal, normalBias + vec2(-0.71,  0.71) * px * 0.92, 0.72);
    gi += sampleScreenGiTap(uv, center, normal, normalBias + vec2( 0.71, -0.71) * px * 0.92, 0.72);
    gi += sampleScreenGiTap(uv, center, normal, normalBias + vec2(-0.71, -0.71) * px * 0.92, 0.72);

    if (gi.a <= 0.001) {
        return color;
    }

    vec3 bounce = gi.rgb / gi.a;
    vec3 neutralBounce = vec3(luminance(bounce));
    vec3 coloredBounce = mix(neutralBounce, bounce, 0.72);
    float receiver = smoothstep(0.03, 0.62, luminance(color)) * (1.0 - smoothstep(0.82, 1.12, maxComponent(color)));
    receiver *= 1.0 - waterMask * 0.48;
    vec3 lifted = color + coloredBounce * (SCREEN_GI_STRENGTH * receiver * (0.22 + gi.a * 0.10));
    return mix(color, max(color, lifted), clamp(SCREEN_GI_STRENGTH * (0.42 + gi.a * 0.16), 0.0, 0.36));
}

float getFoliageSssMask(vec3 baseColor, vec4 material, float waterMask) {
    return getFoliageSurfaceMask(baseColor, material, waterMask);
}

vec3 applyLeafSubsurfaceScattering(vec3 color, vec2 uv, float depth, float waterMask) {
    if (LEAF_SSS_STRENGTH <= 0.001 || depth >= 0.999999 || isEyeInWater != 0) {
        return color;
    }

    vec4 material = texture2D(colortex1, uv);
    vec3 baseColor = texture2D(colortex0, uv).rgb;
    float foliage = getFoliageSssMask(baseColor, material, waterMask);
    if (foliage <= 0.001) {
        return color;
    }

    vec3 viewNormal = decodeStoredPbrNormal(uv, depth, waterMask);
    vec3 lightDir = normalize(mix(moonPosition, sunPosition, getSunPresence()));
    float backLight = smoothstep(-0.18, 0.62, dot(-viewNormal, lightDir));
    float horizonWarmth = getHorizonSunWarmth();
    float weatherSoft = 1.0 - getRainCloudOcclusion() * 0.38;
    vec3 leafTint = mix(vec3(0.42, 0.74, 0.30), vec3(0.92, 0.72, 0.34), horizonWarmth * 0.52);
    leafTint = mix(leafTint, getOvercastSkyTint() * vec3(0.70, 0.86, 0.58), getRainAmount() * 0.22);

    float sss = foliage * backLight * LEAF_SSS_STRENGTH * weatherSoft;
    sss *= 0.42 + getSunPresence() * 0.58;
    vec3 glowBase = max(color, vec3(luminance(color)) * leafTint);
    vec3 glow = glowBase + leafTint * (0.018 + luminance(baseColor) * 0.075) * sss;
    return mix(color, glow, clamp(sss, 0.0, 0.58));
}

vec3 applyMaterialSurfaceResponse(vec3 color, vec2 uv, float depth, float waterMask) {
    if (depth >= 0.999999 || isEyeInWater != 0) {
        return color;
    }

    vec4 material = texture2D(colortex1, uv);
    vec4 pbrExtra = texture2D(colortex3, uv);
    vec3 baseColor = texture2D(colortex0, uv).rgb;
    float smoothness = clamp(material.g, 0.0, 1.0) * (1.0 - waterMask);
    float emission = clamp(material.b, 0.0, 1.0) * (1.0 - waterMask);
    float porosity = clamp(material.a, 0.0, 1.0) * (1.0 - waterMask);
    float reflectance = clamp(pbrExtra.r, 0.0, 1.0);
    float height = clamp(pbrExtra.g, 0.0, 1.0);
    float pbrPresence = clamp(pbrExtra.b, 0.0, 1.0) * (1.0 - waterMask);
    float upward = clamp(pbrExtra.a, 0.0, 1.0) * (1.0 - waterMask);
    float rain = getRainAmount();
    float overcast = getRainCloudOcclusion();
    float night = getNightVisibility();
    float glassMaterial = getExplicitGlassMaterial(material, pbrExtra, waterMask);
    float metalMaterial = getExplicitMetalMaterial(material, pbrExtra, waterMask);
    float stoneMaterial = getExplicitStoneMaterial(material, pbrExtra, waterMask);
    float foliageMaterial = getFoliageSurfaceMask(baseColor, material, waterMask);

    if (smoothness <= 0.001 && emission <= 0.001 && rain <= 0.001) {
        return color;
    }

    vec3 viewPos = getViewPosition(uv, depth);
    vec3 viewNormal = decodeStoredPbrNormal(uv, depth, waterMask);
    float facing = clamp(dot(viewNormal, normalize(-viewPos)), 0.0, 1.0);
    float fresnel = pow(1.0 - facing, 2.35);

    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    float metalLike = smoothstep(0.72, 0.92, reflectance);
    metalLike = max(metalLike, metalMaterial);
    metalLike *= 1.0 - glassMaterial;
    float glassLike = smoothstep(0.66, 0.92, smoothness) * (1.0 - metalLike) * (1.0 - stoneMaterial * 0.86) * (1.0 - porosity);
    glassLike = max(glassLike, glassMaterial);
    float reliefStability = 1.0 - clamp(glassLike * 0.72 + metalLike * 0.62, 0.0, 0.86);
    reliefStability = mix(reliefStability, max(reliefStability, 0.82), stoneMaterial);
    float heightRelief = abs(height - 0.5) * pbrPresence * reliefStability;
    vec2 reflectOffset = viewNormal.xy * px * (1.4 + smoothness * 4.6 + rain * upward * 3.6 + heightRelief * PBR_HEIGHT_REFLECTION_WARP * 8.0);
    reflectOffset *= mix(1.0, 0.16, glassMaterial);
    reflectOffset *= mix(1.0, 0.34, metalMaterial);
    reflectOffset *= mix(1.0, 1.26, stoneMaterial);
    float reflectionBlur = WATER_REFLECTION_BLUR * mix(0.20 + smoothness * 0.36, 0.055 + GLASS_REFLECTION_STRENGTH * 0.12, glassMaterial);
    reflectionBlur = mix(reflectionBlur, max(reflectionBlur, WATER_REFLECTION_BLUR * 0.42), stoneMaterial);
    reflectionBlur = mix(reflectionBlur, min(reflectionBlur, WATER_REFLECTION_BLUR * 0.18), metalMaterial);
    vec3 softReflection = sampleSoftReflection(uv + reflectOffset, reflectionBlur);

    float f0Boost = mix(0.62, 1.82, reflectance) * (1.0 + pbrPresence * PBR_REFLECTANCE_RESPONSE * 0.34);
    f0Boost = mix(f0Boost, f0Boost * 0.38, stoneMaterial);
    f0Boost = mix(f0Boost, max(f0Boost, 1.86), metalMaterial);
    float impermeable = 1.0 - porosity;
    float drySpec = smoothness * MATERIAL_SPECULAR_STRENGTH * (0.20 + fresnel * 1.30) * f0Boost;
    drySpec = mix(drySpec, smoothness * GLASS_REFLECTION_STRENGTH * (0.10 + fresnel * 0.72), glassMaterial);
    drySpec = mix(drySpec, drySpec * 0.36, stoneMaterial);
    drySpec = max(drySpec, metalMaterial * METAL_REFLECTION_STRENGTH * (0.18 + fresnel * 0.92) * (0.44 + smoothness * 0.56));
    drySpec *= 1.0 - foliageMaterial * (0.68 + night * 0.26);
    float wetSpec = rain * upward * MATERIAL_WET_SURFACE_BOOST * (0.24 + fresnel * 1.12) * (0.30 + impermeable * 0.90) * (1.0 + overcast * 0.18);
    wetSpec *= 1.0 - glassMaterial * 0.82;
    wetSpec *= 1.0 - stoneMaterial * 0.28;
    wetSpec *= 1.0 - foliageMaterial * 0.44;
    float specMask = clamp((drySpec + wetSpec) * (1.0 - waterMask), 0.0, 0.76);

    float porousWetDarkening = rain * upward * porosity * PBR_POROSITY_RAIN_DAMPING;
    vec3 roughDamped = mix(color, vec3(luminance(color)) * vec3(0.78, 0.84, 0.94), porousWetDarkening * MATERIAL_ROUGHNESS_RESPONSE);
    roughDamped = mix(roughDamped, roughDamped * vec3(0.92, 0.94, 0.98), stoneMaterial * (0.18 + porosity * 0.22 + rain * 0.12));
    vec3 glossyTarget = max(roughDamped, softReflection * (0.66 + smoothness * 0.34 + rain * upward * 0.22));
    glossyTarget = mix(glossyTarget, max(roughDamped, softReflection * vec3(0.72, 0.78, 0.86)), stoneMaterial * 0.84);
    glossyTarget = mix(glossyTarget, max(roughDamped, softReflection * vec3(0.88, 0.95, 1.05)), metalMaterial * (0.58 + fresnel * 0.22));
    glossyTarget = mix(glossyTarget, roughDamped, foliageMaterial * (0.62 + night * 0.30));
    glossyTarget = mix(glossyTarget, glossyTarget * vec3(0.78, 0.88, 1.08), rain * upward * (0.18 + overcast * 0.08));
    float glassReflectionMix = clamp(GLASS_REFLECTION_STRENGTH * (0.26 + fresnel * 0.48), 0.0, 0.42);
    vec3 glassReflection = mix(color * vec3(0.98, 1.00, 1.01),
                               softReflection * vec3(0.98, 1.00, 1.015),
                               glassReflectionMix);
    glossyTarget = mix(glossyTarget, max(roughDamped, glassReflection), glassMaterial * (0.28 + fresnel * 0.18));

    vec3 result = mix(roughDamped, glossyTarget, specMask);

    float glowLuma = luminance(color);
    vec3 warmGlow = mix(vec3(glowLuma), max(color, vec3(glowLuma) * vec3(1.18, 0.92, 0.58)), 0.62);
    result += warmGlow * emission * MATERIAL_EMISSIVE_LIGHT;

    return result;
}

vec3 applyCinematicWaterReflection(vec3 color, vec2 uv, float depth, float waterMask) {
    if (waterMask <= 0.001 || isEyeInWater != 0 || depth >= 0.999999) {
        return color;
    }

    vec3 worldPos = getWorldPosition(uv, depth);
    vec2 waterCoord = worldPos.xz * 0.055;
    float waterPresence = waterMask;

    float apparentDepth = getApparentWaterDepth(uv, depth, color);
    float physicalDepth = getPhysicalWaterDepth01(uv, depth);
    float depthFactor = clamp(max(apparentDepth, physicalDepth), 0.0, 1.0);
    float shallowFactor = 1.0 - smoothstep(0.10, 0.62, depthFactor);
    float viewDistance = length(getViewPosition(uv, depth));
    float farWater = smoothstep(38.0, 132.0, viewDistance);
    float detailFade = mix(1.0, 1.0 - WATER_DISTANT_DETAIL_FADE, farWater);
    vec2 curvature = getLayeredWaterCurvature(uv, worldPos.xz, depthFactor);
    curvature *= 0.42 + detailFade * 0.58;
    vec2 ripple = getWorldWaterSlope(worldPos.xz) * detailFade + curvature;

    vec3 waterNormal = normalize(vec3(-ripple.x * (0.78 + depthFactor * 0.62),
                                      1.0 - depthFactor * 0.07,
                                      -ripple.y * (0.78 + depthFactor * 0.62)));

    float t = frameTimeCounter * WATER_WAVE_SPEED;
    float waveBreakup = texture2D(noisetex, waterCoord * mix(2.4, 7.0, detailFade) + ripple * 0.22 + curvature * 0.30 + vec2(t * 0.010, -t * 0.007)).r;
    float brightWave = smoothstep(0.56, 0.92, waveBreakup) * WATER_HORIZON_GLOW;
    float depthLift = smoothstep(0.04, 0.86, depth);
    float rippleEnergy = clamp(length(ripple) * 0.34, 0.0, 1.0);
    float noon = getWaterNoonMask();
    float dayDamping = noon * WATER_DAY_REFLECTION_DAMPING;
    float sunDay = getSunPresence();
    float horizonWarmth = getHorizonSunWarmth();
    float rain = getRainAmount();
    float overcast = getRainCloudOcclusion();
    float directSun = getDirectSunTransmission();
    float night = getNightVisibility();
    float edgeReflectFade = screenEdgeFade(uv);
    float shallowReflectionFade = mix(0.72, 1.06, smoothstep(0.12, 0.88, depthFactor));
    float weatherReflectionFade = 1.0 - rain * (0.16 + overcast * 0.10);
    float waterShadowFactor = getShadowFactor(uv, depth);
    float waterDirectLight = clamp((waterShadowFactor - (1.0 - SHADOW_STRENGTH)) / max(SHADOW_STRENGTH, 0.001), 0.0, 1.0);
    float waterShadowAmount = (1.0 - waterDirectLight) * WATER_SHADOW_SPARKLE_DAMPING * sunDay * directSun;
    waterShadowAmount *= 1.0 - overcast * 0.42;
    float shadowedSparkle = clamp(mix(1.0 - WATER_SHADOW_SPARKLE_DAMPING, 1.0, waterDirectLight), 0.0, 1.0);
    shadowedSparkle = mix(shadowedSparkle, 1.0, overcast * 0.30);

    vec3 sunDir = sunPosition / max(length(sunPosition), 0.001);
    vec3 sunPlayerDir = normalize((gbufferModelViewInverse * vec4(sunDir, 0.0)).xyz);
    vec3 viewDir = normalize(cameraPosition - worldPos);
    float sunMirror = pow(max(dot(reflect(-sunPlayerDir, waterNormal), viewDir), 0.0), 18.0 + depthFactor * 32.0);
    float sunFacing = clamp(dot(waterNormal, sunPlayerDir) * 0.5 + 0.5, 0.0, 1.0);
    vec2 sunFlow = normalize(sunPlayerDir.xz + vec2(0.001, 0.001));
    vec2 sunCross = vec2(-sunFlow.y, sunFlow.x);
    vec2 sunPathUv = vec2(dot(worldPos.xz, sunFlow), dot(worldPos.xz, sunCross)) * 0.026;
    float pathNoise = texture2D(noisetex, sunPathUv * vec2(0.42, 2.35) + ripple * 0.16 + vec2(t * 0.012, -t * 0.004)).r;
    float pathBreakup = smoothstep(0.34, 0.88, pathNoise * 0.64 + waveBreakup * 0.42 + abs(curvature.x - curvature.y) * 0.28);
    float sunPath = sunDay * WATER_SUN_PATH_STRENGTH * (sunMirror * (1.15 + horizonWarmth * 1.25) + brightWave * sunFacing * 0.15);
    sunPath *= directSun * (0.58 + pathBreakup * 0.86) * (1.0 - farWater * 0.16) * (1.0 - dayDamping * 0.52);
    sunPath *= shadowedSparkle;
    vec3 sunTint = normalizeLightTint(getPhysicalSunColor());

    vec3 shallowWater = vec3(0.74, 0.92, 1.00);
    vec3 deepWater = vec3(0.05, 0.25, 0.48);
    vec3 waterDepthColor = mix(shallowWater, deepWater, smoothstep(0.08, 0.94, depthFactor));
    vec2 refractionOffset = (curvature * vec2(0.008, 0.011) + ripple * vec2(0.0025, 0.0030));
    refractionOffset *= WATER_REFRACTION_DISTORTION * (0.34 + depthFactor * 0.74) * (0.76 + shallowFactor * 0.24);
    vec2 refractUv = clamp(uv + refractionOffset, vec2(0.001), vec2(0.999));
    vec3 opaqueScene = texture2D(colortex4, refractUv).rgb;
    vec3 currentScene = texture2D(colortex0, refractUv).rgb;
    float opaqueValid = smoothstep(0.015, 0.120, luminance(opaqueScene));
    vec3 refractedScene = mix(currentScene, opaqueScene, opaqueValid);
    float waterAmbient = getWaterSceneAmbient(uv, refractedScene);
    float ambientLift = smoothstep(0.12, 0.74, waterAmbient);
    float waterNightCap = mix(0.34, 0.985, clamp(waterAmbient + getDayVisibility() * 0.18, 0.0, 1.0));
    vec3 dynamicReflection = getDynamicWaterEnvironmentReflection(worldPos, waterNormal, ripple, curvature, waveBreakup, depthFactor);
    dynamicReflection *= 1.0 + WATER_SKY_REFLECTION_BOOST * (0.08 + depthFactor * 0.12);
    dynamicReflection *= 1.0 - dayDamping * (0.44 + depthFactor * 0.18);
    dynamicReflection *= weatherReflectionFade * (0.74 + edgeReflectFade * 0.26);
    dynamicReflection *= mix(0.68, 1.08, ambientLift);
    dynamicReflection = mix(dynamicReflection, dynamicReflection * vec3(0.60, 0.78, 1.10), night * 0.18 + rain * 0.14);
    dynamicReflection += sunTint * brightWave * shadowedSparkle * (0.064 + depthFactor * 0.052) * (1.0 - dayDamping * 0.66) * directSun;
    dynamicReflection += sunTint * sunPath * (0.060 + depthFactor * 0.050);
    dynamicReflection = mix(dynamicReflection, dynamicReflection * vec3(0.70, 0.84, 1.08), overcast * 0.22);
    dynamicReflection = applyWaterDayHighlightRolloff(dynamicReflection, noon * waterPresence);

    float reflectionMask = waterPresence * WATER_REFLECTION_STRENGTH * WATER_DYNAMIC_REFLECTION_STRENGTH;
    reflectionMask *= 0.38 + WATER_REFLECTION_FLOOR * 0.70 + depthLift * 0.08 + depthFactor * WATER_DEEP_REFLECTION_BOOST * 0.22 + brightWave * 0.26 + rippleEnergy * 0.08;
    reflectionMask *= 1.0 - dayDamping * (0.34 + depthFactor * 0.12);
    reflectionMask = max(reflectionMask, waterPresence * WATER_REFLECTION_STRENGTH * (WATER_REFLECTION_FLOOR * 0.55 + depthFactor * 0.08));
    reflectionMask *= 0.78 + shallowFactor * 0.16 + depthFactor * 0.10;
    reflectionMask *= shallowReflectionFade * (0.72 + edgeReflectFade * 0.28) * weatherReflectionFade * (0.92 + night * 0.08);
    reflectionMask *= mix(0.78, 1.10, ambientLift);
    reflectionMask *= 1.0 - WATER_AMBIENT_REFLECTION_DAMPING * 0.28;

    vec3 shallowTint = mix(refractedScene, waterDepthColor, 0.16 + WATER_SHORE_CLARITY * 0.10);
    vec3 deepTint = mix(refractedScene * vec3(0.78, 0.90, 1.00), waterDepthColor, 0.30 + WATER_DEPTH_ABSORPTION * 0.48);
    deepTint *= mix(vec3(1.0), vec3(0.62, 0.80, 1.02), depthFactor * WATER_DEPTH_ABSORPTION);
    vec3 baseWater = mix(shallowTint, deepTint, depthFactor);
    baseWater = mix(baseWater, refractedScene, shallowFactor * WATER_SHORE_CLARITY * 0.28);
    baseWater = mix(baseWater, baseWater * vec3(0.68, 0.86, 1.04), (rippleEnergy * 0.10 + depthFactor * 0.12));
    baseWater *= 1.0 - depthFactor * WATER_DEPTH_ABSORPTION * 0.18;
    baseWater = mix(baseWater, baseWater * vec3(0.82, 0.90, 1.02), clamp(waterShadowAmount * 0.26, 0.0, 0.32));
    vec3 ambientWaterFloor = mix(vec3(0.050, 0.160, 0.300), vec3(0.220, 0.480, 0.660), ambientLift);
    ambientWaterFloor = mix(ambientWaterFloor, vec3(0.400, 0.700, 0.860), shallowFactor * ambientLift * 0.32);
    float ambientFloor = WATER_NOON_VISIBILITY_FLOOR * waterPresence * ambientLift * (0.22 + depthLift * 0.30 + shallowFactor * 0.14) * (1.0 - rain * 0.36);
    baseWater = max(baseWater, ambientWaterFloor * ambientFloor);
    baseWater *= 0.86 + ambientLift * 0.18;
    vec3 noonVisibility = mix(vec3(0.22, 0.45, 0.62), vec3(0.09, 0.28, 0.48), smoothstep(0.18, 0.96, depthFactor));
    float noonFloor = noon * waterPresence * WATER_NOON_VISIBILITY_FLOOR * (0.42 + depthLift * 0.46) * (1.0 - rain * 0.48);
    baseWater = max(baseWater, noonVisibility * noonFloor);

    float shoreMask = shallowFactor * (1.0 - farWater * 0.78) * waterPresence;
    vec3 sandReflection = vec3(0.82, 0.76, 0.58) * clamp(luminance(refractedScene) * 1.12 + 0.045, 0.0, 1.0);
    vec3 shallowSand = max(baseWater, mix(sandReflection, vec3(0.76, 0.90, 1.00), 0.34));
    baseWater = mix(baseWater, shallowSand, shoreMask * WATER_SHORE_SAND_BLEND);

    float causticBroad = texture2D(noisetex, worldPos.xz * 0.160 + ripple * 0.24 + vec2(t * 0.018, -t * 0.012)).r;
    float causticFine = texture2D(noisetex, worldPos.xz * 0.310 + vec2(-t * 0.029, t * 0.020)).g;
    float causticLines = smoothstep(0.58, 0.94, causticBroad * 0.68 + causticFine * 0.38 + abs(curvature.x - curvature.y) * 0.42);
    float causticMask = shoreMask * WATER_CAUSTICS_STRENGTH * sunDay * directSun * (1.0 - rain * 0.70) * (1.0 - dayDamping * 0.28);
    causticMask *= shadowedSparkle;
    baseWater += vec3(0.92, 0.84, 0.58) * causticLines * causticMask * 0.45;

    vec3 reflectedWater = mix(baseWater, dynamicReflection, clamp(reflectionMask, 0.0, 0.99));
    reflectedWater += sunTint * brightWave * shadowedSparkle * WATER_SUN_SPECULAR_STRENGTH * (0.020 + depthFactor * 0.014) * (1.0 - dayDamping * 0.62) * directSun;
    reflectedWater += sunTint * sunPath * (0.070 + depthFactor * 0.050);
    reflectedWater += dynamicReflection * WATER_REFLECTION_CONTRAST * (0.010 + depthFactor * 0.012) * (1.0 - dayDamping * 0.70);
    reflectedWater = max(reflectedWater, noonVisibility * noonFloor * (0.92 + shallowFactor * 0.18));
    reflectedWater = applyWaterDayHighlightRolloff(reflectedWater, noon * waterPresence);
    float reflectedLum = max(luminance(reflectedWater), 0.0001);
    reflectedWater *= mix(min(1.0, waterNightCap / reflectedLum), 1.0, getDayVisibility() * 0.55);
    return clamp(reflectedWater * WATER_SURFACE_BRIGHTNESS, 0.0, 0.985);
}

vec3 applyRainReflection(vec3 color, vec2 uv, float depth, float waterMask) {
    float rain = clamp(max(rainStrength, wetness), 0.0, 1.0);
    if (rain <= 0.001 || waterMask > 0.15 || isEyeInWater != 0 || depth >= 0.999999) {
        return color;
    }

    vec4 material = texture2D(colortex1, uv);
    vec4 pbrExtra = texture2D(colortex3, uv);
    float porosity = clamp(material.a, 0.0, 1.0);
    float pbrPresence = clamp(pbrExtra.b, 0.0, 1.0);
    vec3 worldPos = getWorldPosition(uv, depth);
    vec3 viewPos = getViewPosition(uv, depth);
    vec3 baseViewNormal = decodeStoredPbrNormal(uv, depth, waterMask);
    vec3 playerNormal = normalize((gbufferModelViewInverse * vec4(baseViewNormal, 0.0)).xyz);

    float upward = max(smoothstep(0.18, 0.72, playerNormal.y), clamp(pbrExtra.a, 0.0, 1.0) * pbrPresence);
    float lowerScreen = 1.0 - smoothstep(0.42, 0.92, uv.y);
    float depthFade = smoothstep(0.02, RAIN_REFLECTION_FADE, depth);
    float puddle = smoothstep(1.0 - RAIN_PUDDLE_COVERAGE, 0.98, puddleNoise(worldPos.xz * 0.18));

    vec2 ripple = getWorldRainSlope(worldPos.xz, rain);
    vec3 wetPlayerNormal = normalize(vec3(playerNormal.x - ripple.x * 0.26,
                                          max(playerNormal.y, 0.16),
                                          playerNormal.z - ripple.y * 0.26));
    vec3 wetViewNormal = normalize((gbufferModelView * vec4(wetPlayerNormal, 0.0)).xyz);

    float facing = clamp(dot(wetViewNormal, normalize(-viewPos)), 0.0, 1.0);
    float fresnel = pow(1.0 - facing, 2.0);
    vec4 ssrReflection = traceRainSSR(uv, viewPos, wetViewNormal, ripple, fresnel);

    float mask = rain * lowerScreen * depthFade * puddle * upward * RAIN_REFLECTION_STRENGTH;
    mask *= mix(1.0, 1.0 - porosity * 0.54, pbrPresence);
    mask *= 0.54 + fresnel * 0.72;

    vec3 coolWet = color * vec3(0.70, 0.80, 0.96) + vec3(0.014, 0.020, 0.032);
    vec3 wetColor = mix(color, coolWet, mask * 0.42);
    wetColor = mix(wetColor, max(wetColor, ssrReflection.rgb), clamp(mask * ssrReflection.a, 0.0, 0.82));
    wetColor += ssrReflection.rgb * ssrReflection.a * mask * 0.12;

    vec4 localLight = getRtLocalLighting(uv, depth, waterMask);
    float neonEnergy = clamp(max(max(localLight.r, localLight.g), localLight.b) - luminance(localLight.rgb) * 0.74, 0.0, 1.0);
    vec3 neonTint = normalizeLightTint(max(localLight.rgb, vec3(0.001)));
    float wetNeon = mask * neonEnergy * RT_LOCAL_NEON_SPILL * (0.34 + fresnel * 0.78) * (0.62 + upward * 0.38);
    wetColor = mix(wetColor, max(wetColor, neonTint * (0.10 + luminance(wetColor) * 0.92)), clamp(wetNeon, 0.0, 0.46));
    wetColor += neonTint * wetNeon * 0.050;

    return wetColor;
}

vec3 getSkyWaterFogColor(float horizon, float night, float rain, float waterInfluence) {
    vec3 daySky = mix(vec3(0.62, 0.80, 1.00), vec3(0.48, 0.70, 1.03), ATMOSPHERIC_BLUE_SHIFT);
    daySky = mix(daySky, vec3(luminance(daySky)) * vec3(0.76, 0.88, 1.08), rain * RAIN_SKY_DESATURATION);
    vec3 shallowWater = vec3(0.70, 0.90, 1.00);
    vec3 deepWater = vec3(0.10, 0.34, 0.58);
    vec3 waterFog = mix(shallowWater, deepWater, clamp(0.32 + night * 0.34 + rain * 0.14, 0.0, 1.0));
    vec3 fogColor = mix(daySky, waterFog, FOG_SKY_WATER_BLEND * clamp(0.28 + waterInfluence * 0.64 + horizon * 0.20, 0.0, 1.0));

    vec3 sunAir = normalizeLightTint(getPhysicalSunColor()) * vec3(0.92, 0.92, 0.90);
    fogColor = mix(fogColor, sunAir, clamp((getHorizonSunWarmth() * horizon * ATMOSPHERIC_SUN_GLOW + getSunPresence() * 0.035) * getDirectSunTransmission(), 0.0, 0.32));

    vec3 rainBlue = mix(vec3(0.36, 0.50, 0.76), getOvercastSkyTint() * vec3(0.50, 0.62, 0.86), getRainCloudOcclusion());
    fogColor = mix(fogColor, rainBlue, rain * (0.26 + getRainCloudOcclusion() * 0.10));

    vec3 nightAir = vec3(0.13, 0.21, 0.42);
    fogColor = mix(fogColor, nightAir, night * 0.82);

    return fogColor;
}

vec3 applyAtmosphericPerspective(vec3 color, vec2 uv, float depth, float waterMask) {
    if (ATMOSPHERIC_PERSPECTIVE_STRENGTH <= 0.001 || isEyeInWater != 0) {
        return color;
    }

    float isSky = step(0.999999, depth);
    vec3 viewPos = getViewPosition(uv, mix(depth, 0.999, isSky));
    float viewDistance = mix(length(viewPos), VOLUMETRIC_FOG_DISTANCE * 1.45, isSky);

    float distanceMask = smoothstep(18.0, VOLUMETRIC_FOG_DISTANCE * 1.32, viewDistance);
    float horizon = 1.0 - smoothstep(0.08, 0.62, abs(uv.y - 0.52) * 2.0);
    float rain = getRainAmount();
    float overcast = getRainCloudOcclusion();
    float night = getNightVisibility();
    float waterInfluence = max(waterMask, horizon * smoothstep(0.20, 0.92, distanceMask) * 0.48);
    vec3 airColor = getSkyWaterFogColor(horizon, night, rain, waterInfluence);

    float mask = distanceMask * (0.30 + horizon * 0.52 + isSky * 0.20);
    mask *= ATMOSPHERIC_PERSPECTIVE_STRENGTH * (1.0 + rain * 0.24 + overcast * RAIN_OVERCAST_MIST * 0.42);
    mask *= 1.0 - FOG_GRAY_WALL_REDUCTION * 0.22;
    mask = mix(mask, mask * 0.62, waterMask);
    mask = clamp(mask, 0.0, 0.34);

    vec3 lifted = max(color, airColor * 0.11);
    return mix(lifted, airColor, mask);
}

vec3 applyVolumetricFog(vec3 color, vec2 uv, float depth, float waterMask) {
    if (VOLUMETRIC_FOG_STRENGTH <= 0.001 || isEyeInWater != 0) {
        return color;
    }

    float isSky = step(0.999999, depth);
    vec3 viewPos = getViewPosition(uv, mix(depth, 0.999, isSky));
    vec3 playerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 worldPos = playerPos + cameraPosition;

    float viewDistance = mix(length(viewPos), VOLUMETRIC_FOG_DISTANCE * 1.25, isSky);
    float distanceFog = 1.0 - exp(-viewDistance * VOLUMETRIC_FOG_DENSITY);
    float farFade = smoothstep(8.0, VOLUMETRIC_FOG_DISTANCE, viewDistance);
    float horizonBand = 1.0 - smoothstep(0.10, 0.72, abs(uv.y - 0.52) * 2.0);
    float lowMist = smoothstep(18.0, -10.0, playerPos.y) * (1.0 - isSky);

    vec2 noiseUv = worldPos.xz * 0.010 + vec2(frameTimeCounter * 0.006, -frameTimeCounter * 0.004);
    float fogNoise = texture2D(noisetex, noiseUv).r;
    float volumeBreakup = mix(1.0, mix(0.84, 1.12, fogNoise), VOLUMETRIC_FOG_NOISE);

    float rain = getRainAmount();
    float overcast = getRainCloudOcclusion();
    float night = getNightVisibility();
    float rainBoost = 1.0 + rain * 0.32 + overcast * RAIN_OVERCAST_MIST;
    float weatherColumn = clamp((rain * 0.62 + overcast * 0.38) * WEATHER_VOLUME_SCATTER *
                                farFade * (0.38 + horizonBand * 0.46 + lowMist * 0.28),
                                0.0, 0.42);
    float fogMask = distanceFog * farFade * (0.56 + horizonBand * 0.56 + lowMist * 0.34);
    fogMask = clamp(fogMask * volumeBreakup * rainBoost * VOLUMETRIC_FOG_STRENGTH, 0.0, 0.76);
    fogMask += weatherColumn * (0.18 + distanceFog * 0.42);
    fogMask *= 1.0 - FOG_GRAY_WALL_REDUCTION * 0.26;
    fogMask = mix(fogMask, fogMask * 0.58, waterMask);
    fogMask = clamp(fogMask, 0.0, 0.52);

    float waterInfluence = max(waterMask, horizonBand * 0.46 + lowMist * 0.20);
    vec3 fogColor = getSkyWaterFogColor(horizonBand, night, rain, waterInfluence);
    fogColor = mix(fogColor, vec3(0.56, 0.74, 1.00), VOLUMETRIC_FOG_BLUE_TINT * 0.16);
    fogColor = mix(fogColor,
                   normalizeLightTint(getPhysicalSunColor()) * vec3(0.92, 0.92, 0.86),
                   weatherColumn * getSunPresence() * getDirectSunTransmission() * 0.38);

    vec3 lifted = max(color, fogColor * 0.12);
    return mix(lifted, fogColor, fogMask);
}

vec3 applyHorizonWaterSkyBlend(vec3 color, vec2 uv, float depth, float waterMask) {
    if (HORIZON_BLEND_STRENGTH <= 0.001 || isEyeInWater != 0) {
        return color;
    }

    float isSky = step(0.999999, depth);
    vec3 viewPos = getViewPosition(uv, mix(depth, 0.999, isSky));
    float viewDistance = mix(length(viewPos), VOLUMETRIC_FOG_DISTANCE * 1.62, isSky);
    float farMask = smoothstep(28.0, VOLUMETRIC_FOG_DISTANCE * 1.50, viewDistance);
    float horizonBand = 1.0 - smoothstep(0.0, HORIZON_BLEND_WIDTH, abs(uv.y - 0.52) * 1.48);

    float rain = getRainAmount();
    float overcast = getRainCloudOcclusion();
    float night = getNightVisibility();
    float waterInfluence = max(waterMask, horizonBand * farMask * 0.72 + isSky * horizonBand * 0.20);
    vec3 horizonColor = getSkyWaterFogColor(horizonBand, night, rain, waterInfluence);

    float mistNoise = texture2D(noisetex, vec2(uv.x * 1.65 + frameTimeCounter * 0.002, 0.37 + uv.y * 0.19)).r;
    float mistMask = horizonBand * farMask * HORIZON_BLEND_STRENGTH * (0.72 + mistNoise * 0.28);
    mistMask *= 0.82 + waterInfluence * HORIZON_WATER_MIST;
    mistMask *= 1.0 - rain * 0.04 + overcast * RAIN_OVERCAST_MIST * 0.34;
    mistMask = clamp(mistMask, 0.0, 0.42);

    vec3 lifted = max(color, horizonColor * (0.10 + HORIZON_WATER_MIST * 0.08));
    vec3 blended = mix(horizonColor, max(horizonColor, color * 0.72), waterMask * 0.24);
    return mix(lifted, blended, mistMask);
}

float getLightVisibility(vec3 lightViewPos) {
    return 1.0 - step(-0.001, lightViewPos.z);
}

vec3 getLightScreenPosition(vec3 lightViewPos) {
    vec3 lightDir = normalize(lightViewPos);
    return projectViewToScreen(lightDir * 96.0);
}

float getCloudMask(vec2 uv) {
    vec4 extra = texture2D(colortex3, clamp(uv, vec2(0.001), vec2(0.999)));
    float marker = smoothstep(0.84, 0.95, extra.g);
    marker *= 1.0 - smoothstep(0.08, 0.18, extra.r);
    marker *= 1.0 - smoothstep(0.08, 0.18, extra.b);
    marker *= smoothstep(0.58, 0.92, extra.a);
    return clamp(marker, 0.0, 1.0);
}

float getCloudDensityNoise(vec2 uv) {
    vec2 cloudUv = uv * vec2(2.15, 1.18) + vec2(frameTimeCounter * 0.0020, -frameTimeCounter * 0.0012);
    float broad = texture2D(noisetex, cloudUv).r;
    float mid = texture2D(noisetex, cloudUv * 2.70 + vec2(0.31, 0.17)).g;
    float fine = texture2D(noisetex, cloudUv * 6.10 + vec2(-0.18, 0.41)).b;
    return broad * 0.50 + mid * 0.34 + fine * 0.16;
}

vec3 applyCloudDepthAndScattering(vec3 color, vec2 uv, float depth) {
    float cloud = getCloudMask(uv);
    if (cloud <= 0.001 || isEyeInWater != 0) {
        return color;
    }

    float densityNoise = getCloudDensityNoise(uv);
    float clump = smoothstep(0.34, 0.82, densityNoise);
    float edge = smoothstep(0.34, 0.86, abs(densityNoise - 0.50) * 2.0);
    float horizonWarmth = getHorizonSunWarmth();
    float rain = getRainAmount();
    float overcast = getRainCloudOcclusion();

    vec3 shadowTint = mix(vec3(0.76, 0.83, 0.95), vec3(0.90, 0.66, 0.54), horizonWarmth * 0.50 * getDirectSunTransmission());
    shadowTint = mix(shadowTint, getOvercastSkyTint() * vec3(0.50, 0.62, 0.86), overcast * 0.72);
    float innerShadow = cloud * CLOUD_SHADOW_STRENGTH * (0.34 + clump * 0.62) * (1.0 + overcast * 0.62) * (1.0 - rain * 0.08);
    vec3 shaped = color * mix(vec3(1.0), shadowTint, innerShadow);

    vec3 sunTint = normalizeLightTint(getPhysicalSunColor());
    vec3 lightScreen = getLightScreenPosition(sunPosition);
    float visible = getLightVisibility(sunPosition) * screenEdgeFade(lightScreen.xy);
    visible *= 1.0 - step(0.999, abs(lightScreen.z));
    float nearSun = 1.0 - smoothstep(0.025, SUN_HALO_RADIUS * 0.78, length(uv - lightScreen.xy));
    float rim = nearSun * visible * getSunPresence() * getDirectSunTransmission() * cloud * (0.36 + edge * 0.86 + horizonWarmth * 0.42);
    shaped += sunTint * rim * CLOUD_SUN_SCATTER * (0.12 + horizonWarmth * 0.16) * (1.0 - rain * 0.45);

    vec3 densityTarget = mix(shaped * (0.94 + clump * 0.08), shaped * mix(vec3(1.0), sunTint * vec3(1.02, 0.94, 0.82), edge * 0.18 * getDirectSunTransmission()), CLOUD_DENSITY_VARIATION);
    densityTarget = mix(densityTarget, densityTarget * vec3(0.72, 0.82, 1.02), overcast * 0.26);
    float depthMask = clamp(cloud * (CLOUD_DEPTH_STRENGTH * (0.46 + clump * 0.54) + CLOUD_DENSITY_VARIATION * 0.18), 0.0, 0.58);
    return mix(color, densityTarget, depthMask);
}

vec3 applySunBehindCloudScattering(vec3 color, vec2 uv, float depth) {
    if ((SUN_HALO_STRENGTH + SUN_HAZE_SCATTER) <= 0.001 || isEyeInWater != 0) {
        return color;
    }

    vec3 lightScreen = getLightScreenPosition(sunPosition);
    float visible = getLightVisibility(sunPosition) * screenEdgeFade(lightScreen.xy);
    visible *= 1.0 - step(0.999, abs(lightScreen.z));

    vec2 toSun = lightScreen.xy - uv;
    float radialDistance = length(toSun);
    float tightHalo = 1.0 - smoothstep(0.020, SUN_HALO_RADIUS, radialDistance);
    float broadHaze = 1.0 - smoothstep(SUN_HALO_RADIUS * 0.52, SUN_HALO_RADIUS * 1.55, radialDistance);
    float cloudOnRay = max(getCloudMask(uv), max(getCloudMask(mix(uv, lightScreen.xy, 0.36)), getCloudMask(mix(uv, lightScreen.xy, 0.70))));
    float skyOrFar = max(step(0.999999, depth), smoothstep(0.84, 1.0, depth));
    float rain = getRainAmount();
    float overcast = getRainCloudOcclusion();

    vec3 sunTint = normalizeLightTint(getPhysicalSunColor());
    float hiddenBoost = cloudOnRay * (0.72 + getHorizonSunWarmth() * 0.46);
    float scatter = tightHalo * SUN_HALO_STRENGTH * (0.20 + skyOrFar * 0.34 + hiddenBoost);
    scatter += broadHaze * SUN_HAZE_SCATTER * (skyOrFar * 0.18 + hiddenBoost * 0.34);
    scatter *= visible * getSunPresence() * getDirectSunTransmission() * (1.0 - rain * 0.52);

    vec3 overcastHaze = getOvercastSkyTint() * broadHaze * skyOrFar * overcast * SUN_HAZE_SCATTER * RAIN_OVERCAST_MIST * 0.30;
    return color + sunTint * scatter + overcastHaze;
}

float sampleGodRayOcclusion(vec2 sampleUv) {
    float sampleDepth = texture2D(depthtex0, clamp(sampleUv, vec2(0.001), vec2(0.999))).r;
    return smoothstep(0.985, 1.0, sampleDepth);
}

vec3 sampleGodRay(vec2 uv, vec3 lightViewPos, vec3 lightColor, float strength) {
    if (GODRAY_STRENGTH <= 0.001 || strength <= 0.001 || isEyeInWater != 0) {
        return vec3(0.0);
    }

    vec3 lightScreen = getLightScreenPosition(lightViewPos);
    float visible = getLightVisibility(lightViewPos);
    visible *= screenEdgeFade(lightScreen.xy);
    visible *= 1.0 - step(0.999, abs(lightScreen.z));

    vec2 toLight = lightScreen.xy - uv;
    float radialDistance = length(toLight);
    vec2 stepDir = toLight * (GODRAY_LENGTH / 8.0);

    float density = 0.0;
    float illumination = 1.0;
    density += sampleGodRayOcclusion(uv + stepDir * 1.0) * illumination; illumination *= GODRAY_DECAY;
    density += sampleGodRayOcclusion(uv + stepDir * 2.0) * illumination; illumination *= GODRAY_DECAY;
    density += sampleGodRayOcclusion(uv + stepDir * 3.0) * illumination; illumination *= GODRAY_DECAY;
    density += sampleGodRayOcclusion(uv + stepDir * 4.0) * illumination; illumination *= GODRAY_DECAY;
    density += sampleGodRayOcclusion(uv + stepDir * 5.0) * illumination; illumination *= GODRAY_DECAY;
    density += sampleGodRayOcclusion(uv + stepDir * 6.0) * illumination; illumination *= GODRAY_DECAY;
    density += sampleGodRayOcclusion(uv + stepDir * 7.0) * illumination; illumination *= GODRAY_DECAY;
    density += sampleGodRayOcclusion(uv + stepDir * 8.0) * illumination;

    density /= 8.0;

    float cone = 1.0 - smoothstep(0.04, 0.92, radialDistance);
    float horizon = smoothstep(0.05, 0.62, 1.0 - abs(uv.y - lightScreen.y));
    float rain = getRainAmount();
    float rainFade = clamp(1.0 - rain * RAIN_GODRAY_DAMPING * (0.82 + getNightVisibility() * 0.26), 0.10, 1.0);
    float rayMask = clamp(density * cone * horizon * visible * strength * GODRAY_STRENGTH * rainFade, 0.0, 0.78);

    return lightColor * rayMask;
}

vec3 applyGodRays(vec3 color, vec2 uv, float depth) {
    float skyOrFar = max(smoothstep(0.72, 1.0, depth), step(0.999999, depth));
    vec3 sunColor = mix(getPhysicalSunColor(), vec3(0.72, 0.88, 1.00), GODRAY_BLUE_TINT * 0.22);
    vec3 moonColor = mix(vec3(0.50, 0.62, 1.00), vec3(0.68, 0.94, 1.00), GODRAY_BLUE_TINT);
    vec3 rays = sampleGodRay(uv, sunPosition, sunColor, GODRAY_SUN_STRENGTH * getSunPresence() * getDirectSunTransmission());
    rays += sampleGodRay(uv, moonPosition, moonColor, GODRAY_MOON_STRENGTH * getNightVisibility());
    return color + rays * (0.32 + skyOrFar * 0.68);
}

vec3 getRtLocalDebug(vec2 uv, float depth, float waterMask) {
    vec4 localLight = getRtLocalLighting(uv, depth, waterMask);
    vec4 blockField = getRtBlockLightField(uv, depth, waterMask);
    float localShadowStrength = min(RT_LOCAL_SHADOW_STRENGTH, RT_LOCAL_SHADOW_STABLE_CAP);
    float shadow = clamp(localLight.a * localShadowStrength + blockField.a, 0.0, 0.32) / 0.32;
    float light = clamp(luminance(localLight.rgb + blockField.rgb) * 2.4, 0.0, 1.0);
    return vec3(light, light * 0.52 + shadow * 0.18, shadow);
}

void main() {
    vec4 source = texture2D(colortex0, texcoord);
    float depth = texture2D(depthtex0, texcoord).r;
    float waterMask = step(0.5, texture2D(colortex1, texcoord).r);

#if DEBUG_VIEW == 1
    float shadowFactor = getShadowFactor(texcoord, depth);
    float directLight = clamp((shadowFactor - (1.0 - SHADOW_STRENGTH)) / max(SHADOW_STRENGTH, 0.001), 0.0, 1.0);
    gl_FragData[0] = vec4(vec3(directLight), source.a);
    return;
#elif DEBUG_VIEW == 2
    gl_FragData[0] = vec4(vec3(getAmbientOcclusion(texcoord, depth, waterMask)), source.a);
    return;
#elif DEBUG_VIEW == 3
    gl_FragData[0] = vec4(getRtLocalDebug(texcoord, depth, waterMask), source.a);
    return;
#elif DEBUG_VIEW == 4
    gl_FragData[0] = vec4(mix(vec3(0.02, 0.04, 0.08), vec3(0.0, 0.72, 1.0), waterMask), source.a);
    return;
#elif DEBUG_VIEW == 5
    gl_FragData[0] = vec4(getMaterialDebugView(texcoord, waterMask, 5), source.a);
    return;
#elif DEBUG_VIEW == 6
    gl_FragData[0] = vec4(getMaterialDebugView(texcoord, waterMask, 6), source.a);
    return;
#elif DEBUG_VIEW == 7
    gl_FragData[0] = vec4(getMaterialDebugView(texcoord, waterMask, 7), source.a);
    return;
#elif DEBUG_VIEW == 8
    gl_FragData[0] = vec4(getMaterialDebugView(texcoord, waterMask, 8), source.a);
    return;
#elif DEBUG_VIEW == 9
    gl_FragData[0] = vec4(getMaterialDebugView(texcoord, waterMask, 9), source.a);
    return;
#elif DEBUG_VIEW == 10
    gl_FragData[0] = vec4(getMaterialDebugView(texcoord, waterMask, 10), source.a);
    return;
#elif DEBUG_VIEW == 11
    gl_FragData[0] = vec4(getMaterialDebugView(texcoord, waterMask, 11), source.a);
    return;
#endif

    vec3 color = source.rgb;
    color = applyTimeOfDayLighting(color, texcoord, depth);
    color *= getAmbientOcclusion(texcoord, depth, waterMask);
    color = applyRtLocalEmissionLight(color, texcoord, depth, waterMask);
    color = applyScreenSpaceGlobalIllumination(color, texcoord, depth, waterMask);
    color = applyLeafSubsurfaceScattering(color, texcoord, depth, waterMask);
    color = applyMaterialSurfaceResponse(color, texcoord, depth, waterMask);
    color = applyCinematicWaterReflection(color, texcoord, depth, waterMask);
    color = applyRainReflection(color, texcoord, depth, waterMask);
    color = applyAtmosphericPerspective(color, texcoord, depth, waterMask);
    color = applyVolumetricFog(color, texcoord, depth, waterMask);
    color = applyHorizonWaterSkyBlend(color, texcoord, depth, waterMask);
    color = applyCloudDepthAndScattering(color, texcoord, depth);
    color = applySunBehindCloudScattering(color, texcoord, depth);
    color = applyGodRays(color, texcoord, depth);

    gl_FragData[0] = vec4(clamp(color, 0.0, LDR_SCENE_WHITE), source.a);
}
