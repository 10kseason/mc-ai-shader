/* DRAWBUFFERS:0123 */

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D lightmap;
uniform vec4 entityColor;

varying vec4 gbColor;
varying vec2 gbTexCoord;
varying vec2 gbMidTexCoord;
varying vec2 gbSpriteHalfSize;
varying vec2 gbLightCoord;
varying vec3 gbNormal;
varying vec3 gbViewNormal;
varying vec3 gbViewTangent;
varying vec3 gbViewBitangent;
varying vec3 gbViewDirTangent;
varying float gbVegetationMask;
varying float gbIceMask;
varying float gbGlassMask;
varying float gbMetalMask;
varying float gbStoneMask;

#define PBR_ALBEDO_AO_STRENGTH 0.70 // [0.00 0.30 0.50 0.70 0.90 1.00]
#define LEAF_COLOR_BOOST 0.24 // [0.00 0.10 0.18 0.24 0.34 0.46]
#define RT_SOURCE_TEXTURE_STRICTNESS 0.58 // [0.00 0.28 0.44 0.58 0.74 0.90]
#define PBR_BUMP_STRENGTH 0.42 // [0.00 0.18 0.30 0.42 0.58 0.72]
#define PBR_BUMP_HEIGHT_SHADE 0.18 // [0.00 0.08 0.14 0.18 0.26 0.34]

