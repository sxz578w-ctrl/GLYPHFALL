extends RefCounted
class_name SaveService

const SAVE_PATH: String = "user://glyphfall_save.json"
const SAVE_VERSION: int = 1
const DEFAULTS: Dictionary = {
    "version": SAVE_VERSION,
    "selected_class": "vanguard",
    "shards": 0,
    "damage_rank": 0,
    "vitality_rank": 0,
    "quality": "balanced",
    "music_volume": 0.7,
    "effects_volume": 0.8,
    "checkpoint": "safe_haven"
}

static func normalise(raw_data: Variant) -> Dictionary:
    var result: Dictionary = DEFAULTS.duplicate(true)
    if not raw_data is Dictionary:
        return result
    if int(raw_data.get("version", -1)) != SAVE_VERSION:
        return result

    var selected_class := str(raw_data.get("selected_class", "vanguard")).to_lower()
    if WorldRules.is_valid_class(selected_class):
        result["selected_class"] = selected_class

    result["shards"] = clampi(int(raw_data.get("shards", 0)), 0, 999999999)
    result["damage_rank"] = clampi(int(raw_data.get("damage_rank", 0)), 0, 10)
    result["vitality_rank"] = clampi(int(raw_data.get("vitality_rank", 0)), 0, 10)

    var quality := str(raw_data.get("quality", "balanced")).to_lower()
    if ["performance", "balanced", "high", "ultra"].has(quality):
        result["quality"] = quality

    result["music_volume"] = clampf(float(raw_data.get("music_volume", 0.7)), 0.0, 1.0)
    result["effects_volume"] = clampf(float(raw_data.get("effects_volume", 0.8)), 0.0, 1.0)

    var checkpoint := str(raw_data.get("checkpoint", "safe_haven"))
    if ["safe_haven", "outskirts", "mirkwood", "sunken_grove"].has(checkpoint):
        result["checkpoint"] = checkpoint

    result["version"] = SAVE_VERSION
    return result

static func load_save() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return DEFAULTS.duplicate(true)
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return DEFAULTS.duplicate(true)
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    return normalise(parsed)

static func write_save(raw_data: Dictionary) -> bool:
    var safe_data := normalise(raw_data)
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(safe_data, "\t"))
    file.close()
    return true
