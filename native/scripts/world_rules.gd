extends RefCounted
class_name WorldRules

const SAFE_HAVEN_RADIUS: float = 42.0
const WORLD_LIMIT: float = 235.0
const VALID_CLASSES: PackedStringArray = ["vanguard", "phantom", "bastion"]

const CLASS_PROFILES: Dictionary = {
    "vanguard": {
        "id": "vanguard",
        "name": "الحارس",
        "title": "VANGUARD",
        "role": "guardian",
        "weapon": "RELIC LONGSWORD",
        "weapon_ar": "سيف الأثر والدرع",
        "ability": "AEGIS SURGE",
        "ability_ar": "اندفاع الحارس",
        "description": "مقاتل متزن يصدّ الضربات ويردّ الهجوم بموجة مضيئة.",
        "health": 145.0,
        "stamina": 110.0,
        "damage": 1.0,
        "speed": 7.0,
        "guard": 0.78,
        "cooldown": 8.0,
        "accent": Color(0.18, 0.83, 1.0)
    },
    "phantom": {
        "id": "phantom",
        "name": "الشبح",
        "title": "PHANTOM",
        "role": "assassin",
        "weapon": "TWIN WRAITH BLADES",
        "weapon_ar": "النصلان الطيفيان",
        "ability": "SHADOW RIP",
        "ability_ar": "شق الظلال",
        "description": "مقاتل سريع يدمج التفادي والضربات المتتابعة.",
        "health": 105.0,
        "stamina": 130.0,
        "damage": 1.18,
        "speed": 9.2,
        "guard": 0.38,
        "cooldown": 6.0,
        "accent": Color(0.7, 0.32, 1.0)
    },
    "bastion": {
        "id": "bastion",
        "name": "الحصن",
        "title": "BASTION",
        "role": "breaker",
        "weapon": "RUIN MAUL",
        "weapon_ar": "مطرقة الانهيار",
        "ability": "QUAKE SLAM",
        "ability_ar": "زلزال الحصن",
        "description": "مقاتل ثقيل يمتص الضرر ويسحق الخصوم بضربة أرضية.",
        "health": 190.0,
        "stamina": 95.0,
        "damage": 1.32,
        "speed": 5.7,
        "guard": 0.9,
        "cooldown": 11.0,
        "accent": Color(1.0, 0.62, 0.2)
    }
}

static func is_safe_haven(position: Vector3) -> bool:
    return Vector2(position.x, position.z).length() < SAFE_HAVEN_RADIUS

static func is_inside_site(position: Vector3, center: Vector3, radius: float) -> bool:
    return radius > 0.0 and Vector2(position.x - center.x, position.z - center.z).length() <= radius

static func can_enemy_engage(
    enemy_position: Vector3,
    player_position: Vector3,
    site_center: Vector3,
    site_radius: float,
    aggro_radius: float
) -> bool:
    if site_radius <= 0.0 or aggro_radius <= 0.0:
        return false
    if not is_inside_site(player_position, site_center, site_radius):
        return false
    if not is_inside_site(enemy_position, site_center, site_radius):
        return false
    var distance := Vector2(
        player_position.x - enemy_position.x,
        player_position.z - enemy_position.z
    ).length()
    return distance <= aggro_radius

static func is_inside_world(position: Vector3, margin: float = 0.0) -> bool:
    var limit := maxf(0.0, WORLD_LIMIT - margin)
    return absf(position.x) <= limit and absf(position.z) <= limit

static func class_profile(class_id: String) -> Dictionary:
    var key := class_id.to_lower()
    if not CLASS_PROFILES.has(key):
        key = "vanguard"
    return CLASS_PROFILES[key].duplicate(true)

static func all_class_profiles() -> Array[Dictionary]:
    var profiles: Array[Dictionary] = []
    for class_id in VALID_CLASSES:
        profiles.append(class_profile(class_id))
    return profiles

static func is_valid_class(class_id: String) -> bool:
    return VALID_CLASSES.has(class_id.to_lower())
