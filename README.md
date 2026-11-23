# GLYPHFALL — The Broken World

**Native Android build:** Godot 4.7.2 Stable · GDScript · Mobile renderer · Landscape · Arabic-first UI.

## Visual Ascension 0.3.0

- Eclipse Frontier visual identity with a cinematic scalable SVG main-menu background and custom app mark.
- A redesigned single-screen class roster with three class identities, signature weapons, ability labels and clear selected states.
- Redesigned combat/action icon set for attack, heavy attack, guard, dodge, skill, interact, rebuild, map, pause and settings.
- Revised safe-haven architecture with facade courses, deep window frames, door recesses, rooftop silhouettes, banners, market stalls and beacons.
- Higher-density terrain, layered conifer silhouettes, broadleaf forest, instanced understory and crystal gardens.
- Sentinel, Wraith and Brute encounter silhouettes while preserving site-bounded engagement.
- Filmic sky, selective glow/fog, reflective anomaly water and Performance/Balanced/High/Ultra quality options.
- MultiMesh batching for repeated vegetation, window details and architectural trim to control mobile draw calls.

## Build and verify

The repository contains two GitHub Actions pipelines:
- **GLYPHFALL Godot Native Tests** — imports the native project, validates world/combat/save/UI contracts, visual acceptance and scene startup.
- **GLYPHFALL Native Android APK** — imports and tests the project, exports an arm64 Android APK, validates the package and uploads the APK artifact.

Run manually from GitHub: **Actions → GLYPHFALL Native Android APK → Run workflow**.

## Android requirements

- Android 7.0+ (API 24+), ARM64
- Landscape display
- Godot 4.7.2 Android export templates installed in CI
- No paid API or account required
- Internet permission is disabled in the Android preset; all current runtime assets are bundled in the APK.

## Graphics profiles

- Performance: 0.68 3D scale, no MSAA
- Balanced: 0.82 scale, MSAA 2×
- High: 1.00 scale, MSAA 4×
- Ultra: 1.15 scale, MSAA 4×

Ultra is device-dependent. It does not force 4K/8K render targets on phones; SVG art scales cleanly, while the 3D render scale adapts to device GPU and thermal limits.

## Release scope

Version 0.3.0 is a native Android visual/gameplay vertical slice. It is not a commercial AAA-complete game. Planned story chapters, authored cinematic animation sets, full quest/content pipeline, multiplayer, additional biomes, platform certification, extensive device QA and a production-scale 3D asset library remain future production work.
