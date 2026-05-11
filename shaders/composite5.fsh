#version 120

/* DRAWBUFFERS:5 */

uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;

#define BLOOM_RADIUS 2.80 // [1.50 2.20 2.80 3.50 3.80 4.40 5.60]

vec3 sampleBloom6(vec2 uv) {
    return texture2D(colortex6, clamp(uv, vec2(0.001), vec2(0.999))).rgb;
}

vec3 upsampleMid(vec2 uv) {
    vec2 px = vec2(4.0 / viewWidth, 4.0 / viewHeight) * max(BLOOM_RADIUS * 0.30, 0.70);
    vec3 bloom = sampleBloom6(uv) * 0.36;
    bloom += sampleBloom6(uv + vec2( px.x, 0.0)) * 0.105;
    bloom += sampleBloom6(uv + vec2(-px.x, 0.0)) * 0.105;
    bloom += sampleBloom6(uv + vec2(0.0,  px.y)) * 0.105;
    bloom += sampleBloom6(uv + vec2(0.0, -px.y)) * 0.105;
    bloom += sampleBloom6(uv + vec2( px.x,  px.y)) * 0.055;
    bloom += sampleBloom6(uv + vec2(-px.x,  px.y)) * 0.055;
    bloom += sampleBloom6(uv + vec2( px.x, -px.y)) * 0.055;
    bloom += sampleBloom6(uv + vec2(-px.x, -px.y)) * 0.055;
    return bloom;
}

void main() {
    vec3 base = texture2D(colortex5, texcoord).rgb;
    vec3 mid = upsampleMid(texcoord);
    vec3 bloom = base * 0.58 + mid * 0.82;
    gl_FragData[0] = vec4(clamp(bloom, 0.0, 4.0), 1.0);
}
