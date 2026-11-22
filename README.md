# GLYPHFALL — The Broken World

Arabic-first, landscape 3D survival-action game for Android.

## Current delivery baseline

The project is initialized from the latest GLYPHFALL landscape HTML prototype and packaged inside a native Android WebView shell. Three.js remains the renderer. Android build output is produced by GitHub Actions as a downloadable APK artifact.

## Build

A push to `main` triggers `.github/workflows/android-apk.yml`. The workflow builds the debug APK and uploads it as `GLYPHFALL-Android-APK`.

## Requirements

- Android 7.0+ (API 24+)
- Android System WebView / Chrome WebView provider
- Internet connection for the pinned Three.js modules loaded from jsDelivr
- Landscape screen orientation

## Important scope note

This repository's initial commit contained no files. This project is being initialized from the supplied playable GLYPHFALL HTML prototype. A complete commercial-scale open-world game requires further content, systems, asset production, and device QA beyond packaging the prototype.
