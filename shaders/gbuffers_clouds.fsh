#version 120

/* DRAWBUFFERS:0123 */

uniform sampler2D gtexture;
uniform vec4 entityColor;

varying vec4 gbColor;
varying vec2 gbTexCoord;

float cloudLuma(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    vec4 color = texture2D(gtexture, gbTexCoord) * gbColor;
    if (color.a < 0.01) {
        discard;
    }

    color.rgb = mix(color.rgb, entityColor.rgb, clamp(entityColor.a, 0.0, 1.0));

    float density = clamp(color.a * (0.48 + cloudLuma(color.rgb) * 0.78), 0.0, 1.0);

    gl_FragData[0] = color;
    gl_FragData[1] = vec4(0.0, 0.02 * density, 0.0, 0.0);
    gl_FragData[2] = vec4(0.5, 0.5, 1.0, 1.0);
    gl_FragData[3] = vec4(0.02, 0.90 + density * 0.08, 0.02, 0.70 + density * 0.28);
}
