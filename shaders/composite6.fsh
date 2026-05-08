#version 120

/* RENDERTARGETS: 8 */
/*
const int colortex8Format = RGBA16;
*/

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform int isEyeInWater;

varying vec2 texcoord;

#define WATER_GEOMETRY_REFLECTION_STRENGTH 0.58 // [0.00 0.24 0.42 0.58 0.74 0.90]
#define WATER_GEOMETRY_REFLECTION_STEPS 18 // [8 12 18 24 30]
#define WATER_GEOMETRY_REFLECTION_MAX_DISTANCE 58.0 // [24.0 36.0 58.0 82.0 112.0]
#define WATER_GEOMETRY_REFLECTION_THICKNESS 1.10 // [0.35 0.65 1.10 1.65 2.40]
#define WATER_GEOMETRY_REFLECTION_BLUR 0.72 // [0.00 0.36 0.72 1.10 1.60]
#define WATER_GEOMETRY_REFLECTION_WAVE 0.68 // [0.00 0.34 0.68 0.92 1.20]

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
    vec4 homPos = projectionMatrix * vec4(position, 1.0);
    return homPos.xyz / homPos.w;
}

vec3 getViewPosition(vec2 uv, float depth) {
    vec3 ndcPos = vec3(uv, depth) * 2.0 - 1.0;
    return projectAndDivide(gbufferProjectionInverse, ndcPos);
}

