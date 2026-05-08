/* DRAWBUFFERS:0123 */

uniform sampler2D gtexture;
uniform vec4 entityColor;

varying vec4 gbColor;
varying vec2 gbTexCoord;

float materialLuma(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float materialSaturation(vec3 color) {
    float mx = max(max(color.r, color.g), color.b);
    float mn = min(min(color.r, color.g), color.b);
    return clamp((mx - mn) / max(mx, 0.001), 0.0, 1.0);
}

void main() {
    vec4 color = texture2D(gtexture, gbTexCoord) * gbColor;
    if (color.a < 0.01) {
        discard;
    }

    color.rgb = mix(color.rgb, entityColor.rgb, clamp(entityColor.a, 0.0, 1.0));

    float emissive = smoothstep(0.46, 1.08, materialLuma(color.rgb)) *
                     smoothstep(0.18, 0.62, materialSaturation(color.rgb));

    gl_FragData[0] = color;
    gl_FragData[1] = vec4(0.0, 0.18 * emissive, 0.52 * emissive, 0.0);
    gl_FragData[2] = vec4(0.5, 0.5, 1.0, 1.0);
    gl_FragData[3] = vec4(0.0, 0.5, 0.0, 0.0);
}
