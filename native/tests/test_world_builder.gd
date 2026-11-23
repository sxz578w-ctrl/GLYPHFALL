extends SceneTree

const WorldBuilder = preload("res://scripts/world_builder.gd")

func _initialize() -> void:
    var builder = WorldBuilder.new()
    assert(is_finite(builder.terrain_height(0.0, 0.0)))
    assert(is_finite(builder.terrain_height(125.0, -78.0)))
    var sites: Array = builder.get_encounter_sites()
    assert(sites.size() == 2)
    assert(sites[0]["id"] != sites[1]["id"])
    assert(sites[0]["radius"] > 20.0)
    assert(sites[1]["radius"] > 20.0)
    print("GLYPHFALL native world-builder tests: PASS")
    quit()
