# Client GLSL Shaderpack Lab

[한국어 README](README.ko.md)

Minimal Iris/OptiFine-style GLSL shaderpack experiment for Minecraft Java.

This is a vibe-coded shader: an iterative visual lab focused on quickly shaping mood, water, light, and atmosphere in-game.

This project is intentionally separate from the server-side Fabric optimizer code.

## Version

Current release: `0.1.7` for Minecraft Java `1.20.1`.

## Preview

In-game Iris test captures from the current shaderpack build:

![Day water and foliage preview](docs/images/preview-day-water.png)

| Night water and moon haze | Torch and local lighting |
| --- | --- |
| ![Night water and moon haze preview](docs/images/preview-night-water.png) | ![Torch and local lighting preview](docs/images/preview-night-torch.png) |

| Material and local light test |
| --- |
| ![Material and local light preview](docs/images/preview-material-lights.png) |

## What This Version Does

- Runs as a standard shaderpack folder or zip.
- Uses resource pack format 15 for Minecraft Java 1.20.1.
- Uses `shadow`, `composite`, multi-pass bloom, and `final` passes for low-risk visual iteration.
- Adds screen-space shadowing from the shadow map.
- Adds a water mask pass for dusk-styled glossy water reflections.
- Reads LabPBR `_n.png` and `_s.png` atlases from the active resource pack through Iris/OptiFine `normals` and `specular` samplers.
- Adds selective LabPBR `_n` alpha height parallax/POM on stone, brick, deepslate, blackstone, sandstone, quartz, prismarine-brick, and tile-like block families through a dedicated block material mask.
- Encodes material targets for water, smoothness, emissive strength, porosity, PBR view normals, material AO, reflectance, height, and upward-facing surfaces.
- Shader settings are defined in `shaders/shaders.properties`.
- Adds rain/wetness-based puddle reflection and ripple highlights.
- Rain weather now models an overcast cloud layer: direct sun transmission, sun-path water sparkle, caustics, god rays, cloud rim light, and shadow contrast fade under rain while cool diffuse skylight and mist rise.
- Adds PBR-aware specular response, wet surface polish, emissive glow, material AO, normal-driven fresnel, porosity rain damping, and roughness contrast controls.
- Removes the older HBAO and screen-space ray AO paths; dynamic ambient occlusion now uses SSAO only to reduce moving-view shimmer.
- Water now combines reflection, depth absorption, shallow-water clarity, and weak refraction distortion so the surface reads as reflective without turning into a screen mirror.
- Underwater view now adds distance-based blue haze, soft blur, and subtle refractive drift so looking from inside water feels milky instead of only tinted.
- Ice blocks are now mapped separately from water and receive a frosted blue material response with higher smoothness/reflectance, so lakes and frozen surfaces read differently in the same scene.
- True nighttime skies now add a procedural star field, a soft Milky Way band, and animated shooting stars directly on sky pixels.
- Adds a dedicated `composite6` reflected-geometry resolve pass. Water pixels now trace visible terrain/tree geometry into `colortex8`, then the final pass blends that texture back onto the surface for a more grounded reflected-geometry read than the older single-pass post reflection.
- Stabilizes the reflected-geometry water pass by anchoring only the water ripple/noise/normal perturbation to world-space XZ coordinates. The reflection vector, Fresnel term, and view-dependent intensity still follow the active camera direction, while shallow/deep water depth fade and distance fade keep the result from becoming a hard mirror.
- Water defaults are tuned darker than the previous test build: surface brightness is reduced, ambient sky reflection is damped, only sun-direction specular is boosted, far water loses high-frequency noise, and near water keeps detail.
- Noon water no longer crushes midtones: daylight highlight rolloff now affects only bright glints, and `WATER_NOON_VISIBILITY_FLOOR` keeps deep water readable blue instead of black.
- Water color now moves by depth: shallow water trends cyan-white, deep water trends cyan-blue.
- Water now adds a directional sun path, shallow sand-color return, and weak near-shore caustic shimmer so highlights cluster toward the real sun direction instead of spreading evenly over the whole surface.
- Fog now blends sky and water color instead of leaning into a flat gray wall; volumetric fog density/blue tint are restrained by default to avoid the washed-out blue-gray look seen in distant rainy or ocean views.
- Horizon blending has a dedicated water-sky mist pass to soften the flat gray render-boundary band where distant water, fog, and sky meet.
- Vanilla cloud geometry now writes a cloud marker into the material buffer, allowing the composite pass to add density variation, inner shadow, and sun-behind-cloud scattering without changing world geometry.
- Glass blocks and panes now use an explicit material id with high smoothness, low porosity, restrained reflectance, subtle surface grain, faint blue-green edge tint, and Fresnel-driven reflection so they read more like real glass instead of generic shiny metal.
- High-reflectance metal surfaces still use PBR smoothness/reflectance plus Fresnel, but cyan/magenta reflection split is reduced on glass-specific pixels.
- Generated vanilla PBR maps from `vanilla-pbr-map-maker/dist/Vanilla-PBR-Generated.zip` are now treated conservatively: glass/ice height is kept near neutral, metal normal detail is damped, stone smoothness stays rougher, and PBR height warp/POM depth are restrained by default.
- Leaf-tinted terrain gets a stronger natural green response without vertex sway, keeping grass and foliage stable while standing still.
- The main scene and bloom buffers now stay in a precise `0..1` LDR range with 16-bit normalized color targets instead of carrying overbright HDR values.
- The final pass uses an LDR precision curve for shadow toe, highlight shoulder, low-black-floor detail, and local contrast preservation without 20-stop HDR compression.
- Default final color grading now favors physically plausible exposure over stylized filters: pastel wash, BF3-style blue grading, heavy rain gray-blue tint, and over-bright middle-gray mapping are reduced or disabled by default.
- Sunlight tint keeps its brightness but defaults to 35% lower daylight saturation through `SUNLIGHT_SATURATION`, reducing over-yellow sand, cloud scatter, and water glints.
- Adds color grading, contrast, vignette, and underwater tint handling.
- Adds real multi-stage bloom: bright extraction in `composite1`, downsample blur through `composite2`/`composite3`, upsample accumulation through `composite4`/`composite5`, and final compositing from `colortex5`.
- Bloom defaults use a higher threshold, restrained pixel radius, soft knee, rain/night damping, and dim-surface guarding so rainy, nighttime, and indoor scenes do not smear every bright surface.
- Bloom extraction now follows a more physical viewing model: local eye adaptation, source-to-surround contrast, emission, muted sky glare, and broad bright-surface suppression decide what scatters instead of treating saturated color as light.
- Final bloom compositing now behaves more like lens/atmospheric veiling glare, with exposure-aware damping before adding colored scatter back into the image.
- Adds first-pass screen-space RT local lighting for torch-like emissive sources: visible warm emissive pixels cast local colored light, trace through the depth buffer, and reduce light where intervening geometry blocks the ray.
- RT local light settings are exposed as `RT_LOCAL_LIGHT_STRENGTH`, `RT_LOCAL_SHADOW_STRENGTH`, `RT_LOCAL_SCREEN_RADIUS`, `RT_LOCAL_MAX_DISTANCE`, `RT_LOCAL_TRACE_STEPS`, `RT_LOCAL_SOURCE_THRESHOLD`, and `RT_LOCAL_WARMTH`.
- RT local lights get a small weather contrast response through `RT_WEATHER_LOCAL_CONTRAST`, so torch-like sources stand out more when rain clouds cut daylight.
- RT source detection now uses a stricter warm-texture source mask so ordinary torch-lit walls are less likely to become fake emitters.
- Adds a block-light field fallback in the material mask: non-water surfaces encode local block light below the water-mask threshold, then composite uses it for stable warm local light and shadow-edge darkening even when the torch itself is off screen.
- Adds Iris shader profiles for `low`, `balanced`, and `cinematic`. `balanced` matches the current shader defaults, while the other two profiles lower or raise the same setting groups for direct in-game comparison.
- Adds a `Debug View` shader setting for isolating shadow-only, SSAO-only, RT-local-only, water-mask, material-class, smoothness/roughness/glass, reflectance/height/PBR, block-light/emissive/porosity, normal/AO, and glass/up/water outputs.
- Stabilizes block-edge shadows by softening shadow-map sampling, reducing screen-space RT local shadow strength, and removing vegetation vertex wind movement.
- Current RT limitation: visible emissive sources use screen-space tracing, while the block-light fallback is a stable light-field approximation rather than a full voxel light list.
- Current water reflection limitation: the new reflection texture is a half-resolution Iris pass for visible reflected geometry. It is still bounded by screen/depth-buffer visibility, not a full second mirrored world render, which keeps performance closer to this lab pack's current budget.
- Keeps the shader simple enough to debug with Iris shader reload.

