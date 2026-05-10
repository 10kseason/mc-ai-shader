# Glass Material Diagnosis

Use this when glass starts reading like water.

## Current Glass Path

Glass is an explicit terrain material from `shaders/block.properties`, not the water mask. It should stay a thin dry pane:

- No water depth absorption.
- No water ripple, curvature, or caustic pass.
- Neutral-clear tint with only a faint edge lift.
- Strongly reduced screen reflection blur and offset.

## Debug Views

Use Iris `Debug View`:

- `5 Material Class`: glass should be cyan, water should be blue.
- `6 Smooth/Rough/Glass`: blue should mark glass panes/blocks.
- `10 Glass/Up/Water`: red is glass, blue is water. A glass block should not turn blue here.

If glass appears blue in mode `10`, inspect `gbuffers_water` or the water mask buffer. If it is red but looks like water in normal view, tune glass reflectance/tint instead.

## Controls

- `GLASS_REFLECTION_STRENGTH`: thin-pane screen reflection strength. Default profiles now keep this restrained.
- `PBR_HEIGHT_REFLECTION_WARP`: should have little effect on explicit glass because glass height is forced neutral.

## PBR Generator Note

`vanilla-pbr-map-maker` now treats generated glass maps as dry pane maps: lower F0, flatter normal RGB, and neutral height alpha. That keeps generated glass from being interpreted as a water-like high-reflection surface by this pack or by other LabPBR-aware shaders.
