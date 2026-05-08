#version 120

/* DRAWBUFFERS:4 */
/*
const int colortex4Format = RGBA16;
*/

uniform sampler2D colortex0;

varying vec2 texcoord;

void main() {
    gl_FragData[0] = vec4(texture2D(colortex0, texcoord).rgb, 1.0);
}
