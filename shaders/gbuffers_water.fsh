#version 120

/* DRAWBUFFERS:0123 */

uniform sampler2D gtexture;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    vec4 base = texture2D(gtexture, texcoord) * glcolor;

    vec3 waterColor = mix(base.rgb, vec3(0.66, 0.86, 1.0), 0.52);
    waterColor = mix(waterColor, vec3(0.34, 0.62, 0.96), 0.20);
    float waterAlpha = clamp(max(base.a * 0.48, 0.30), 0.24, 0.56);

    gl_FragData[0] = vec4(waterColor, waterAlpha);
    gl_FragData[1] = vec4(1.0, 1.0, 0.0, 1.0);
    gl_FragData[2] = vec4(0.5, 1.0, 0.5, 1.0);
    gl_FragData[3] = vec4(0.08, 0.5, 0.0, 1.0);
}
