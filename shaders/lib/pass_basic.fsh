/* DRAWBUFFERS:0123 */

varying vec4 gbColor;

void main() {
    if (gbColor.a < 0.01) {
        discard;
    }

    gl_FragData[0] = gbColor;
    gl_FragData[1] = vec4(0.0);
    gl_FragData[2] = vec4(0.5, 0.5, 1.0, 1.0);
    gl_FragData[3] = vec4(0.0);
}
