# GLYPHFALL — The Broken World

Arabic-first 3D survival-action game prototype packaged for Android in landscape orientation.

## Included in this repository

- The complete current landscape HTML/Three.js prototype under `app/src/main/assets/index.html`.
- Android Java WebView host with immersive full-screen presentation.
- Local asset delivery through AndroidX `WebViewAssetLoader` using the secure `https://appassets.androidplatform.net` origin.
- JavaScript and DOM storage for the game's current controls, settings and local progress data.
- Landscape-only Android activity, game icon, and lifecycle/back-button integration.
- Automated source verification and encounter-zone/melee regression tests.
- GitHub Actions workflow that builds and publishes a debug APK artifact on every push to `main`.

## Build locally

Use JDK 17, Android SDK Platform 36, and Gradle 9.6.0:

```bash
node scripts/verify-game.cjs
node tests/encounter-zones.test.cjs
node tests/android-shell.test.cjs
gradle --no-daemon :app:assembleDebug
```

APK output:

`app/build/outputs/apk/debug/app-debug.apk`

## Build on GitHub

Push to `main` or run **Actions → Build GLYPHFALL Android APK → Run workflow**. Download the `GLYPHFALL-Android-APK` artifact from the completed workflow run.

## Runtime note

The HTML scene is bundled locally, but Three.js 0.160.0 and its official example modules are loaded from the pinned jsDelivr CDN URL in the import map. The first launch and 3D runtime therefore require internet access. No user account, paid API, or in-app purchase SDK is required by this Android shell.

## Project status and scope

This is an installable Android build of the current playable prototype, not a claim that every planned campaign, quest, animation, environment asset, save-sync service, or production optimization described in the design document is complete. The original game document explicitly places substantial story and progression content in future development scope. Device testing is still required before a public release.

## Android identity

- Application ID (debug): `com.glyphfall.game.debug`
- Minimum Android: 7.0 / API 24
- Target Android: API 36
- Screen: landscape
