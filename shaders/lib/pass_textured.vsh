varying vec4 gbColor;
varying vec2 gbTexCoord;
varying vec2 gbLightCoord;
varying vec3 gbNormal;
varying vec3 gbViewNormal;
varying vec3 gbViewTangent;
varying vec3 gbViewBitangent;
varying float gbVegetationMask;

attribute vec4 at_tangent;

float getVertexVegetationMask(vec4 tint, vec3 normal) {
    float greenLead = smoothstep(0.05, 0.34, tint.g - max(tint.r, tint.b));
    float saturation = max(max(tint.r, tint.g), tint.b) - min(min(tint.r, tint.g), tint.b);
    float naturalGreen = smoothstep(0.08, 0.46, saturation) * smoothstep(0.18, 0.92, tint.g);
    float leafFace = 1.0 - smoothstep(0.92, 1.0, abs(normal.y));
    return clamp(greenLead * naturalGreen * (0.45 + leafFace * 0.55), 0.0, 1.0);
}

void main() {
    vec4 vertex = gl_Vertex;
    vec3 objectNormal = dot(gl_Normal, gl_Normal) > 0.0001 ? normalize(gl_Normal) : vec3(0.0, 1.0, 0.0);
    gbVegetationMask = getVertexVegetationMask(gl_Color, objectNormal);

    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * vertex;
    gbColor = gl_Color;
    gbTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
    gbLightCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
    gbNormal = normalize(gl_Normal);

    gbViewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vec3 objectTangent = dot(at_tangent.xyz, at_tangent.xyz) > 0.0001 ? at_tangent.xyz : vec3(1.0, 0.0, 0.0);
    gbViewTangent = normalize(gl_NormalMatrix * objectTangent);
    gbViewBitangent = normalize(cross(gbViewNormal, gbViewTangent) * (at_tangent.w < 0.0 ? -1.0 : 1.0));
}