float materialLuma(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float materialSaturation(vec3 color) {
    float mx = max(max(color.r, color.g), color.b);
    float mn = min(min(color.r, color.g), color.b);
    return clamp((mx - mn) / max(mx, 0.001), 0.0, 1.0);
}

vec3 boostLeafColor(vec3 color, vec4 baseColor) {
    float brightness = materialLuma(color);
    float greenLead = smoothstep(0.00, 0.24, baseColor.g - max(baseColor.r * 0.92, baseColor.b));
    float saturation = materialSaturation(baseColor.rgb);
    float leafMask = clamp(gbVegetationMask * greenLead * smoothstep(0.10, 0.46, saturation), 0.0, 1.0);
    if (leafMask <= 0.001 || LEAF_COLOR_BOOST <= 0.001) {
        return color;
    }

    float skyLift = smoothstep(0.36, 0.96, gbLightCoord.y);
    vec3 coolShadow = vec3(brightness * 0.42, brightness * 0.78, brightness * 0.62);
    vec3 sunLeaf = vec3(max(color.r, brightness * 0.62),
                        max(color.g, brightness * 1.18),
                        max(color.b, brightness * 0.58));
    vec3 lifted = mix(coolShadow, sunLeaf, skyLift);
    lifted = mix(color, max(color, lifted), LEAF_COLOR_BOOST * leafMask);
    lifted = mix(vec3(materialLuma(lifted)), lifted, 1.0 + LEAF_COLOR_BOOST * leafMask * 0.28);
    return lifted;
}

float iceHash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float getIceFrostMask(vec2 uv, vec3 normal) {
    vec2 fineCell = floor(uv * vec2(72.0, 72.0));
    float grain = smoothstep(0.72, 1.0, iceHash(fineCell));

    vec2 grid = abs(fract(uv * vec2(22.0, 22.0)) - 0.5);
    float hairline = 1.0 - smoothstep(0.018, 0.060, min(grid.x, grid.y));
    float diagonal = 1.0 - smoothstep(0.010, 0.048, abs(fract((uv.x + uv.y) * 18.0) - 0.5));
    float faceFrost = smoothstep(0.16, 0.86, abs(normal.y));
    return clamp(grain * 0.38 + hairline * 0.28 + diagonal * 0.18 + faceFrost * 0.16, 0.0, 1.0);
}

vec3 applyIceBlockLook(vec3 color, vec4 baseColor, vec2 surfaceTexCoord) {
    float ice = clamp(gbIceMask, 0.0, 1.0);
    if (ice <= 0.001) {
        return color;
    }

    float brightness = materialLuma(color);
    float textureDetail = clamp((materialLuma(baseColor.rgb) - 0.18) * 1.4, 0.0, 1.0);
    float frost = getIceFrostMask(surfaceTexCoord, normalize(gbNormal));
    vec3 clearBlue = color * vec3(0.62, 0.84, 1.22) + vec3(0.015, 0.050, 0.095);
    vec3 frosted = mix(clearBlue, vec3(0.72, 0.91, 1.00), clamp(frost * 0.62 + textureDetail * 0.18, 0.0, 0.82));
    frosted = mix(frosted, vec3(brightness) * vec3(0.70, 0.92, 1.12), 0.18);
    return mix(color, frosted, ice);
}

float getGlassSurfaceGrain(vec2 uv) {
    float vertical = 1.0 - smoothstep(0.018, 0.070, abs(fract(uv.x * 16.0) - 0.5));
    float horizontal = 1.0 - smoothstep(0.012, 0.058, abs(fract(uv.y * 16.0) - 0.5));
    float faintWave = sin((uv.x + uv.y) * 58.0) * 0.5 + 0.5;
    return clamp(vertical * 0.18 + horizontal * 0.14 + faintWave * 0.035, 0.0, 1.0);
}

vec3 applyRealisticGlassLook(vec3 color, vec4 baseColor, vec2 surfaceTexCoord) {
    float glass = clamp(gbGlassMask, 0.0, 1.0);
    if (glass <= 0.001) {
        return color;
    }

    float brightness = materialLuma(color);
    float stain = materialSaturation(baseColor.rgb);
    float thinAlpha = 1.0 - smoothstep(0.36, 0.92, baseColor.a);
    float grain = getGlassSurfaceGrain(surfaceTexCoord);
    vec3 clearTint = color * vec3(0.97, 1.00, 1.015) + vec3(0.002, 0.003, 0.004);
    vec3 stainedPreserve = mix(clearTint, color, clamp(stain * 0.95, 0.0, 0.86));
    vec3 faintEdge = vec3(max(brightness, 0.08)) * vec3(0.92, 0.98, 1.02);
    vec3 texturedGlass = mix(stainedPreserve, max(stainedPreserve, faintEdge), grain * (0.10 + thinAlpha * 0.10));
    return mix(color, texturedGlass, glass * (0.30 + thinAlpha * 0.12));
}

float decodeLabPbrPorosity(vec4 specData) {
    float blueByte = specData.b * 255.0;
    return clamp(min(blueByte, 64.0) / 64.0, 0.0, 1.0);
}

float decodeLabPbrEmission(vec4 specData) {
    float alphaByte = specData.a * 255.0;
    return alphaByte >= 254.5 ? 0.0 : clamp(alphaByte / 254.0, 0.0, 1.0);
}

float getWarmTextureSourceMask(vec3 baseColor) {
    float brightness = materialLuma(baseColor);
    float saturation = materialSaturation(baseColor);
    float redWarmth = smoothstep(0.035, 0.30, baseColor.r - max(baseColor.g * 0.82, baseColor.b * 1.35));
    float amberWarmth = smoothstep(0.04, 0.38, baseColor.g - baseColor.b) *
                        smoothstep(0.62, 1.26, baseColor.r / max(baseColor.g, 0.001));
    float hotTexture = smoothstep(0.42, 0.92, brightness) * smoothstep(0.10, 0.58, saturation);
    float warmMask = max(redWarmth, amberWarmth) * hotTexture;
    return mix(hotTexture, warmMask, RT_SOURCE_TEXTURE_STRICTNESS);
}

vec3 decodeLabPbrViewNormal(vec4 normalData) {
    vec2 xy = normalData.rg * 2.0 - 1.0;
    float z = sqrt(max(0.0, 1.0 - dot(xy, xy)));
    vec3 tangentNormal = normalize(vec3(xy, z));
    return normalize(gbViewTangent * tangentNormal.x +
                     gbViewBitangent * tangentNormal.y +
                     gbViewNormal * tangentNormal.z);
}

vec3 applyLabPbrBumpShading(vec3 color, vec4 baseColor, vec4 normalData, vec4 specData) {
#ifdef MC_TEXTURE_FORMAT_LAB_PBR
    if (PBR_BUMP_STRENGTH <= 0.001 && PBR_BUMP_HEIGHT_SHADE <= 0.001) {
        return color;
    }

    float glass = clamp(gbGlassMask, 0.0, 1.0);
    float ice = clamp(gbIceMask, 0.0, 1.0);
    float explicitMetal = clamp(gbMetalMask, 0.0, 1.0) * (1.0 - glass);
    float explicitStone = clamp(gbStoneMask, 0.0, 1.0) * (1.0 - glass) * (1.0 - ice);
    float smoothness = clamp(specData.r, 0.0, 1.0);
    float reflectance = clamp(specData.g, 0.0, 1.0);
    float metalLike = smoothstep(0.70, 0.92, reflectance) * smoothstep(0.42, 0.86, smoothness);
    metalLike = max(metalLike, explicitMetal);
    float materialMask = (1.0 - glass) * (1.0 - ice * 0.58) * (1.0 - metalLike * 0.62);

    vec2 bumpVector = normalData.rg * 2.0 - 1.0;
    float bumpEnergy = smoothstep(0.015, 0.42, length(bumpVector));
    float heightRelief = clamp(normalData.a - 0.5, -0.16, 0.16);
    float heightEnergy = smoothstep(0.006, 0.055, abs(heightRelief));
    float detailMask = clamp(max(bumpEnergy, heightEnergy) * materialMask * mix(1.0, 1.22, explicitStone), 0.0, 1.0);
    if (detailMask <= 0.001) {
        return color;
    }

    vec2 keyDir = normalize(vec2(-0.45, 0.74));
    float sideShade = dot(bumpVector, keyDir);
    float skyContext = smoothstep(0.24, 0.96, gbLightCoord.y);
    float blockContext = smoothstep(0.42, 0.98, gbLightCoord.x);
    float lightContext = 0.42 + max(skyContext, blockContext) * 0.58;
    float microShade = sideShade * PBR_BUMP_STRENGTH * 0.22;
    microShade += heightRelief * PBR_BUMP_HEIGHT_SHADE * 1.65;

    float cavity = (1.0 - clamp(normalData.b, 0.0, 1.0)) * PBR_BUMP_HEIGHT_SHADE * 0.34;
    float shade = clamp(1.0 + microShade * detailMask * lightContext - cavity * detailMask, 0.62, 1.42);
    return color * shade;
#else
    return color;
#endif
}

vec4 encodeMaterialMask(vec4 baseColor, vec3 litColor, vec4 normalData, vec4 specData) {
    float baseLum = materialLuma(baseColor.rgb);
    float litLum = materialLuma(litColor);
    float saturation = materialSaturation(baseColor.rgb);
    float neutralSurface = 1.0 - smoothstep(0.10, 0.55, saturation);
    float polishedSurface = smoothstep(0.26, 0.86, baseLum) * neutralSurface;
    float glassLikeAlpha = (1.0 - smoothstep(0.72, 0.99, baseColor.a)) * smoothstep(0.08, 0.42, baseColor.a);
    float smoothness = clamp(polishedSurface * 0.42 + glassLikeAlpha * 0.74, 0.0, 1.0);
    float glass = clamp(gbGlassMask, 0.0, 1.0);
    float ice = clamp(gbIceMask, 0.0, 1.0);
    float explicitMetal = clamp(gbMetalMask, 0.0, 1.0) * (1.0 - glass);
    float explicitStone = clamp(gbStoneMask, 0.0, 1.0) * (1.0 - glass) * (1.0 - ice);

    float rawBlockLight = clamp(gbLightCoord.x, 0.0, 1.0);
    float blockLight = smoothstep(0.62, 0.98, rawBlockLight);
    float skyLight = smoothstep(0.45, 0.94, gbLightCoord.y);
    float localLight = blockLight * (1.0 - skyLight * 0.62);
    float sourceTexture = getWarmTextureSourceMask(baseColor.rgb);
    float emissive = localLight * sourceTexture * smoothstep(0.20, 0.86, litLum);
    float encodedBlockLight = clamp(rawBlockLight * (1.0 - skyLight * 0.36) * 0.46, 0.0, 0.46);

#ifdef MC_TEXTURE_FORMAT_LAB_PBR
    smoothness = clamp(specData.r, 0.0, 1.0);
    emissive = max(emissive * 0.45, decodeLabPbrEmission(specData));
    float porosity = decodeLabPbrPorosity(specData);
#else
    float porosity = 0.18 * neutralSurface;
#endif

    smoothness = mix(smoothness, min(smoothness, 0.34), explicitStone);
    smoothness = mix(smoothness, max(smoothness, 0.82), explicitMetal);
    porosity = mix(porosity, max(porosity, 0.46), explicitStone);
    porosity = mix(porosity, 0.00, explicitMetal);
    smoothness = mix(smoothness, max(smoothness, 0.76), ice);
    smoothness = mix(smoothness, max(smoothness, 0.84), glass);
    porosity = mix(porosity, 0.02, ice);
    porosity = mix(porosity, 0.00, glass);
    emissive *= 1.0 - glass;

    float upward = smoothstep(0.18, 0.86, normalize(gbNormal).y);
    return vec4(encodedBlockLight, smoothness, emissive, porosity);
}

vec4 encodePbrNormalTarget(vec4 normalData) {
    float glass = clamp(gbGlassMask, 0.0, 1.0);
    float metal = clamp(gbMetalMask, 0.0, 1.0) * (1.0 - glass);
#ifdef MC_TEXTURE_FORMAT_LAB_PBR
    vec3 viewNormal = decodeLabPbrViewNormal(normalData);
    viewNormal = normalize(mix(viewNormal, normalize(gbViewNormal), metal * 0.46));
    viewNormal = normalize(mix(viewNormal, normalize(gbViewNormal), glass * 0.68));
    float ao = mix(clamp(normalData.b, 0.0, 1.0), 0.98, glass);
    return vec4(viewNormal * 0.5 + 0.5, ao);
#else
    return vec4(normalize(gbViewNormal) * 0.5 + 0.5, 1.0);
#endif
}

vec4 encodePbrExtraTarget(vec4 normalData, vec4 specData) {
    float upward = smoothstep(0.18, 0.86, normalize(gbNormal).y);
    float ice = clamp(gbIceMask, 0.0, 1.0);
    float glass = clamp(gbGlassMask, 0.0, 1.0);
    float metal = clamp(gbMetalMask, 0.0, 1.0) * (1.0 - glass);
    float stone = clamp(gbStoneMask, 0.0, 1.0) * (1.0 - glass) * (1.0 - ice);
#ifdef MC_TEXTURE_FORMAT_LAB_PBR
    float reflectance = clamp(specData.g, 0.0, 1.0);
    float height = clamp(normalData.a, 0.0, 1.0);
    reflectance = mix(reflectance, min(reflectance, 0.26), stone);
    reflectance = mix(reflectance, max(reflectance, 0.78), metal);
    reflectance = mix(reflectance, max(reflectance, 0.44), ice);
    reflectance = mix(reflectance, 0.18, glass);
    height = mix(height, mix(0.58, height, 0.80), stone);
    height = mix(height, mix(0.50, height, 0.28), metal);
    height = mix(height, mix(0.52, height, 0.35), ice);
    height = mix(height, 0.50, glass);
    float pbrMarker = 1.0;
    pbrMarker = mix(pbrMarker, 0.58, stone);
    pbrMarker = mix(pbrMarker, 0.86, metal);
    pbrMarker = mix(pbrMarker, 0.72, glass);
    return vec4(reflectance, height, pbrMarker, upward);
#else
    float reflectance = mix(0.10, 0.22, stone);
    reflectance = mix(reflectance, 0.78, metal);
    reflectance = mix(reflectance, 0.58, ice);
    float height = mix(0.5, 0.60, stone);
    height = mix(height, 0.50, metal);
    height = mix(height, 0.64, ice);
    reflectance = mix(reflectance, 0.18, glass);
    height = mix(height, 0.50, glass);
    float marker = 0.0;
    marker = mix(marker, 0.58, stone);
    marker = mix(marker, 0.86, metal);
    marker = mix(marker, 0.72, glass);
    return vec4(reflectance, height, marker, upward);
#endif
}

void main() {
    vec2 surfaceTexCoord = gbTexCoord;
    vec4 base = texture2D(gtexture, surfaceTexCoord) * gbColor;
    vec4 color = base;
    if (color.a < 0.01) {
        discard;
    }

    vec3 lightColor = texture2D(lightmap, clamp(gbLightCoord, vec2(0.0), vec2(1.0))).rgb;
    color.rgb *= max(lightColor, vec3(0.08));
    color.rgb = mix(color.rgb, entityColor.rgb, clamp(entityColor.a, 0.0, 1.0));
    color.rgb = boostLeafColor(color.rgb, base);

    vec4 normalData = texture2D(normals, surfaceTexCoord);
    vec4 specData = texture2D(specular, surfaceTexCoord);
#ifdef MC_TEXTURE_FORMAT_LAB_PBR
    color.rgb *= mix(vec3(1.0), vec3(clamp(normalData.b, 0.0, 1.0)), PBR_ALBEDO_AO_STRENGTH);
#endif
    color.rgb = applyLabPbrBumpShading(color.rgb, base, normalData, specData);
    color.rgb = applyIceBlockLook(color.rgb, base, surfaceTexCoord);
    color.rgb = applyRealisticGlassLook(color.rgb, base, surfaceTexCoord);

    gl_FragData[0] = color;
    gl_FragData[1] = encodeMaterialMask(base, color.rgb, normalData, specData);
    gl_FragData[2] = encodePbrNormalTarget(normalData);
    gl_FragData[3] = encodePbrExtraTarget(normalData, specData);
}
