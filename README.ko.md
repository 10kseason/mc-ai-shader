# Client GLSL Shaderpack Lab

[English README](README.md)

Minecraft Java용 Iris/OptiFine 스타일 GLSL 셰이더팩 실험 프로젝트입니다.

이 프로젝트는 바이브 코딩 쉐이더입니다. 게임 안에서 분위기, 물, 빛, 대기감을 빠르게 잡아가며 반복 튜닝하는 시각 실험실에 가깝습니다.

이 프로젝트는 서버 사이드 Fabric 최적화 모드와 분리된 클라이언트 전용 셰이더팩입니다.

## 버전

현재 릴리스: Minecraft Java `1.20.1`용 `0.1.7`.

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
- 물체 반사 안정화를 위해 물 ripple/noise/normal perturbation만 world-space XZ 좌표에 고정했습니다. 반사 벡터, Fresnel, 시점 의존 intensity는 계속 camera/view direction을 따르며, shallow/deep water depth fade와 distance fade로 과한 거울 느낌을 줄였습니다.
- LabPBR `_n.png`, `_s.png` 아틀라스를 Iris/OptiFine의 `normals`, `specular` sampler로 읽습니다.
- LabPBR `_n` 알파 height를 사용한 선택적 parallax/POM을 추가했습니다. 돌, 벽돌, deepslate, blackstone, sandstone, quartz, prismarine brick, tile류처럼 효과가 큰 block family에만 material ID로 한정 적용합니다.
- 물, smoothness, emissive, porosity, PBR view normal, material AO, reflectance, height, upward-facing surface 정보를 material buffer에 인코딩합니다.
- 비/젖음 기반 puddle reflection, ripple highlight, overcast cloud, rain mist, rain shadow fade를 포함합니다.
- PBR 기반 specular, wet surface polish, emissive glow, material AO, normal fresnel, porosity rain damping, roughness contrast를 적용합니다.
- 기존 HBAO와 screen-space ray AO 경로는 제거하고 SSAO 중심으로 정리해 이동 중 shimmer를 줄였습니다.
- 물은 reflection, depth absorption, shallow-water clarity, 약한 refraction distortion을 조합해 화면 거울처럼 보이지 않게 조정했습니다.
- 물 내부 시야는 거리 기반 파란 haze, soft blur, 약한 굴절 drift를 추가해 단순 tint가 아니라 물속 특유의 뿌연 느낌이 나도록 조정했습니다.
- 얼음 블록은 물과 별도 ID로 매핑하고, 더 차갑고 서리 낀 파란 material response와 높은 smoothness/reflectance를 적용해 같은 장면에서도 물과 얼음이 분리되어 보이게 했습니다.
- 진짜 밤 시간대의 맑은 하늘에는 procedural star field, 은하수 band, 움직이는 별똥별을 sky 픽셀에 직접 합성합니다.
- 유리 블록과 유리판은 별도 material ID를 사용합니다. 높은 smoothness, 낮은 porosity, 절제된 reflectance, 약한 표면 결, 옅은 청록 edge tint, Fresnel 기반 반사를 조합해 일반 shiny metal이 아니라 실제 유리처럼 읽히게 조정했습니다.
- 높은 반사율 금속은 계속 PBR smoothness/reflectance와 Fresnel을 사용하지만, 유리 전용 픽셀에서는 cyan/magenta split을 크게 줄입니다.
- `vanilla-pbr-map-maker/dist/Vanilla-PBR-Generated.zip` 기준으로 생성형 PBR 맵을 보수적으로 읽습니다. 유리/얼음 height는 중립에 가깝게, 금속 normal은 약하게, 돌 smoothness는 거칠게 유지하고 PBR height warp/POM depth 기본값을 낮췄습니다.
- 잎 계열 terrain은 초록 응답을 강화하되 vertex sway는 제거해, 정지 상태에서 풀과 잎이 주변 블록 그림자를 흔들어 보이게 하지 않습니다.
- 최종 색보정은 과한 pastel/BF3 blue/heavy rain gray-blue보다 물리적으로 읽히는 노출과 LDR detail 보존을 우선합니다.
- bloom은 bright extraction, downsample blur, upsample accumulation, final compositing으로 나뉘며, 비/밤/실내에서 과하게 번지지 않게 기본값을 잡았습니다.
- torch 같은 warm emissive source를 대상으로 screen-space RT local lighting을 적용합니다. 보이는 광원은 tracing하고, 보이지 않는 block light는 stable light-field fallback으로 처리합니다.
- Iris shader profile `low`, `balanced`, `cinematic`을 제공합니다.
- 직접 그림자, SSAO, RT local, water mask, material class, smoothness/roughness/glass, reflectance/height/PBR, block-light/emissive/porosity, normal/AO, glass/up/water를 따로 볼 수 있는 `Debug View` 옵션을 제공합니다.
- shadow map sampling을 부드럽게 하고, RT local shadow 기여를 낮추고, vegetation vertex wind를 제거해 블록 경계 그림자 흔들림을 줄였습니다.

