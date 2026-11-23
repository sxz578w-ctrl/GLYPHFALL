# GLYPHFALL — Visual Ascension Design

**Date:** 2026-11-23  
**Target:** Android landscape; Arabic-first; Godot 4.7.2 Stable; GDScript; Mobile renderer  
**Execution:** The user explicitly delegated design and technical choices; implement directly without a clarification round.

## Product direction

Eclipse Frontier is a premium-feeling third-person survival RPG. Its art direction combines monumental dark-stone citadels, carved architectural profiles, layered forest silhouettes, deep-water reflections, crystalline anomaly light, and a restrained cyan/violet/gold color language. The game must communicate scale through composition, landmarks, material contrast, vegetation density, and atmospheric depth—not through indiscriminate polygon counts or oversized textures.

## Scope for this visual milestone

- Rebuild the safe-haven skyline with layered facades, window recesses, stone courses, pillars, roof crowns, bridges, market props, banners, lanterns and an unmistakable central beacon.
- Replace spherical tree crowns with multiple tree silhouettes, layered conifer forms, understory, ground cover and accent-biome foliage using MultiMesh for repeated assets.
- Improve terrain variation, water, crystals, lighting, shadow distance and non-volumetric atmospheric fog.
- Redesign the single-screen class roster with large class emblems, strong selected-state framing, readable stat bars, signature-weapon and ability cards, and a cinematic main-menu key art.
- Introduce a cohesive 512px SVG identity/icon system for app, hero classes and combat actions.
- Add an entrance animation and restrained interface motion; keep controls native, responsive and accessible.
- Add Performance, Balanced, High and Ultra profiles. Ultra is an optional device-dependent profile, not a promise of 4K/8K rendering on every phone.
- Preserve gameplay rules, melee combat, safe haven, site-bound enemies and local save behaviour.

## Technical decisions

- Keep Godot 4.7.2 Stable and GDScript; the repository already has a working native Android export path and gameplay systems.
- Keep the Mobile renderer for Android compatibility. Use filmic tonemapping, carefully tuned glow/fog, a directional sun, selective local lights, shared PBR materials and instanced geometry.
- Use procedural meshes for the current asset-free baseline; use SVG for scalable identity and UI marks. Keep original art files source-controlled and compressed.
- Use MultiMesh for forests, stones, market clutter and repeated facade accents to avoid hundreds of separate draw calls.
- No 8K runtime textures, no forced Forward+ features, no paid APIs, no copied franchise assets, and no claim of a commercial AAA release.

## Acceptance

- Automated Godot tests verify visual contracts, world composition, class roster and unchanged combat/world invariants.
- Headless Godot import, test suite, main-scene smoke test and Android export pass in GitHub Actions.
- APK is non-empty, zip-valid, has application ID com.glyphfall.game and is uploaded as a workflow artifact.
- A human device review is still required for real frame pacing, thermal behaviour, touch feel and final art judgement.
