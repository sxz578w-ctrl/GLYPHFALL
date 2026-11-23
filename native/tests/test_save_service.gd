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
        "damage_rank": 4,
        "vitality_rank": 3,
        "quality": "high"
    })
    assert(valid["selected_class"] == "phantom")
    assert(valid["shards"] == 25)
    assert(valid["damage_rank"] == 4)
    assert(valid["vitality_rank"] == 3)
    assert(valid["quality"] == "high")
    var invalid: Dictionary = SaveService.normalise({
        "version": 999,
        "selected_class": "../../invalid",
        "shards": -900,
        "damage_rank": 900,
        "vitality_rank": -20,
        "quality": "unlimited"
    })
    assert(invalid["selected_class"] == "vanguard")
    assert(invalid["shards"] == 0)
    assert(invalid["damage_rank"] == 0)
    assert(invalid["vitality_rank"] == 0)
    assert(invalid["quality"] == "balanced")
    var partial: Dictionary = SaveService.normalise({
        "version": SaveService.SAVE_VERSION,
        "selected_class": "bastion",
        "shards": 50,
        "music_volume": 4.0,
        "effects_volume": -2.0
    })
    assert(partial["music_volume"] == 1.0)
    assert(partial["effects_volume"] == 0.0)
    print("GLYPHFALL native save tests: PASS")
    quit()
