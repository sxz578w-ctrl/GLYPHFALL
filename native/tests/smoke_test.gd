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
    assert(instance.has_node("GameUI"), "GameUI must be composed")
    print("GLYPHFALL native scene smoke test: PASS")
    instance.queue_free()
    quit()
