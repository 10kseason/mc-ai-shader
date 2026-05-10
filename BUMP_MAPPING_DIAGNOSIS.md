# Bump Mapping Diagnosis

## Goal

Use LabPBR `_n.png` normal data for stable material relief without POM ray marching or texture-coordinate displacement.

## Current Behavior

- `POM_STRENGTH`, `POM_STEPS`, and `POM_DEPTH_SCALE` are removed from the active settings path.
- Terrain albedo, normal, and specular samples use the original atlas UVs. The shader does not offset texture coordinates for parallax.
- LabPBR normal RGB is still decoded into the material normal buffer and used by lighting, reflection, SSGI, and material diagnostics.
- A lightweight bump shading pass uses `_n` normal RGB and alpha height only as local shading cues.

## Controls

- `PBR_BUMP_STRENGTH`: controls directional micro-shading from the normal map.
- `PBR_BUMP_HEIGHT_SHADE`: controls subtle light/dark relief from neutral-centered height alpha.
- `PBR_NORMAL_DETAIL_STRENGTH`: controls how strongly the stored PBR normal affects later composite-stage lighting/reflection logic.

## Debug View

Use `Debug View -> Bump Detail`.

- Red: normal-vector bump detail.
- Green: neutral-centered height relief.
- Blue: ordinary non-glass PBR surface marker.

The old `POM Safety` view is no longer used in the current release because there is no POM ray to fade or atlas travel to clamp.

## Test Loop

1. Use the `balanced` profile and a LabPBR/PBR resource pack.
2. Look at stone, deepslate, bricks, blackstone, sandstone, and quartz from normal gameplay angles.
3. Switch `Debug View` to `Bump Detail`; detail should stay localized to material texture detail instead of covering large atlas planes.
4. Increase `PBR_BUMP_STRENGTH` if the scene is too flat.
5. Lower `PBR_BUMP_HEIGHT_SHADE` first if generated PBR maps make stone look noisy.

## Expected Tradeoff

This does not change block silhouettes or create deep parallax. The benefit is that resource-pack variation cannot cause atlas bleed, underground-looking holes, or broad POM safety color fields.