## 설치

1. `package_shaderpack.bat`를 실행합니다.
2. `dist/Client-GLSL-Shaderpack-Lab-0.1.7-mc1.20.1.zip`을 `.minecraft/shaderpacks/`에 복사합니다.
3. Iris 또는 OptiFine shader settings에서 활성화합니다.

개발 중에는 이 폴더 자체를 `shaderpacks/`에 복사한 뒤 게임 안에서 shader reload를 해도 됩니다.

## Iris 프리셋 비교

Iris shader settings의 메인 옵션 화면 맨 위에 있는 profile 버튼에서 전환합니다.

- `low`: 비용이 큰 항목을 먼저 낮춥니다. shadow map 해상도/거리, SSAO 반경/강도, RT local light tracing 거리/step, bloom radius/GI, water SSR step/거리, rain SSR, fog/cloud 강도, glass/metal reflection을 줄입니다. 또한 `composite6` reflected-geometry water pass를 끄고 final blend를 `0.00`으로 두며, 선택적 POM도 `POM_STRENGTH=0.00`, `POM_STEPS=0`으로 끕니다.
- `balanced`: 현재 shader source의 기본값과 생성형 PBR 맵 튜닝 기준입니다. vanilla 유리, 금속 블록, 얼음, 돌, 벽돌, 타일, polished material 반응과 안정화된 water reflected-geometry pass를 볼 때 기준으로 사용합니다. 선택적 POM은 8-step 중간값으로 동작합니다.
- `cinematic`: 같은 항목들을 시각 품질 쪽으로 올립니다. 4096 shadow, 160 block shadow distance, 더 강한 SSAO, 더 긴 RT local light tracing, 큰 bloom/GI, 긴 water SSR/reflected-geometry tracing, 강한 fog/cloud/rain atmosphere, 더 강한 world-anchored water perturbation, 더 강하지만 height가 과하게 흔들리지 않는 material reflection을 사용합니다. 선택적 POM은 14-step과 더 깊은 height scale로 올라갑니다.

추천 테스트 순서:

1. `balanced`를 선택하고 shader reload 후 물, 나무, torch-lit block, 비, 유리/금속/PBR 표면을 기준 장면으로 확인합니다.
2. `low`로 바꾸고 shader reload 후 reflection, AO, bloom, shadow, local light 비용을 낮춰도 장면 판독성이 유지되는지 봅니다.
3. `cinematic`으로 바꾸고 shader reload 후 더 큰 shadow range, water reflection pass, bloom GI, weather atmosphere가 성능 부담만큼 가치가 있는지 봅니다.
4. 프리셋 선택 뒤 개별 slider를 만지면 Iris가 `Custom`으로 표시할 수 있습니다. 원래 프리셋으로 되돌리려면 profile을 다시 선택합니다.

## 변경 내역

### 0.1.7

- 물 reflected-geometry pass를 다시 튜닝해 ripple/noise/normal perturbation이 screen-space처럼 미끄러지지 않고 world-space XZ 좌표에 고정되도록 했습니다.
- 반사 벡터, Fresnel 반응, view-dependent intensity는 camera/view direction 기준을 유지해 시점 변화에 따른 자연스러운 반사 변화가 남도록 했습니다.
- `balanced` reflected-geometry tracing을 24 step / 82 block max distance와 더 강한 final blend로 올렸습니다. `low`는 계속 꺼지고, `cinematic`은 같은 경로를 더 강하게 씁니다.
- shallow/deep water depth fade, distance fade, 절제된 blur를 추가해 나무와 지형 반사는 읽히지만 물 표면이 평평한 거울처럼 과해지지 않게 했습니다.
- water reflection 진단 문서를 갱신하고 Iris에서 바로 테스트할 수 있는 `Client-GLSL-Shaderpack-Lab-0.1.7-mc1.20.1.zip`을 다시 만들었습니다.