vec3 getPlayerPositionFromView(vec3 viewPos) {
    return (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
}

vec3 projectViewToScreen(vec3 viewPos) {
    vec3 ndcPos = projectAndDivide(gbufferProjection, viewPos);
    return vec3(ndcPos.xy * 0.5 + 0.5, ndcPos.z * 0.5 + 0.5);
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float screenEdgeFade(vec2 uv) {
    vec2 edge = min(uv, 1.0 - uv);
    return smoothstep(0.00, 0.075, min(edge.x, edge.y));
}

float getRainAmount() {
    return clamp(max(rainStrength, wetness), 0.0, 1.0);
}

float getWaterDepth01(vec2 uv, float waterDepth) {
    float floorDepth = texture2D(depthtex1, uv).r;
    vec3 waterViewPos = getViewPosition(uv, waterDepth);
    vec3 floorViewPos = getViewPosition(uv, floorDepth);
    float physicalDepth = max((-floorViewPos.z) - (-waterViewPos.z), 0.0);
    float validFloor = step(waterDepth + 0.000001, floorDepth) * (1.0 - step(0.999999, floorDepth));
    float fallback = smoothstep(0.42, 0.98, waterDepth);
    return clamp(mix(fallback, smoothstep(0.12, 8.0, physicalDepth), validFloor), 0.0, 1.0);
}

vec2 getWorldWaterSlope(vec2 worldXZ) {
    vec2 p = worldXZ * 0.052;
    float t = frameTimeCounter;

    float w0 = sin(dot(p, vec2(0.86, 0.24)) * 7.0 + t * 0.98);
    float w1 = cos(dot(p, vec2(-0.36, 0.93)) * 11.0 - t * 1.18);
    float w2 = sin(dot(p, vec2(0.55, -0.78)) * 17.0 + t * 1.46);

    vec2 noiseCoord = p * 1.8 + vec2(t * 0.022, -t * 0.017);
    vec2 noiseSlope = texture2D(noisetex, noiseCoord).rg - vec2(0.5);

    vec2 slope = vec2(w0 * 0.52 + w2 * 0.18, w1 * 0.38 - w2 * 0.12);
    slope += noiseSlope * 0.58;
    return slope * WATER_GEOMETRY_REFLECTION_WAVE;
}

vec3 getWaterViewNormal(vec3 viewPos, float depthFactor) {
    vec3 playerPos = getPlayerPositionFromView(viewPos);
    vec2 slope = getWorldWaterSlope((playerPos + cameraPosition).xz);
    vec3 playerNormal = normalize(vec3(-slope.x * (0.60 + depthFactor * 0.34),
                                        1.0,
                                        -slope.y * (0.60 + depthFactor * 0.34)));
    return normalize((gbufferModelView * vec4(playerNormal, 0.0)).xyz);
}

vec3 sampleResolvedScene(vec2 uv, float blur) {
    vec2 px = vec2(max(blur, 0.0) / viewWidth, max(blur, 0.0) / viewHeight);
    vec3 color = texture2D(colortex0, clamp(uv, vec2(0.001), vec2(0.999))).rgb * 0.44;
    color += texture2D(colortex0, clamp(uv + vec2( px.x, 0.0), vec2(0.001), vec2(0.999))).rgb * 0.14;
    color += texture2D(colortex0, clamp(uv + vec2(-px.x, 0.0), vec2(0.001), vec2(0.999))).rgb * 0.14;
    color += texture2D(colortex0, clamp(uv + vec2(0.0,  px.y), vec2(0.001), vec2(0.999))).rgb * 0.14;
    color += texture2D(colortex0, clamp(uv + vec2(0.0, -px.y), vec2(0.001), vec2(0.999))).rgb * 0.14;
    return color;
}

vec4 traceReflectedGeometry(vec2 uv, float depth) {
    vec3 waterViewPos = getViewPosition(uv, depth);
    vec3 waterPlayerPos = getPlayerPositionFromView(waterViewPos);
    float depthFactor = getWaterDepth01(uv, depth);
    vec3 waterNormal = getWaterViewNormal(waterViewPos, depthFactor);
    vec3 viewDir = normalize(waterViewPos);
    vec3 rayDir = normalize(reflect(viewDir, waterNormal));

    if (abs(rayDir.z) < 0.008) {
        return vec4(0.0);
    }

    float viewDistance = length(waterViewPos);
    float distanceFade = 1.0 - smoothstep(96.0, 184.0, viewDistance);
    vec3 origin = waterViewPos + waterNormal * 0.08 + rayDir * 0.14;

    for (int i = 0; i < 30; i++) {
        if (i >= WATER_GEOMETRY_REFLECTION_STEPS) {
            break;
        }

        float stepRatio = (float(i) + 1.0) / float(WATER_GEOMETRY_REFLECTION_STEPS);
        float rayDistance = mix(0.18, WATER_GEOMETRY_REFLECTION_MAX_DISTANCE, stepRatio * stepRatio);
        vec3 rayPos = origin + rayDir * rayDistance;
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

        vec4 hitMaterial = texture2D(colortex1, rayScreen.xy);
        float hitWater = step(0.5, hitMaterial.r);
        if (hitWater > 0.5) {
            continue;
        }

        vec3 scenePos = getViewPosition(rayScreen.xy, sceneDepth);
        vec3 scenePlayerPos = getPlayerPositionFromView(scenePos);
        float rayLinearDepth = -rayPos.z;
        float sceneLinearDepth = -scenePos.z;
        float depthDelta = abs(rayLinearDepth - sceneLinearDepth);
        float thickness = WATER_GEOMETRY_REFLECTION_THICKNESS * (1.0 + sceneLinearDepth * 0.018);

        if (depthDelta < thickness) {
            float aboveWater = smoothstep(0.05, 3.5, scenePlayerPos.y - waterPlayerPos.y);
            float notSky = 1.0 - step(0.999999, sceneDepth);
            float edgeFade = screenEdgeFade(rayScreen.xy);
            float travelFade = 1.0 - smoothstep(WATER_GEOMETRY_REFLECTION_MAX_DISTANCE * 0.25,
                                                WATER_GEOMETRY_REFLECTION_MAX_DISTANCE,
                                                rayDistance);
            float depthFit = 1.0 - smoothstep(0.0, thickness, depthDelta);
            float glancing = pow(1.0 - clamp(dot(-viewDir, waterNormal), 0.0, 1.0), 1.8);
            float shallowFade = mix(0.52, 1.0, depthFactor);
            float rainFade = 1.0 - getRainAmount() * 0.18;
            float alpha = edgeFade * travelFade * depthFit * aboveWater * notSky * distanceFade;
            alpha *= (0.34 + glancing * 0.78) * shallowFade * rainFade * WATER_GEOMETRY_REFLECTION_STRENGTH;

            vec2 hitUv = clamp(rayScreen.xy, vec2(0.001), vec2(0.999));
            float blur = WATER_GEOMETRY_REFLECTION_BLUR * (0.55 + depthFactor * 0.65 + rayDistance * 0.010);
            vec3 hitColor = sampleResolvedScene(hitUv, blur);
            hitColor = mix(vec3(luminance(hitColor)) * vec3(0.72, 0.86, 1.08), hitColor, 0.76);
            hitColor *= vec3(0.78, 0.92, 1.10);

            return vec4(clamp(hitColor, 0.0, 1.0), clamp(alpha, 0.0, 0.86));
        }
    }

    return vec4(0.0);
}

void main() {
    float depth = texture2D(depthtex0, texcoord).r;
    float waterMask = step(0.5, texture2D(colortex1, texcoord).r);

    if (waterMask <= 0.001 || isEyeInWater != 0 || depth >= 0.999999 ||
        WATER_GEOMETRY_REFLECTION_STRENGTH <= 0.001) {
        gl_FragData[0] = vec4(0.0);
        return;
    }

    gl_FragData[0] = traceReflectedGeometry(texcoord, depth);
}
