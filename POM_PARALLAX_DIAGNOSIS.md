# POM / Parallax Diagnosis

## Goal

Add an Iris-safe parallax/POM path that uses LabPBR `_n` alpha height without applying the cost and atlas-edge risk to every terrain block.

## Implementation

- `shaders/block.properties` assigns material id `10002` only to high-value stone, brick, deepslate, blackstone, sandstone, quartz, prismarine-brick, and tile-like block families.
- `shaders/lib/pass_textured.vsh` converts the camera view direction into tangent space and passes a `gbParallaxMask` only when `mc_Entity.x` matches material id `10002`.
- `shaders/lib/pass_textured_lit.fsh` runs POM only under `MC_TEXTURE_FORMAT_LAB_PBR`, so the `_n` alpha channel is treated as the height source only when a LabPBR-compatible resource pack is active.
- The displaced UV is used for albedo, normal, and specular samples so the visible texture detail and encoded PBR targets stay aligned.
- Extreme grazing angles are damped to reduce UV jumps across atlas neighbors.

## Profile Behavior

- `low`: `POM_STRENGTH=0.00`, `POM_STEPS=0`, `POM_DEPTH_SCALE=0.000`; POM is fully skipped.
- `balanced`: `POM_STRENGTH=0.42`, `POM_STEPS=8`, `POM_DEPTH_SCALE=0.050`; stone/brick relief is visible but conservative.
- `cinematic`: `POM_STRENGTH=0.72`, `POM_STEPS=14`, `POM_DEPTH_SCALE=0.080`; stronger relief for stress testing.

## Constraints

This is texture-space parallax, not true displaced geometry. It does not change block silhouettes, collision, or shadow caster geometry. Because Minecraft block textures are atlas-based, very high height scale can still sample into neighboring atlas cells on some resource packs; this build keeps scale restrained and limits the block list first.

## Iris Test Notes

Use a LabPBR/PBR resource pack with `_n` alpha height maps. Compare `low`, `balanced`, and `cinematic` on stone bricks, deepslate tiles, blackstone bricks, sandstone, and quartz surfaces. If a pack shows atlas bleeding, lower `POM_DEPTH_SCALE` before widening the material list.
