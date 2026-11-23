extends SceneTree

func _initialize() -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    assert(packed != null, "Main scene must load")
    var instance: Node = packed.instantiate()
    assert(instance is Node3D, "Root must be a 3D scene")
    root.add_child(instance)
    await process_frame
    assert(instance.has_node("WorldBuilder"), "WorldBuilder must be composed")
    assert(instance.has_node("Player"), "Player must be composed")
    assert(instance.has_node("EncounterManager"), "EncounterManager must be composed")
    assert(instance.has_node("GameUI"), "GameUI must be composed")
    var encounter_node: Node = instance.get_node("EncounterManager")
    assert(encounter_node.get_child_count() == 15, "Both encounter sites must spawn 15 hostiles")
    for enemy in encounter_node.get_children():
        assert(enemy.is_inside_tree(), "Spawned enemy must be inside the scene tree")
        assert(enemy.is_in_group("hostiles"), "Spawned enemy must register as hostile")
        assert(enemy.global_position.distance_to(enemy.home_position) < 0.01, "Spawned enemy must retain its authored home position")
    var ui_node: Node = instance.get_node("GameUI")
    assert(ui_node.has_method("get_visual_contract"), "GameUI visual contract must load")
    var required_scripts := [
        "res://scripts/virtual_joystick.gd",
        "res://scripts/world_builder.gd",
        "res://scripts/player_controller.gd",
        "res://scripts/enemy_controller.gd",
        "res://scripts/game_ui.gd"
    ]
    for script_path in required_scripts:
        assert(ResourceLoader.load(script_path) != null, "Required script must compile: " + script_path)
    print("GLYPHFALL native scene smoke test: PASS")
    paused = false
    instance.queue_free()
    quit()
