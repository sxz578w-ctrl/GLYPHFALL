extends SceneTree

const SaveService = preload("res://scripts/save_service.gd")

func _initialize() -> void:
    var defaults: Dictionary = SaveService.normalise({})
    assert(defaults["version"] == SaveService.SAVE_VERSION)
    assert(defaults["selected_class"] == "vanguard")
    var valid: Dictionary = SaveService.normalise({
        "version": SaveService.SAVE_VERSION,
        "selected_class": "phantom",
        "shards": 25,
        "quality": "high"
    })
    assert(valid["selected_class"] == "phantom")
    assert(valid["shards"] == 25)
    assert(valid["quality"] == "high")
    var invalid: Dictionary = SaveService.normalise({
        "version": 999,
        "selected_class": "../../invalid",
        "shards": -900,
        "quality": "unlimited"
    })
    assert(invalid["selected_class"] == "vanguard")
    assert(invalid["shards"] == 0)
    assert(invalid["quality"] == "balanced")
    print("GLYPHFALL native save tests: PASS")
    quit()
