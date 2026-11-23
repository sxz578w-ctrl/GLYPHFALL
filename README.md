# GLYPHFALL — The Broken World

Android-first third-person survival-action RPG set in a fractured world of ancient ruins, anomaly forests, and safe havens.

## Active engine

The active visual/gameplay foundation is **Godot 4.7.2 Stable**, GDScript, and the Mobile renderer. The earlier Three.js/WebView prototype remains under `app/` as a fallback while native parity is developed.

## Native project

Open `native/project.godot` with Godot 4.7.2 Stable.

- Landscape-first, Arabic-first UI.
- Main roster screen with VANGUARD, PHANTOM, and BASTION.
- Third-person player controller and signature melee weapons.
- SAFE HAVEN settlement, outskirts, Mirkwood, Sunken Grove, and bounded encounter sites.
- Enemy AI is site-bound; enemies do not pursue outside their owning encounter radius.
- Versioned local settings/progression save.
- Touch joystick, attack, heavy strike, guard, dodge, skill, interact, rebuild, and pause controls.
- Scalable SVG scene art, class emblems, combat iconography, and app identity.
- Performance, Balanced, and High graphics presets; adaptive 3D render scale.

## Native Android APK

The workflow `.github/workflows/godot-android.yml` downloads the matching Godot 4.7.2 Stable editor and export templates, installs JDK 17 and Android SDK dependencies, runs headless tests, exports the APK, verifies the package ID, and uploads the `GLYPHFALL-NATIVE-ANDROID-APK` artifact.

A push to `main` that changes `native/**` starts the build automatically. The latest APK is downloaded from the successful GitHub Actions run.

## Local build requirements

- Godot 4.7.2 Stable (standard build, not .NET)
- OpenJDK 17
- Android SDK Platform 35, Build Tools 35.0.1, Platform Tools, NDK 28.1.13356709, CMake 3.10.2.4988404
- Matching Godot 4.7.2 export templates

Export preset: `Android`

```bash
godot --headless --editor --path native --quit
godot --headless --path native --script res://tests/test_world_rules.gd
godot --headless --path native --script res://tests/test_combat_rules.gd
godot --headless --path native --script res://tests/test_save_service.gd
godot --headless --path native --script res://tests/test_world_builder.gd
godot --headless --path native --script res://tests/test_ui_contract.gd
godot --headless --path native --script res://tests/smoke_test.gd
godot --headless --path native --export-debug Android build/GLYPHFALL-Android.apk
```

## Scope and quality statement

This is a native, playable vertical slice and a scalable foundation, not a finished commercial AAA release. It uses procedural/primitive 3D geometry and custom vector art; it does not yet contain a full authored campaign, production character rigging, motion-captured animation, voice acting, multiplayer, or a large professionally authored asset library. These are separate production milestones. Device testing is required before public release.

## Legacy fallback

The previous Three.js/WebView prototype remains in `app/src/main/assets/index.html` and can still be built through `.github/workflows/android-apk.yml`.
