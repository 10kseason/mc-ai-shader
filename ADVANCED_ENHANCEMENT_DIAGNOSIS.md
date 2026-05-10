# Advanced Enhancement Diagnosis

Use this checklist after installing `Client-GLSL-Shaderpack-Lab-0.1.13-mc1.20.1.zip`.

## Implemented From The Plan

- Screen-space global illumination in `composite.fsh`.
  - Controls: `SCREEN_GI_STRENGTH`, `SCREEN_GI_RADIUS`.
  - Profile baseline: off in `low`, moderate in `balanced`, stronger in `cinematic`.
- Leaf subsurface/backlight response.
  - Control: `LEAF_SSS_STRENGTH`.
  - It is inferred from foliage-like albedo/saturation and the stored PBR normal, so it does not need vertex wind or new resource-pack metadata.
- Wet-weather volumetric scatter.
  - Control: `WEATHER_VOLUME_SCATTER`.
  - It raises rain/overcast horizon mist and sun-tinted fog while preserving the existing volumetric fog sliders.
- POM ray marching is removed in `0.1.12`. LabPBR `_n` maps now provide bump/normal detail without UV displacement, so atlas bleed and parallax safety failures are avoided.
- Explicit glass is retuned in `0.1.13` to avoid water-like output. It should stay neutral-clear, low-distortion, and visibly separate from the blue water mask in debug views.

Full TAA is still deferred. It needs a history buffer, velocity/reprojection data, projection jitter, and in-game ghosting validation before it should be enabled in a comparison build.

## Comparison Loop

1. Start with the `balanced` profile.
2. Test a red or blue wool wall beside white blocks. Raise `SCREEN_GI_STRENGTH`; adjacent surfaces should pick up a soft color lift without obvious halos around depth edges.
3. Face leaves against the sun at morning or evening. Raise `LEAF_SSS_STRENGTH`; leaf clusters should warm and glow subtly on backlit edges without turning grass blocks neon.
4. Switch weather to rain. Raise `WEATHER_VOLUME_SCATTER`; distant low fog and horizon haze should increase, while nearby terrain should remain readable.
5. Compare `low`, `balanced`, and `cinematic`. `low` should keep the new GI path off, while `cinematic` should make the differences obvious for screenshots.

## Failure Signs

- `SCREEN_GI_STRENGTH` too high: colored halos around foreground silhouettes, washed-out corners, or obvious screen-space popping.
- `LEAF_SSS_STRENGTH` too high: grass or moss turns into flat bright green instead of only backlit foliage lifting.
- `WEATHER_VOLUME_SCATTER` too high: rain becomes a uniform gray wall and hides nearby water/terrain contrast.
- Bump detail too noisy: `Debug View -> Bump Detail` shows dense red/green noise on flat materials. Lower `PBR_BUMP_HEIGHT_SHADE` first, then `PBR_BUMP_STRENGTH`.

## Quick Rollback

- Set `SCREEN_GI_STRENGTH=0.00` to disable the new screen GI path.
- Set `LEAF_SSS_STRENGTH=0.00` to disable leaf backlight/subsurface response.
- Set `WEATHER_VOLUME_SCATTER=0.00` to disable the new weather scatter while keeping base volumetric fog.
- Select the `low` profile to disable screen GI and reduce most expensive comparison paths at once.
