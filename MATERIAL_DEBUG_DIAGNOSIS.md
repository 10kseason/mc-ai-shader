# Material Debug Diagnosis

## Goal

Expose the packed GLSL material buffers directly inside Iris so glass, water, PBR height, reflectance, emissive, porosity, AO, normal, and bump-detail issues can be checked without changing Minecraft resource packs or copying screenshots into a separate tool.

## Debug View Modes

`DEBUG_VIEW` now has material-oriented modes:

- `5 Material Class`: blue water, cyan glass, magenta metal-like reflectance, orange emissive pixels, brown porous/rough surfaces, green ordinary PBR surfaces.
- `6 Smooth/Rough/Glass`: red is smoothness, green is roughness, blue is explicit glass material.
- `7 Reflect/Height/PBR`: red is reflectance, green is LabPBR `_n` alpha height, blue is PBR/material marker.
- `8 Light/Emit/Porosity`: red is encoded block light, green is emissive strength, blue is porosity.
- `9 Normal/AO`: view-space normal RGB with a small AO blend so broken normal maps are visible.
- `10 Glass/Up/Water`: red is explicit glass material, green is upward-facing surface, blue is water mask.
- `11 Bump Detail`: red is normal-vector detail, green is neutral-centered height relief, blue is ordinary non-glass PBR surface marking.

## Buffer Contract

- `colortex1.r`: water mask when above `0.5`; otherwise encoded block light below the water threshold.
- `colortex1.g`: smoothness.
- `colortex1.b`: emissive strength.
- `colortex1.a`: porosity.
- `colortex2.rgb`: encoded view-space PBR normal.
- `colortex2.a`: material AO.
- `colortex3.r`: reflectance.
- `colortex3.g`: LabPBR height.
- `colortex3.b`: PBR/material marker; ordinary PBR surfaces use `1.0`, while explicit glass uses a reduced marker around `0.72`.
- `colortex3.a`: upward-facing surface marker.

## Iris Test Notes

Use Iris shader settings -> `Debug View`. For gameplay, return to `Normal`. When checking the new glass work, use `Material Class`, `Smooth/Rough/Glass`, and `Glass/Up/Water` first. If a glass block is not cyan/red-marked there, the block id mapping in `shaders/block.properties` is the first place to inspect.

For water-like glass, compare `Material Class` and `Glass/Up/Water`: glass should be cyan/red, while only real water should be blue. If the labels are correct but normal view is still too blue, lower `GLASS_REFLECTION_STRENGTH` before touching water settings.

For bump-map comparison, switch to `Bump Detail` after checking `Reflect/Height/PBR`. Red/green detail should follow material texture detail rather than filling broad atlas planes. If generated maps look noisy, lower `PBR_BUMP_HEIGHT_SHADE` before reducing normal detail globally.
