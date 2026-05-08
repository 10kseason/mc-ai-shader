/* DRAWBUFFERS:0123 */

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D lightmap;
uniform vec4 entityColor;

varying vec4 gbColor;
varying vec2 gbTexCoord;
varying vec2 gbLightCoord;
varying vec3 gbNormal;
varying vec3 gbViewNormal;
varying vec3 gbViewTangent;
varying vec3 gbViewBitangent;
varying float gbVegetationMask;

#define PBR_ALBEDO_AO_STRENGTH 0.70 // [0.00 0.30 0.50 0.70 0.90 1.00]
#define LEAF_COLOR_BOOST 0.24 // [0.00 0.10 0.18 0.24 0.34 0.46]
#define RT_SOURCE_TEXTURE_STRICTNESS 0.58 // [0.00 0.28 0.44 0.58 0.74 0.90]

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

vec4 encodeMaterialMask(vec4 baseColor, vec3 litColor, vec4 normalData, vec4 specData) {
    float baseLum = materialLuma(baseColor.rgb);
    float litLum = materialLuma(litColor);
    float saturation = materialSaturation(baseColor.rgb);
    float neutralSurface = 1.0 - smoothstep(0.10, 0.55, saturation);
    float polishedSurface = smoothstep(0.26, 0.86, baseLum) * neutralSurface;
    float glassLikeAlpha = (1.0 - smoothstep(0.72, 0.99, baseColor.a)) * smoothstep(0.08, 0.42, baseColor.a);
    float smoothness = clamp(polishedSurface * 0.42 + glassLikeAlpha * 0.74, 0.0, 1.0);

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

    float upward = smoothstep(0.18, 0.86, normalize(gbNormal).y);
    return vec4(encodedBlockLight, smoothness, emissive, porosity);
}

vec4 encodePbrNormalTarget(vec4 normalData) {
#ifdef MC_TEXTURE_FORMAT_LAB_PBR
    vec3 viewNormal = decodeLabPbrViewNormal(normalData);
    return vec4(viewNormal * 0.5 + 0.5, clamp(normalData.b, 0.0, 1.0));
#else
    return vec4(normalize(gbViewNormal) * 0.5 + 0.5, 1.0);
#endif
}

vec4 encodePbrExtraTarget(vec4 normalData, vec4 specData) {
    float upward = smoothstep(0.18, 0.86, normalize(gbNormal).y);
#ifdef MC_TEXTURE_FORMAT_LAB_PBR
    float reflectance = clamp(specData.g, 0.0, 1.0);
    float height = clamp(normalData.a, 0.0, 1.0);
    return vec4(reflectance, height, 1.0, upward);
#else
    return vec4(0.10, 0.5, 0.0, upward);
#endif
}

void main() {
    vec4 base = texture2D(gtexture, gbTexCoord) * gbColor;
    vec4 color = base;
    if (color.a < 0.01) {
        discard;
    }

    vec3 lightColor = texture2D(lightmap, clamp(gbLightCoord, vec2(0.0), vec2(1.0))).rgb;
    color.rgb *= max(lightColor, vec3(0.08));
    color.rgb = mix(color.rgb, entityColor.rgb, clamp(entityColor.a, 0.0, 1.0));
    color.rgb = boostLeafColor(color.rgb, base);

    vec4 normalData = texture2D(normals, gbTexCoord);
    vec4 specData = texture2D(specular, gbTexCoord);
#ifdef MC_TEXTURE_FORMAT_LAB_PBR
    color.rgb *= mix(vec3(1.0), vec3(clamp(normalData.b, 0.0, 1.0)), PBR_ALBEDO_AO_STRENGTH);
#endif

    gl_FragData[0] = color;
    gl_FragData[1] = encodeMaterialMask(base, color.rgb, normalData, specData);
    gl_FragData[2] = encodePbrNormalTarget(normalData);
    gl_FragData[3] = encodePbrExtraTarget(normalData, specData);
}
