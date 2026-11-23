# GLYPHFALL Visual Ascension — Implementation Plan

## Task 1 — Lock the visual contract (TDD)
- Add `native/tests/test_visual_ascension.gd`.
- Assert terrain segment count, at least three tree silhouettes, modular architecture count, world-detail nodes, cinematic art path, intro treatment, three class cards and ten combat/UI icons.
- Add this test to both Godot test and Android export workflows.
- Confirm it fails because the new visual-contract APIs and scene nodes do not exist yet.

## Task 2 — Native environment and world
- Add WorldBuilder visual contract and stable public reports.
- Raise terrain mesh density within mobile limits; tune sky, tonemapping, fog, glow and sun/shadow.
- Replace sphere canopies with three instanced tree silhouettes and add forest understory, ground cover and landmark props.
- Upgrade buildings with facade depth, stone courses, cornices, buttresses, roof detail, window frames/mullions, banners, stairs and lamps.
- Add a crystal garden and richer water/shore accents.
- Run world-builder tests and smoke test.

## Task 3 — Character and enemy art pass
- Strengthen class silhouettes and PBR material separation.
- Give Vanguard a long relic sword and shield silhouette; Phantom twin curved blades and light armour; Bastion broad armour and large maul.
- Introduce three enemy silhouettes while preserving the same site-bounded AI state machine.
- Run combat and world-rule tests.

## Task 4 — UX/UI and identity
- Create a unified art system for background, app icon, hero portraits and combat icons.
- Improve the single roster composition, selected-class details, stat visualisation and entrance transition.
- Improve HUD hierarchy and icon sizing/hit areas without changing action signal contracts.
- Add Ultra graphics option while preserving adaptive lower presets.
- Run UI contract and visual ascension tests.

## Task 5 — Verify and ship
- Run Godot headless import, all native tests, scene smoke test and Android export.
- Inspect export logs and APK validation.
- Upload APK artifact and verify artifact metadata and digest.
- Report actual platform/device limitations and remaining AAA production gaps.
