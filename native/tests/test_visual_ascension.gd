extends SceneTree

const WorldBuilderScript = preload("res://scripts/world_builder.gd")
const GameUIScript = preload("res://scripts/game_ui.gd")
const WorldRules = preload("res://scripts/world_rules.gd")

func _initialize() -> void:
    print("visual-ascension-test: start")
    var builder = WorldBuilderScript.new()
    root.add_child(builder)
    await process_frame

    var world_contract = builder.call("get_visual_contract")
    assert(world_contract is Dictionary, "WorldBuilder must expose a visual contract")
    assert(int(world_contract.get("terrain_segments", 0)) >= 160, "terrain must have a high-detail mobile mesh")
    assert(int(world_contract.get("tree_species", 0)) >= 3, "world must provide three distinct tree silhouettes")
    assert(int(world_contract.get("architecture_modules", 0)) >= 10, "citadel architecture must be modular and detailed")
    assert(str(world_contract.get("art_direction", "")) == "eclipse_frontier", "world palette must use Eclipse Frontier")
    assert(builder.has_node("ForestUnderstory"), "forests must contain ground-level vegetation")
    assert(builder.has_node("SafeHavenDetailProps"), "safe haven must contain readable environmental props")
    assert(builder.has_node("CrystalGardens"), "crystal gardens must be visible landmarks")

    var ui = GameUIScript.new()
    root.add_child(ui)
    await process_frame
    var ui_contract = ui.call("get_visual_contract")
    assert(ui_contract is Dictionary, "GameUI must expose a visual contract")
    assert(int(ui_contract.get("class_count", 0)) == 3, "one roster screen must expose exactly three classes")
    assert(str(ui_contract.get("roster_mode", "")) == "single_screen", "class selection must remain a unified roster")
    assert(str(ui_contract.get("menu_art", "")) == "res://assets/main_keyart.svg", "cinematic menu key art must be loaded")
    assert(bool(ui_contract.get("intro_animation", false)), "menu entrance must be animated")
    assert(int(ui_contract.get("action_icon_count", 0)) >= 10, "all combat and navigation icons must exist")

    var profiles := WorldRules.all_class_profiles()
    assert(profiles.size() == 3, "all class profiles remain selectable")
    assert(str(profiles[0]["weapon"]) != str(profiles[1]["weapon"]), "class weapons must remain distinct")
    assert(str(profiles[1]["ability"]) != str(profiles[2]["ability"]), "class abilities must remain distinct")

    print("GLYPHFALL visual ascension tests: PASS")
    ui.queue_free()
    builder.queue_free()
    await process_frame
    quit(0)
