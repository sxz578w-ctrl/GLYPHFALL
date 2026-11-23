extends SceneTree

const WorldRules = preload("res://scripts/world_rules.gd")

func _initialize() -> void:
    var vanguard := WorldRules.class_profile("vanguard")
    var phantom := WorldRules.class_profile("phantom")
    var bastion := WorldRules.class_profile("bastion")
    assert(float(phantom["speed"]) > float(vanguard["speed"]))
    assert(float(bastion["health"]) > float(vanguard["health"]))
    assert(float(bastion["damage"]) > float(phantom["damage"]))
    assert(float(vanguard["guard"]) > float(phantom["guard"]))
    assert(WorldRules.can_enemy_engage(Vector3(10, 0, 0), Vector3(18, 0, 0), Vector3.ZERO, 40.0, 12.0))
    assert(not WorldRules.can_enemy_engage(Vector3(10, 0, 0), Vector3(42, 0, 0), Vector3.ZERO, 40.0, 12.0))
    print("GLYPHFALL native combat-profile tests: PASS")
    quit()
