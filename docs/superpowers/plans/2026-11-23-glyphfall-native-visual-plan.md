# GLYPHFALL Native Visual Upgrade Implementation Plan

> **For agentic workers:** Implement this plan natively in this session, task by task. Steps use checkbox syntax.

**Goal:** Build a native, landscape Android GLYPHFALL vertical slice with premium visual direction, class roster, melee combat, bounded encounter sites, and an APK build pipeline.

**Architecture:** Keep the existing Three.js/WebView project intact as a fallback. Add an isolated Godot 4.7.2 project under `native/`; use GDScript modules for rules, world generation, player, enemy, UI, and application coordination. Build/export through a dedicated GitHub Actions workflow.

**Tech Stack:** Godot 4.7.2 Stable, GDScript, Godot Mobile renderer, procedural 3D meshes, SVG UI assets, GitHub Actions, Android arm64 APK.

**Spec:** `docs/superpowers/specs/2026-11-23-glyphfall-native-visual-design.md`

## Global Constraints

- Engine is Godot 4.7.2 Stable, not an unstable 4.8 beta.
- Android orientation is landscape.
- Renderer is `mobile`, not Forward+.
- No external paid API, account backend, or player firearms.
- Old WebView project and its existing workflow remain intact.
- APK app ID is `com.glyphfall.game`.
- Use adaptive quality; never force 4K/8K across all phones.

## Review Focus

- Corrupt/unknown save version must fall back to defaults; test invalid and missing save values.
- Player cannot leave the world bounds or fall through terrain; test movement limits and terrain height.
- Enemies outside their encounter radius must return home; test site radius and aggro radius boundaries.
- UI taps must not trigger world attacks through an overlay; test signal routing and input blocking.
- Scene generation must remain bounded on mobile; test deterministic counts and avoid unbounded per-frame allocations.

---

### Task 1: Project shell and deterministic rules

**Files:**
- Create: `native/project.godot`
- Create: `native/scenes/main.tscn`
- Create: `native/scripts/world_rules.gd`
- Create: `native/tests/test_world_rules.gd`
- Create: `native/assets/icon.svg`

**Interfaces:**
- `WorldRules.is_safe_haven(position: Vector3) -> bool`
- `WorldRules.is_inside_site(position: Vector3, center: Vector3, radius: float) -> bool`
- `WorldRules.can_enemy_engage(enemy_position, player_position, site_center, site_radius, aggro_radius) -> bool`
- `WorldRules.class_profile(class_id: String) -> Dictionary`

- [ ] Write tests for safe radius, site boundary, aggro boundary, unknown class defaults.
- [ ] Run tests headlessly and confirm expected missing-script/test failures.
- [ ] Implement rules, project config, main scene, and original icon.
- [ ] Run headless project import and rules tests.

### Task 2: Native world rendering

**Files:**
- Create: `native/scripts/world_builder.gd`
- Create: `native/shaders/water.gdshader`
- Create: `native/tests/test_world_builder.gd`
- Create: `native/assets/main_keyart.webp` (generated scene background)

**Interfaces:**
- `WorldBuilder.build_world() -> void`
- `WorldBuilder.terrain_height(x: float, z: float) -> float`
- `WorldBuilder.get_encounter_sites() -> Array[Dictionary]`

- [ ] Test deterministic terrain and exactly two forest encounter sites.
- [ ] Build terrain mesh with vertex colors, environment/sky/fog, directional shadows, water, central tower, modular settlement, forest MultiMeshes, rocks, foliage, crystals, and site markers.
- [ ] Use shared materials, instancing, capped object counts, and Mobile renderer-safe effects.
- [ ] Run headless import and world tests.

### Task 3: Player, classes, melee and enemy site AI

**Files:**
- Create: `native/scripts/player_controller.gd`
- Create: `native/scripts/enemy_controller.gd`
- Create: `native/scripts/encounter_manager.gd`
- Create: `native/tests/test_combat_rules.gd`

**Interfaces:**
- `PlayerController.select_class(class_id: String) -> void`
- `PlayerController.attack_light() -> void`
- `PlayerController.attack_heavy() -> void`
- `PlayerController.guard() -> void`
- `PlayerController.dodge(direction: Vector3) -> void`
- `PlayerController.use_class_skill() -> void`
- `EncounterManager.update_sites(player_position: Vector3) -> void`

- [ ] Test distinct melee profiles and site-bounded enemy engagement first.
- [ ] Implement touch/keyboard movement, third-person camera, melee hit checks, class weapon meshes, cooldowns, guard/dodge/skill, and enemy state transitions.
- [ ] Run combat rules and headless scene checks.

### Task 4: Main menu, roster and in-game HUD

**Files:**
- Create: `native/scripts/game_ui.gd`
- Create: `native/scripts/virtual_joystick.gd`
- Create: `native/assets/icons/*.svg`
- Create: `native/tests/test_ui_contract.gd`

**Interfaces:**
- Signals: `start_game`, `class_selected(class_id)`, `pause_requested`, `resume_requested`, `action_requested(action_id)`
- `GameUI.show_menu()`, `GameUI.show_hud()`, `GameUI.update_hud(state)`

- [ ] Test roster IDs, action button contract, start/pause/resume flow.
- [ ] Implement cinematic background overlay, Arabic/English navigation, one class roster screen, weapon/skill/stats detail, settings, HUD, minimap placeholder, joystick, and skill buttons with SVG icons.
- [ ] Verify all controls connect to real signals and have accessible sizes.

### Task 5: Persistence and application integration

**Files:**
- Create: `native/scripts/save_service.gd`
- Create: `native/scripts/main.gd`
- Modify: `native/scenes/main.tscn`
- Create: `native/tests/test_save_service.gd`

- [ ] Test missing, valid, and malformed local save files.
- [ ] Implement versioned settings/class/shard/checkpoint save with defensive parsing.
- [ ] Connect world, player, encounter manager, and UI lifecycle.

### Task 6: Android export and CI

**Files:**
- Create: `native/export_presets.cfg`
- Create: `.github/workflows/godot-android.yml`
- Modify: `README.md`
- Create: `native/tests/smoke_test.gd`

- [ ] Run source/test checks before exporting.
- [ ] Install Godot 4.7.2 Stable, matching export templates, JDK 17, and Android SDK.
- [ ] Run headless project import, smoke tests, and `--export-debug Android`.
- [ ] Verify APK file is non-empty and upload as `GLYPHFALL-NATIVE-ANDROID-APK`.
- [ ] Keep prior WebView workflow active until native APK has been tested on the user's Android device.