## Install

1. Run `package_shaderpack.bat`.
2. Copy `dist/Client-GLSL-Shaderpack-Lab-0.1.7-mc1.20.1.zip` into `.minecraft/shaderpacks/`.
3. Enable it from Iris or OptiFine shader settings.

During development, you can also copy this folder directly into `shaderpacks/` and reload shaders in-game.

## Iris Profile Comparison

Open Iris shader settings and use the profile button at the top of the main options screen.

- `low`: reduces expensive comparison targets first. It drops shadow map resolution/distance, SSAO radius and strength, RT local light tracing distance/steps, bloom radius/GI, water SSR steps/distance, rain SSR, fog/cloud intensity, and reflective glass/metal response. It also disables the `composite6` reflected-geometry water pass and sets selective POM to `POM_STRENGTH=0.00`, `POM_STEPS=0`.
- `balanced`: uses the source defaults and the generated PBR map tuning baseline. Use this when comparing vanilla glass, metal blocks, ice, stone, brick, tile, polished material response, and the stabilized water reflected-geometry pass. Selective POM runs at a moderate 8-step setting.
- `cinematic`: raises the same groups for visual stress testing. It uses 4096 shadows at 160 blocks, stronger SSAO, longer RT local light tracing, larger bloom/GI, longer water SSR and reflected-geometry tracing, stronger fog/cloud/rain atmosphere, stronger world-anchored water perturbation, and stronger but still height-damped material reflections. Selective POM rises to 14 steps and a deeper height scale.

