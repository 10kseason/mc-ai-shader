#version 120

/* DRAWBUFFERS:7 */
/*
const int colortex7Format = RGBA16;
*/

uniform sampler2D colortex6;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;

#define BLOOM_RADIUS 2.80 // [1.50 2.20 2.80 3.50 3.80 4.40 5.60]

vec3 sampleBloom(vec2 uv) {
    return texture2D(colortex6, clamp(uv, vec2(0.001), vec2(0.999))).rgb;
}

void main() {
    vec2 px = vec2(4.0 / viewWidth, 4.0 / viewHeight) * max(BLOOM_RADIUS * 0.62, 1.0);
    vec3 bloom = sampleBloom(texcoord) * 0.18;

    bloom += sampleBloom(texcoord + vec2( px.x, 0.0)) * 0.13;
    bloom += sampleBloom(texcoord + vec2(-px.x, 0.0)) * 0.13;
    bloom += sampleBloom(texcoord + vec2(0.0,  px.y)) * 0.13;
    bloom += sampleBloom(texcoord + vec2(0.0, -px.y)) * 0.13;

    bloom += sampleBloom(texcoord + vec2( px.x,  px.y) * 1.18) * 0.075;
    bloom += sampleBloom(texcoord + vec2(-px.x,  px.y) * 1.18) * 0.075;
    bloom += sampleBloom(texcoord + vec2( px.x, -px.y) * 1.18) * 0.075;
    bloom += sampleBloom(texcoord + vec2(-px.x, -px.y) * 1.18) * 0.075;

    gl_FragData[0] = vec4(clamp(bloom, 0.0, 1.0), 1.0);
}
