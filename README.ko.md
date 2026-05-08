# Client GLSL Shaderpack Lab

[English README](README.md)

Minecraft Java용 Iris/OptiFine 스타일 GLSL 셰이더팩 실험 프로젝트입니다.

이 프로젝트는 서버 사이드 Fabric 최적화 모드와 분리된 클라이언트 전용 셰이더팩입니다.

## 프리뷰

현재 셰이더팩 빌드로 찍은 Iris 인게임 테스트 캡처입니다.

![낮 물과 숲 프리뷰](docs/images/preview-day-water.png)

| 밤 물과 달빛 haze | torch와 local lighting |
| --- | --- |
| ![밤 물과 달빛 haze 프리뷰](docs/images/preview-night-water.png) | ![torch와 local lighting 프리뷰](docs/images/preview-night-torch.png) |

| material과 local light 테스트 |
| --- |
| ![material과 local light 프리뷰](docs/images/preview-material-lights.png) |

## 주요 기능

- 표준 shaderpack 폴더 또는 zip으로 동작합니다.
- Minecraft Java 1.20.1용 resource pack format 15를 사용합니다.
- `shadow`, `composite`, 다중 bloom pass, `final` pass를 사용해 Iris에서 빠르게 반복 테스트할 수 있습니다.
- shadow map 기반 화면 공간 그림자를 추가합니다.
- 물 mask pass와 `composite6` 반사 resolve pass를 사용해 보이는 지형과 나무를 물 표면에 반사합니다.
- LabPBR `_n.png`, `_s.png` 아틀라스를 Iris/OptiFine의 `normals`, `specular` sampler로 읽습니다.
- 물, smoothness, emissive, porosity, PBR view normal, material AO, reflectance, height, upward-facing surface 정보를 material buffer에 인코딩합니다.
- 비/젖음 기반 puddle reflection, ripple highlight, overcast cloud, rain mist, rain shadow fade를 포함합니다.
- PBR 기반 specular, wet surface polish, emissive glow, material AO, normal fresnel, porosity rain damping, roughness contrast를 적용합니다.
- 기존 HBAO와 screen-space ray AO 경로는 제거하고 SSAO 중심으로 정리해 이동 중 shimmer를 줄였습니다.
- 물은 reflection, depth absorption, shallow-water clarity, 약한 refraction distortion을 조합해 화면 거울처럼 보이지 않게 조정했습니다.
- 유리는 PBR smoothness/reflectance와 Fresnel을 사용하고, 높은 반사율 금속은 cyan/magenta split을 약하게 추가합니다.
- 잎 계열 terrain은 초록 응답을 강화하고 약한 vertex sway를 적용합니다.
- 최종 색보정은 과한 pastel/BF3 blue/heavy rain gray-blue보다 물리적으로 읽히는 노출과 LDR detail 보존을 우선합니다.
- bloom은 bright extraction, downsample blur, upsample accumulation, final compositing으로 나뉘며, 비/밤/실내에서 과하게 번지지 않게 기본값을 잡았습니다.
- torch 같은 warm emissive source를 대상으로 screen-space RT local lighting을 적용합니다. 보이는 광원은 tracing하고, 보이지 않는 block light는 stable light-field fallback으로 처리합니다.
- Iris shader profile `low`, `balanced`, `cinematic`을 제공합니다.

## 설치

1. `package_shaderpack.bat`를 실행합니다.
2. `dist/Client-GLSL-Shaderpack-Lab-1.20.1.zip`을 `.minecraft/shaderpacks/`에 복사합니다.
3. Iris 또는 OptiFine shader settings에서 활성화합니다.

개발 중에는 이 폴더 자체를 `shaderpacks/`에 복사한 뒤 게임 안에서 shader reload를 해도 됩니다.

## Iris 프리셋 비교

Iris shader settings의 메인 옵션 화면 맨 위에 있는 profile 버튼에서 전환합니다.

- `low`: 비용이 큰 항목을 먼저 낮춥니다. shadow map 해상도/거리, SSAO 반경/강도, RT local light tracing 거리/step, bloom radius/GI, water SSR step/거리, rain SSR, fog/cloud 강도, leaf wind, glass/metal reflection을 줄입니다. 또한 `composite6` reflected-geometry water pass를 끄고 final blend를 `0.00`으로 둡니다.
- `balanced`: 현재 shader source의 기본값과 동일한 기준 프리셋입니다. `low`나 `cinematic`이 장면을 얼마나 바꾸는지 비교할 때 기준으로 사용합니다.
- `cinematic`: 같은 항목들을 시각 품질 쪽으로 올립니다. 4096 shadow, 160 block shadow distance, 더 강한 SSAO, 더 긴 RT local light tracing, 큰 bloom/GI, 긴 water SSR/reflected-geometry tracing, 강한 fog/cloud/rain atmosphere, 더 큰 물 움직임, 강한 material reflection, 강한 leaf movement를 사용합니다.

추천 테스트 순서:

1. `balanced`를 선택하고 shader reload 후 물, 나무, torch-lit block, 비, 유리/금속/PBR 표면을 기준 장면으로 확인합니다.
2. `low`로 바꾸고 shader reload 후 reflection, AO, bloom, shadow, local light 비용을 낮춰도 장면 판독성이 유지되는지 봅니다.
3. `cinematic`으로 바꾸고 shader reload 후 더 큰 shadow range, water reflection pass, bloom GI, weather atmosphere가 성능 부담만큼 가치가 있는지 봅니다.
4. 프리셋 선택 뒤 개별 slider를 만지면 Iris가 `Custom`으로 표시할 수 있습니다. 원래 프리셋으로 되돌리려면 profile을 다시 선택합니다.

## 현재 한계

- screen-space RT local lighting은 보이는 emissive source에 의존합니다. block-light fallback은 full voxel light list가 아니라 안정적인 근사입니다.
- 물의 reflected-geometry texture는 half-resolution Iris pass이며, depth buffer와 화면 안에 보이는 geometry에 제한됩니다. 실제 second mirrored world render는 아닙니다.

## 다음 목표

- `vanilla-pbr-map-maker/dist/Vanilla-PBR-Generated.zip`과 함께 Iris에서 튜닝합니다.
- 게임 안에서 height-map 동작을 확인한 뒤 parallax/POM을 추가합니다.