Suggested test loop:

1. Select `balanced`, reload shaders, and take a baseline view over water, trees, torch-lit blocks, rain, and glass/metal/PBR surfaces.
2. Switch to `low`, reload shaders, and check for retained scene readability with lower reflection, AO, bloom, shadow, and local-light cost.
3. Switch to `cinematic`, reload shaders, and check whether the larger shadow range, water reflection pass, bloom GI, and weather atmosphere are worth the heavier load.
4. If you touch an individual slider after selecting a profile, Iris may show `Custom`; reselect the profile to return to the preset.

## Changelog

### 0.1.7

- Re-tuned the water reflected-geometry pass so water ripple/noise/normal perturbation is anchored to world-space XZ coordinates instead of feeling like a screen-space slide.
- Kept reflection ray direction, Fresnel response, and view-dependent intensity camera-driven so the reflection still changes naturally with the player's viewpoint.
- Raised `balanced` reflected-geometry tracing to 24 steps / 82 block max distance with stronger final blending, while `low` still disables the pass and `cinematic` pushes the same path harder.
- Added shallow/deep water depth fade, stronger distance fade, and restrained blur so reflected trees and terrain become readable without turning the surface into a flat mirror.
- Updated the water reflection diagnosis and rebuilt the Iris-ready package as `Client-GLSL-Shaderpack-Lab-0.1.7-mc1.20.1.zip`.

### 0.1.6

- Expanded `DEBUG_VIEW` into a material debug program with class, smoothness/roughness/glass, reflectance/height/PBR, block-light/emissive/porosity, normal/AO, and glass/up/water visualizations.
- Added `MATERIAL_DEBUG_DIAGNOSIS.md` documenting the material buffer contract and Iris debug workflow.
- Packaged the material debug diagnosis with the release zip.

### 0.1.5

- Added explicit glass material mapping for vanilla glass blocks, tinted glass, glass panes, and stained glass variants.
- Tuned glass to keep clear transmissive color, subtle surface grain, lower fake chromatic split, stable smoothness, low porosity, and realistic Fresnel edge reflection.
- Updated glass profile values so `balanced` and `cinematic` increase real reflection while keeping cyber-style color splitting subdued.

### 0.1.4

- Added selective LabPBR `_n` alpha height parallax/POM for stone, brick, deepslate, blackstone, sandstone, quartz, prismarine-brick, and tile-like blocks.
- Added `POM_STRENGTH`, `POM_STEPS`, and `POM_DEPTH_SCALE` to Iris settings and profile presets: disabled in `low`, moderate in `balanced`, stronger in `cinematic`.
- Added `POM_PARALLAX_DIAGNOSIS.md` and packaged it with the Iris-ready release zip.

### 0.1.3

- Tuned the shader against `Vanilla-PBR-Generated.zip` for calmer glass, metal, ice, and stone PBR response.
- Exposed PBR AO, normal, reflectance, height-warp, porosity, and final fresnel controls through the `low`, `balanced`, and `cinematic` Iris profiles.
- Dampened generated-map normal and height influence on smooth reflective materials so auto PBR maps do not create noisy reflection wobble.
- Packaged README files and the water-reflection diagnosis document into the release zip for handoff.

### 0.1.2

- Added separate ice material mapping so ice and water read as distinct surfaces.
- Added true-night-only Milky Way, stars, and shooting stars.
- Rebuilt the release zip as shaderpack-only contents: `shaders/` and `pack.mcmeta`.

### 0.1.1

- Removed vegetation vertex wind movement to stop grass/foliage from making nearby block shadows appear to move while the camera is still.
- Reduced unstable RT-local shadow contribution around block edges.
- Added debug views for isolating direct shadows, SSAO, RT-local lighting, and the water mask.
- Added underwater view haze, soft blur, and subtle refraction drift for a cloudier in-water look.
- Added separate ice material mapping plus procedural Milky Way, stars, and shooting stars for clear night skies.
- Rebuilt the release zip as `Client-GLSL-Shaderpack-Lab-0.1.1-mc1.20.1.zip`.

## Next Targets

- Tune the selective POM block list and height scale after one in-game pass against real resource-pack height maps.
