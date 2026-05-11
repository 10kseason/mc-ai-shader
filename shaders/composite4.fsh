#version 120

/* DRAWBUFFERS:6 */

uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;

#define BLOOM_RADIUS 2.80 // [1.50 2.20 2.80 3.50 3.80 4.40 5.60]

vec3 sampleBloom7(vec2 uv) {
    return texture2D(colortex7, clamp(uv, vec2(0.001), vec2(0.999))).rgb;
}

vec3 upsampleWide(vec2 uv) {
    vec2 px = vec2(8.0 / viewWidth, 8.0 / viewHeight) * max(BLOOM_RADIUS * 0.38, 0.75);
    vec3 bloom = sampleBloom7(uv) * 0.34;
    bloom += sampleBloom7(uv + vec2( px.x, 0.0)) * 0.11;
    bloom += sampleBloom7(uv + vec2(-px.x, 0.0)) * 0.11;
    bloom += sampleBloom7(uv + vec2(0.0,  px.y)) * 0.11;
    bloom += sampleBloom7(uv + vec2(0.0, -px.y)) * 0.11;
    bloom += sampleBloom7(uv + vec2( px.x,  px.y)) * 0.055;
    bloom += sampleBloom7(uv + vec2(-px.x,  px.y)) * 0.055;
    bloom += sampleBloom7(uv + vec2( px.x, -px.y)) * 0.055;
    bloom += sampleBloom7(uv + vec2(-px.x, -px.y)) * 0.055;
    return bloom;
}

void main() {
    vec3 base = texture2D(colortex6, texcoord).rgb;
    vec3 wide = upsampleWide(texcoord);
    vec3 bloom = base * 0.72 + wide * 0.68;
    gl_FragData[0] = vec4(clamp(bloom, 0.0, 1.0), 1.0);
}