### 0.1.6

- `DEBUG_VIEW`를 material debug program처럼 확장해 material class, smoothness/roughness/glass, reflectance/height/PBR, block-light/emissive/porosity, normal/AO, glass/up/water 시각화를 추가했습니다.
- material buffer contract와 Iris 디버그 절차를 정리한 `MATERIAL_DEBUG_DIAGNOSIS.md`를 추가했습니다.
- 릴리스 zip에 material debug 진단 문서를 포함했습니다.

### 0.1.5

- vanilla glass block, tinted glass, glass pane, stained glass 계열을 별도 glass material로 매핑했습니다.
- 유리 색은 투명하게 보존하면서 약한 표면 결, 낮은 fake chromatic split, 안정적인 smoothness, 낮은 porosity, Fresnel edge reflection을 적용했습니다.
- `balanced`/`cinematic` profile에서 유리 반사는 올리되 cyber 스타일 색분리는 낮게 유지하도록 값을 조정했습니다.

### 0.1.4

- 돌, 벽돌, deepslate, blackstone, sandstone, quartz, prismarine brick, tile류 block에만 선택적으로 적용되는 LabPBR `_n` 알파 height parallax/POM을 추가했습니다.
- `POM_STRENGTH`, `POM_STEPS`, `POM_DEPTH_SCALE`을 Iris 설정과 profile preset에 추가했습니다. `low`에서는 꺼지고, `balanced`에서는 중간, `cinematic`에서는 강하게 켜집니다.
- `POM_PARALLAX_DIAGNOSIS.md`를 추가하고 Iris에서 바로 테스트 가능한 release zip에 포함했습니다.

### 0.1.3

- `Vanilla-PBR-Generated.zip` 기준으로 유리, 금속, 얼음, 돌 PBR 반응을 차분하게 튜닝했습니다.
- PBR AO, normal, reflectance, height warp, porosity, final fresnel 값을 `low`, `balanced`, `cinematic` Iris profile에서 같이 조절되게 노출했습니다.
- 생성형 normal/height 맵이 smooth reflective material에서 반사 흔들림을 만들지 않도록 shader 쪽 normal/height 영향도 낮췄습니다.
- 릴리스 zip에 README와 water-reflection 진단 문서를 포함하도록 패키징을 맞췄습니다.

### 0.1.2

- 얼음 material을 별도로 매핑해 물과 얼음이 다른 표면으로 보이게 했습니다.
- 진짜 밤 시간대에만 은하수, 별, 별똥별이 보이도록 추가했습니다.
- 릴리스 zip은 `shaders/`와 `pack.mcmeta`만 포함하는 shaderpack-only 구성으로 다시 빌드했습니다.

### 0.1.1

- vegetation vertex wind를 제거해 정지 상태에서 풀/잎 움직임 때문에 주변 블록 그림자가 흔들려 보이는 문제를 막았습니다.
- 블록 경계에서 불안정하던 RT local shadow 기여를 낮췄습니다.
- direct shadow, SSAO, RT local lighting, water mask를 분리해서 볼 수 있는 debug view를 추가했습니다.
- 물 내부 시야에 haze, soft blur, 약한 refraction drift를 추가해 더 뿌연 in-water look을 만들었습니다.
- 얼음 material 분리와 밤하늘 은하수/별/별똥별 합성을 추가했습니다.
- 릴리스 zip을 `Client-GLSL-Shaderpack-Lab-0.1.1-mc1.20.1.zip`로 다시 빌드했습니다.

## 현재 한계

- screen-space RT local lighting은 보이는 emissive source에 의존합니다. block-light fallback은 full voxel light list가 아니라 안정적인 근사입니다.
- 물의 reflected-geometry texture는 half-resolution Iris pass이며, depth buffer와 화면 안에 보이는 geometry에 제한됩니다. 실제 second mirrored world render는 아닙니다.

## 다음 목표

- 실제 resource-pack height map으로 한 번 더 인게임 확인한 뒤 selective POM block list와 height scale을 미세 조정합니다.
