extends SceneTree

func _initialize() -> void:
    print("scene-smoke: load")
    var packed: PackedScene = load("res://scenes/main.tscn")
    if packed == null:
        _fail("Main scene must load")
        return

    var instance: Node = packed.instantiate()
    if not instance is Node3D:
        _fail("Main scene root must be Node3D")
        return

    root.add_child(instance)
    await process_frame
    print("scene-smoke: scene-ready")

    for required_node in ["WorldBuilder", "Player", "EncounterManager", "GameUI"]:
        if not instance.has_node(required_node):
            _fail("Required main-scene node is missing: " + required_node)
            instance.queue_free()
            return

    var encounter_node: Node = instance.get_node("EncounterManager")
    if encounter_node.get_child_count() != 15:
        _fail("Both encounter sites must spawn 15 hostiles; found " + str(encounter_node.get_child_count()))
        instance.queue_free()
        return

    for enemy in encounter_node.get_children():
        if not enemy.is_inside_tree():
            _fail("Spawned enemy must be inside the scene tree")
            instance.queue_free()
            return
        if not enemy.is_in_group("hostiles"):
            _fail("Spawned enemy must register as hostile")
            instance.queue_free()
            return
        var position_error: float = enemy.global_position.distance_to(enemy.home_position)
        if position_error >= 0.01:
            _fail("Spawned enemy is not at its authored home position: " + str(position_error))
            instance.queue_free()
            return

    var ui_node: Node = instance.get_node("GameUI")
    if not ui_node.has_method("get_visual_contract"):
        _fail("GameUI visual contract must load")
        instance.queue_free()
        return

    var required_scripts := [
        "res://scripts/virtual_joystick.gd",
        "res://scripts/world_builder.gd",
        "res://scripts/player_controller.gd",
        "res://scripts/enemy_controller.gd",
        "res://scripts/game_ui.gd"
    ]
    for script_path in required_scripts:
        if ResourceLoader.load(script_path) == null:
            _fail("Required script must compile: " + script_path)
            instance.queue_free()
            return

    print("GLYPHFALL native scene smoke test: PASS")
    paused = false
    instance.queue_free()
    quit(0)

func _fail(message: String) -> void:
    printerr("GLYPHFALL native scene smoke test: FAIL — " + message)
    quit(1)
