# GLYPHFALL — Eclipse Frontier Visual & Native Android Design

**Date:** 2026-11-23  
**Status:** Approved by explicit execution instruction (no clarification round)  
**Target:** Android landscape, Arabic-first, third-person survival action

## Vision

GLYPHFALL becomes a premium-feeling, mobile-first third-person action RPG set in a broken world being reclaimed by nature and anomalous energy. The world should communicate scale, material depth, atmosphere, readable landmarks, and intentional exploration. Safe havens are social/upgrade spaces; hostile creatures remain bound to their encounter sites, forests, ruins, and anomaly arenas. Combat remains melee-first: each class owns a signature weapon, guard/dodge loop, and class skill.

The reference direction is cinematic and anime-fantasy inspired by modern mobile RPGs. Use the genre conventions, not copyrighted character designs, logos, UI copies, or assets from other games.

## Approaches considered

1. **Polish the existing Three.js/WebView application.** Fastest and preserves current gameplay, but leaves the product tied to a browser wrapper, manual rendering code, and a weak asset/scene pipeline.
2. **Replace the WebView game immediately with an Unreal-scale production.** Visually ambitious but mismatched to a phone-only, zero-budget workflow and would require a much larger native content/toolchain investment.
3. **Recommended: add a native Godot project while retaining the HTML build as fallback.** Godot 4.7.2 Stable + GDScript + the Mobile renderer provides native Android rendering, scene composition, 3D materials, lights/shadows, UI controls, resource import, and reproducible headless export. It is the strongest practical free/open-source path for this Android-first project. The native project is the active visual foundation; the old WebView build remains available until feature parity is established.

## Goals

- Replace the browser shell with an installable native Android game build.
- Lock to landscape and build touch-first controls.
- Deliver one unified main menu with profile, play, class selection, events, settings, and clear visual hierarchy.
- Make class selection a single roster screen with three complete class profiles: VANGUARD (longsword + shield), PHANTOM (dual blades), BASTION (war maul).
- Render a readable world with real solid terrain, a safe-haven settlement, landmark tower, forests, ruins, rocks, vegetation, water, crystals, and encounter clearings.
- Give each class distinct weapon silhouette, movement profile, defensive action, dodge, and special ability.
- Keep enemies dormant outside named combat sites and prevent pursuit beyond encounter boundaries.
- Add polished in-game HUD, responsive touch joystick/buttons, pause/settings, and clear zone state.
- Build APK through GitHub Actions and preserve automated verification.

## Non-goals for this visual milestone

- No online multiplayer, live-service backend, social guilds, or server-side accounts.
- No claim of commercial AAA content scale, cinematic skeletal animation, full quest campaign, or production-certified performance.
- No 8K texture requirement. Use adaptive resolution and texture quality; 8K textures are inappropriate as a universal mobile default and can exceed device memory. Upscale only where hardware permits.

## UX/UI direction

- Landscape 16:9 composition, Arabic RTL labels with English class names and technical sublabels.
- Dark navy/obsidian surfaces, controlled cyan and violet energy, warm gold for primary actions, red only for warnings/danger.
- Main menu: cinematic art as a background layer with readable overlay; actual buttons and data stay native interactive controls, never baked into the art.
- Character selection: one roster screen with class cards, selected hero detail panel, weapon and skill description, stat bars, and a persistent Start button.
- Combat HUD: HP/energy, objective, zone label/minimap, joystick, large attack, dodge, guard, skill, interact/rebuild actions. SVG icons have consistent stroke weight and touch hit areas.
- Dark in-game theme; no decorative light theme in this milestone because it conflicts with the world identity and readability in combat.
- Use system Arabic font fallback on Android; do not bundle proprietary fonts.

## Stack

- Godot 4.7.2 Stable, standard (non-.NET) editor and export templates.
- GDScript for gameplay, scene generation, UI, and tests.
- Godot Mobile renderer for Android. It is designed for mobile and renders simple scenes faster than Forward+, with a smaller feature set.
- Native Android APK export via Godot headless CLI and GitHub Actions.
- Procedural mesh/environment kit for the first native slice; hand-authored/imported GLTF assets can replace primitives progressively.

## World and gameplay systems

- SAFE HAVEN: enemy-free settlement with keeper, crafting/upgrade stations, class/gear access, and clear landmark tower.
- OUTSKIRTS: safe-to-explore transition area with environmental storytelling and resource pickups.
- MIRKWOOD and SUNKEN GROVE: named hunting grounds with bounded enemy activation and visible arena boundaries.
- ANCHOR SITES: opt-in combat sites with staged enemies and a clear completion state.
- CORE ARENA: isolated boss encounter.
- Enemy AI states: dormant, alert, engage, attack, return-home, defeated. Engage only inside the owning encounter radius and aggro radius.
- Class abilities: VANGUARD Aegis Surge (guard/radial counter), PHANTOM Shadow Rip (short blink + dual slash), BASTION Quake Slam (slow heavy area hit).
- No player firearms. Monster ranged pressure, if present, is anomaly magic rather than gunplay.

## Rendering and performance

- Native 3D scene with terrain mesh, vertex color/material variation, instanced vegetation/rocks, detailed building modules, emissive signage/crystals, water shader, sky, directional shadow, fog, and restrained glow.
- High quality must remain adaptive: Performance, Balanced, High presets; cap render scale based on device. Do not hard-force 4K/8K.
- Prefer MultiMesh for repeated foliage/rocks, shared materials, bounded point/particle counts, and distance-based detail.
- Preserve camera legibility and keep critical geometry in front of the player.

## Persistence and data

This milestone uses local device persistence only. Store settings, selected class, last checkpoint, and shard progression in a versioned local save file. No secrets or user credentials are stored.

## Security

- Native APK contains no API keys or private credentials.
- No remote authentication or account backend in this milestone.
- Validate saved JSON structure/version before applying values; use defaults on corrupted saves.
- Only project-owned resources are loaded at runtime.

## Acceptance criteria

1. Godot project imports and runs headlessly without parse errors.
2. Main scene opens in landscape with the main menu and three selectable classes.
3. Starting the game creates the player, terrain, landmark settlement, forests, and encounter sites.
4. Each class displays its unique weapon and profile; attacks, dodge, guard, and ability call distinct combat functions.
5. Enemies do not activate in the safe haven and cannot pursue outside their site.
6. Touch UI exposes accessible attack/guard/dodge/skill/interact controls.
7. APK export finishes in CI, output file is non-empty, and APK metadata identifies `com.glyphfall.game`.
8. The current WebView APK/project remains recoverable as a fallback until native parity is proven.
