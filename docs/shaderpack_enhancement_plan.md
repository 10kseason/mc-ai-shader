# Shaderpack Advanced Enhancement Plan

## Objective
To implement advanced rendering features—TAA (Temporal Anti-Aliasing), SSGI (Screen Space Global Illumination), POM (Parallax Occlusion Mapping), and Volumetric Weather (SSS & Volumetric Fog)—to elevate the existing shaderpack to a modern, cinematic standard, without breaking the current LabPBR and Bloom pipelines.

## Current Implementation Status

This plan is now partially implemented in release `0.1.13`.

- **POM/Bump**: POM was implemented in earlier releases, but release `0.1.12` removes ray-marched UV displacement and replaces the active path with LabPBR bump/normal-map shading. This keeps material relief while avoiding atlas bleed and resource-pack height-channel failure cases.
- **Glass**: release `0.1.13` retunes explicit glass away from water-like blue volume response. Glass now uses lower reflectance, reduced reflection blur, neutral height, and a drier generated-PBR preset.
- **SSGI**: A lightweight composite-pass approximation is implemented in `0.1.9` through `SCREEN_GI_STRENGTH` and `SCREEN_GI_RADIUS`. It samples nearby visible color/depth/normal data and intentionally stays lower cost than a multi-pass denoised ray-traced GI buffer.
- **SSS & Volumetric Weather**: Implemented in `0.1.9` through `LEAF_SSS_STRENGTH` and `WEATHER_VOLUME_SCATTER`. Leaves receive controlled backlight/subsurface lift, and rain/overcast scenes gain stronger horizon mist and sun-tinted weather scatter.
- **TAA**: Deferred. A proper TAA path needs history-buffer allocation, per-pixel velocity/reprojection, projection jitter, and in-game ghosting validation. This should not be folded into the comparison zip until those parts can be tested together.

## Scope & Impact
This plan outlines the surgical injection of these features into the existing G-Buffer, Composite, and Final passes.
*   **TAA**: Will introduce a history buffer (using a new or repurposed `colortex`) to smooth flickering.
*   **SSGI**: Will upgrade the existing Bloom GI in `final.fsh` using accurate depth/normal-based bouncing.
*   **POM**: Will activate the features diagnosed in `POM_PARALLAX_DIAGNOSIS.md` by modifying `gbuffers_terrain` to calculate ray-marched offsets.
*   **SSS & Volumetrics**: Will enhance `final.fsh` and `composite.fsh` to simulate light scattering through leaves and dense atmospheric fog based on `wetness`.

## Implementation Steps

### Phase 1: TAA (Temporal Anti-Aliasing) Integration
1.  **Buffer Allocation**: Declare a new history buffer (e.g., `colortex9` or repurpose `colortex4`) in `shaders.properties`.
2.  **Velocity Tracking**: Implement velocity vectors in `gbuffers_*.fsh` and write them to a dedicated channel (e.g., the alpha channel of the normal buffer or a new buffer).
3.  **Temporal Blending**: In `final.fsh` (or a new composite pass), blend the current frame's output (`colortex0`) with the reprojection of the history buffer using the velocity vectors.
4.  **Jittering**: Add sub-pixel jitter to the projection matrix in the `.vsh` files, negating it during the TAA resolve phase.

### Phase 2: POM (Parallax Occlusion Mapping) Activation
1.  **G-Buffer Modification**: Update `gbuffers_terrain.fsh` and `gbuffers_terrain.vsh` to calculate tangent-space view vectors.
2.  **Ray Marching**: Implement a ray-marching loop in `gbuffers_terrain.fsh` that reads the height map (from the LabPBR texture's alpha channel) to offset texture coordinates.
3.  **Self-Shadowing**: Calculate shadowing within the POM loop by marching towards the light source, applying the shadow factor to the base color.

### Phase 3: SSGI (Screen Space Global Illumination)
1.  **Extend Bloom GI**: The current `applyBloomGlobalIllumination` in `final.fsh` provides an artistic bounce. We will enhance this by calculating physically-based screen-space ray tracing.
2.  **Ray Tracing**: In `composite.fsh`, add a fast, low-step ray marching pass that bounces from the surface normal to sample the surrounding color (`colortex0`) and depth.
3.  **Filtering**: Apply spatial filtering in subsequent composite passes (e.g., `composite1.fsh` to `composite4.fsh`) to denoise the SSGI signal before final blending.

### Phase 4: SSS & Volumetric Weather
1.  **Subsurface Scattering (SSS)**: In `composite.fsh` or `final.fsh`, detect foliage/translucent materials using LabPBR porosity. Calculate the back-face lighting by inverting the normal and applying a scattered light tint (green/yellow for leaves).
2.  **Volumetric Fog**: Enhance the `getRainMood()` logic in `final.fsh`. Use the depth buffer and sun direction to calculate volumetric ray marching, creating dense fog and god rays that intensify based on `wetness` and `rainStrength`.

## Verification & Testing
1.  **TAA**: Verify that moving the camera slowly does not cause extreme blurring (ghosting) and that stationary jagged edges are smoothed.
2.  **POM**: Check brick/cobblestone blocks at grazing angles to ensure depth is visible without texture tearing.
3.  **SSGI**: Stand in a brightly colored enclosed space (e.g., red wool box) and verify that the color bleeds onto adjacent white blocks.
4.  **SSS/Volumetrics**: Observe leaves against the sun to ensure they glow. Check rain weather for appropriate fog density and light scattering.

## Migration & Rollback
*   If performance drops drastically, each feature will be governed by a `#define` toggle in `shaders.properties` or `final.fsh` (e.g., `#define ENABLE_TAA`, `#define ENABLE_POM`), allowing users to disable them easily.
