extends SceneTree

const WorldRules = preload("res://scripts/world_rules.gd")

func _initialize() -> void:
    _test_safe_haven_radius()
    _test_encounter_boundaries()
    _test_enemy_never_chases_outside_owned_site()
    _test_class_profiles_are_distinct()
    _test_world_bounds()
    print("GLYPHFALL native world-rule tests: PASS")
    quit()

func _test_safe_haven_radius() -> void:
    assert(WorldRules.is_safe_haven(Vector3(0, 0, 0)))
    assert(WorldRules.is_safe_haven(Vector3(40, 0, 0)))
    assert(not WorldRules.is_safe_haven(Vector3(42, 0, 0)))

func _test_encounter_boundaries() -> void:
    var center := Vector3(100, 0, -40)
    assert(WorldRules.is_inside_site(center, center, 36.0))
    assert(WorldRules.is_inside_site(center + Vector3(36, 0, 0), center, 36.0))
    assert(not WorldRules.is_inside_site(center + Vector3(36.1, 0, 0), center, 36.0))

func _test_enemy_never_chases_outside_owned_site() -> void:
    var site := Vector3(150, 0, 20)
    var enemy := site + Vector3(3, 0, 0)
    assert(WorldRules.can_enemy_engage(enemy, site + Vector3(8, 0, 0), site, 40.0, 16.0))
    assert(not WorldRules.can_enemy_engage(enemy, site + Vector3(25, 0, 0), site, 40.0, 16.0))
    assert(not WorldRules.can_enemy_engage(enemy, site + Vector3(41, 0, 0), site, 40.0, 16.0))
    assert(not WorldRules.can_enemy_engage(enemy, site + Vector3(8, 0, 0), site, 40.0, 2.0))

func _test_class_profiles_are_distinct() -> void:
    var vanguard: Dictionary = WorldRules.class_profile("vanguard")
    var phantom: Dictionary = WorldRules.class_profile("phantom")
    var bastion: Dictionary = WorldRules.class_profile("bastion")
    assert(vanguard["weapon"] != phantom["weapon"])
    assert(phantom["weapon"] != bastion["weapon"])
    assert(vanguard["ability"] != phantom["ability"])
    assert(phantom["ability"] != bastion["ability"])
    assert(vanguard["role"] == "guardian")
    assert(phantom["role"] == "assassin")
    assert(bastion["role"] == "breaker")

func _test_world_bounds() -> void:
    assert(WorldRules.is_inside_world(Vector3(0, 0, 0)))
    assert(WorldRules.is_inside_world(Vector3(235, 0, -235)))
    assert(not WorldRules.is_inside_world(Vector3(236, 0, 0)))
