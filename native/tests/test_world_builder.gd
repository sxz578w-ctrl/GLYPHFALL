extends SceneTree

const WorldBuilderScript = preload("res://scripts/world_builder.gd")

func _initialize() -> void:
    print("world-builder-test: start")
    var builder = WorldBuilderScript.new()
    if not is_finite(builder.terrain_height(0.0, 0.0)):
        _fail("terrain height at origin is not finite")
        return
    if not is_finite(builder.terrain_height(125.0, -78.0)):
        _fail("terrain height at secondary coordinate is not finite")
        return
    print("world-builder-test: terrain")
    var sites: Array = builder.get_encounter_sites()
    if sites.size() != 2:
        _fail("expected exactly two named forest encounter sites")
        return
    if sites[0]["id"] == sites[1]["id"]:
        _fail("encounter site identifiers must be unique")
        return
    if float(sites[0]["radius"]) <= 20.0 or float(sites[1]["radius"]) <= 20.0:
        _fail("both encounter sites must have useful play-space radius")
        return
    print("GLYPHFALL native world-builder tests: PASS")
    quit(0)

func _fail(message: String) -> void:
    printerr("GLYPHFALL native world-builder test failed: " + message)
    quit(1)
