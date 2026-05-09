# Water Reflection Diagnosis

## Sources Checked

- Iris gbuffers reference: `gbuffers_water` renders translucent terrain, including water, and translucent water runs after the deferred stage.
  https://shaders.properties/current/reference/programs/gbuffers/
- Iris depth buffer reference: `depthtex0` includes transparent geometry, while `depthtex1` excludes transparent geometry.
  https://shaders.properties/current/reference/buffers/depthtex/
- Iris colortex reference: gbuffers, deferred, and composite programs can write colortex attachments selected by `RENDERTARGETS` or legacy `DRAWBUFFERS`.
  https://shaders.properties/current/reference/buffers/colortex/
- shaderLABS pipeline reference: translucent gbuffers run after deferred and before composite; framebuffer attachments may be overwritten or alpha-blended.
  https://shaderlabs.org/wiki/Rendering_Pipeline_%28OptiFine%2C_ShadersMod%29
- Water Shader Alpha reference implementation notes: real planar water reflection needs a separate reflection texture, using shadow/geometry/compute work rather than simple post color blending.
  https://github.com/MahoganyTown/Water-Shader-Alpha

## Diagnosis

The shader was mostly producing transparent water, not reliable reflective water, because the water material mask was not being written strongly enough during the translucent pass.

`gbuffers_water.fsh` wrote:

```glsl
gl_FragData[1] = vec4(1.0, 1.0, 0.0, 0.0);
```

In the translucent pass, color attachments can be alpha-blended. With alpha `0.0`, the water mask in `colortex1.r` could fail to overwrite the previous material data. `composite.fsh` then calculated:

```glsl
float waterMask = step(0.5, texture2D(colortex1, texcoord).r);
```

When that mask is missing or weak, `applyCinematicWaterReflection()` simply does not run for water pixels.

There was a second structural issue: composite sampled `colortex0` after water had already been drawn. That means refraction/reflection sampling could read the already-blended transparent water image instead of the opaque scene behind it. This makes reflection look washed out or absent.

## Fix Applied

- `gbuffers_water.fsh` now writes the water mask target with alpha `1.0`.
- Added `deferred.fsh` and `deferred.vsh` to snapshot the opaque scene into `colortex4` before translucent water renders.
- `composite.fsh` now samples `colortex4` for water refraction when available, avoiding self-sampling the already-blended water image.
- `composite.fsh` now uses `depthtex0` versus `depthtex1` to estimate physical water thickness, so deeper water drives stronger multi-layer curvature.

## Reflected Geometry Upgrade

- Added `composite6.fsh` / `composite6.vsh` as a dedicated reflected-geometry resolve pass.
- `composite6.fsh` writes `colortex8` instead of directly changing the main scene color.
- `shaders.properties` sizes `colortex8` at half resolution and exposes reflection strength, trace steps, max distance, hit thickness, blur, wave distortion, and final blend strength.
- The pass only traces when the current pixel is tagged as water in `colortex1.r`, so dry scene pixels do not pay the reflection loop cost.
- It reflects the water view ray around a wave-distorted water normal, raymarches through the screen depth buffer, rejects water hits, requires the hit geometry to be above the water surface, and stores the resolved terrain/tree color plus confidence in `colortex8.a`.
- `final.fsh` samples and lightly blurs `colortex8`, then blends it only on water pixels before bloom and final tone operations.

## 0.1.7 Stabilization Pass

The reflection result itself is not pinned to world coordinates. `composite6.fsh` still computes the reflected ray from the active camera/view direction, and its Fresnel-like glancing response remains view dependent.

Only the water-surface perturbation is anchored: `getWorldWaterSlope()` and the ripple confidence mask now sample from `(playerPosition + cameraPosition).xz`, so the normal/noise pattern follows the Minecraft world XZ plane instead of sliding like a screen-space overlay when the camera moves.

The pass also adds stronger restraint around mirror-like artifacts:

- `balanced` now uses `WATER_GEOMETRY_REFLECTION_STRENGTH=0.74`, `WATER_GEOMETRY_REFLECTION_STEPS=24`, `WATER_GEOMETRY_REFLECTION_MAX_DISTANCE=82.0`, `WATER_GEOMETRY_REFLECTION_THICKNESS=1.65`, `WATER_GEOMETRY_REFLECTION_WAVE=0.34`, and `WATER_GEOMETRY_REFLECTION_FINAL_STRENGTH=0.90`.
- `low` still disables `composite6` through zero reflected-geometry strength/final strength and `!program.composite6`.
- `cinematic` raises the same reflected-geometry path to longer tracing, thicker hit acceptance, stronger final blend, and more world-anchored wave perturbation.
- Shallow/deep water depth fade, view-distance fade, screen-edge fade, travel fade, and rain fade all multiply the reflection alpha before it reaches `colortex8.a`.
- The final pass uses a small vertical resolve blur on `colortex8` so terrain/tree silhouettes read on the water surface, but the reflection remains depth-buffer bounded rather than becoming a full planar mirror.

## Remaining Constraints

This is no longer a single-pass color flip/post blend. It now has a separate reflection texture and pass, and it can reflect visible tree/terrain geometry more convincingly on water.

It is still not a full off-screen mirrored camera render. Geometry outside the current depth buffer cannot appear, and edge misses fade out. That is intentional for this lab build: a true planar world re-render or compute/geometry pipeline would be much more expensive and more invasive than the current Iris-compatible pass chain.
