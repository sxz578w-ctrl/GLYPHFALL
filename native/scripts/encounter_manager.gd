extends Node
class_name EncounterManager

signal shards_awarded(amount: int)
signal site_discovered(site_id: String)
signal site_cleared(site_id: String)

const EnemySceneScript = preload("res://scripts/enemy_controller.gd")
const ProgressionService = preload("res://scripts/progression_service.gd")

var player: PlayerController
var world_builder: WorldBuilder
var site_enemies: Dictionary = {}
var _current_site_id: String = ""
var _discovered_sites: Dictionary = {}
var _cleared_sites: Dictionary = {}
var _remaining_by_site: Dictionary = {}

func configure(target: PlayerController, world: WorldBuilder, discovered_sites: Array = [], cleared_sites: Array = []) -> void:
    player = target
    world_builder = world
    for site_id in discovered_sites:
        var discovered_id := str(site_id)
        if ProgressionService.SITE_IDS.has(discovered_id):
            _discovered_sites[discovered_id] = true
    for site_id in cleared_sites:
        var cleared_id := str(site_id)
        if ProgressionService.SITE_IDS.has(cleared_id):
            _discovered_sites[cleared_id] = true
            _cleared_sites[cleared_id] = true
    _spawn_site_enemies()

func _process(_delta: float) -> void:
    if player == null or world_builder == null:
        return
    var new_site := ""
    for site in world_builder.get_encounter_sites():
        var center: Vector3 = site["center"]
        var distance := Vector2(player.global_position.x - center.x, player.global_position.z - center.z).length()
        if distance <= float(site["radius"]):
            new_site = str(site["id"])
            break
    _current_site_id = new_site
    if not new_site.is_empty() and not _discovered_sites.has(new_site):
        _discovered_sites[new_site] = true
        site_discovered.emit(new_site)

func get_current_site_id() -> String:
    return _current_site_id

func is_site_cleared(site_id: String) -> bool:
    return _cleared_sites.has(site_id)

func is_site_discovered(site_id: String) -> bool:
    return _discovered_sites.has(site_id)

func get_site_remaining(site_id: String) -> int:
    return int(_remaining_by_site.get(site_id, 0))

func get_site_enemy_count(site_id: String) -> int:
    if site_enemies.has(site_id):
        return site_enemies[site_id].size()
    return 0

func _spawn_site_enemies() -> void:
    for site in world_builder.get_encounter_sites():
        var id := str(site["id"])
        if _cleared_sites.has(id):
            site_enemies[id] = []
            _remaining_by_site[id] = 0
            continue

        var center: Vector3 = site["center"]
        var radius := float(site["radius"])
        var enemies: Array[EnemyController] = []
        var count := maxi(0, int(site["enemy_count"]))
        _remaining_by_site[id] = count
        for i in range(count):
            var angle := TAU * float(i) / float(count)
            var distance := radius * 0.48
            var x := center.x + cos(angle) * distance
            var z := center.z + sin(angle) * distance
            var position := Vector3(x, world_builder.terrain_height(x, z), z)
            var enemy := EnemySceneScript.new()
            var archetype := "sentinel" if i % 3 == 0 else "wraith" if i % 3 == 1 else "brute"
            enemy.name = "%s_%s_%02d" % [id, archetype.to_upper(), i + 1]
            enemy.configure(player, center, radius, position, site["accent"], archetype)
            enemy.defeated.connect(_on_enemy_defeated.bind(id))
            add_child(enemy)
            enemies.append(enemy)
        site_enemies[id] = enemies
        if count == 0 and not _cleared_sites.has(id):
            _cleared_sites[id] = true
            site_cleared.emit(id)

func _on_enemy_defeated(amount: int, site_id: String) -> void:
    shards_awarded.emit(maxi(1, amount))
    if not _remaining_by_site.has(site_id) or _cleared_sites.has(site_id):
        return
    var remaining: int = maxi(0, int(_remaining_by_site[site_id]) - 1)
    _remaining_by_site[site_id] = remaining
    if remaining == 0:
        _cleared_sites[site_id] = true
        site_cleared.emit(site_id)
