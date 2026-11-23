extends Node
class_name EncounterManager

signal shards_awarded(amount: int)

const EnemySceneScript = preload("res://scripts/enemy_controller.gd")

var player: PlayerController
var world_builder: WorldBuilder
var site_enemies: Dictionary = {}
var _current_site_id: String = ""

func configure(target: PlayerController, world: WorldBuilder) -> void:
    player = target
    world_builder = world
    _spawn_site_enemies()

func _process(_delta: float) -> void:
    if player == null:
        return
    var new_site := ""
    for site in world_builder.get_encounter_sites():
        var center: Vector3 = site["center"]
        var distance := Vector2(player.global_position.x - center.x, player.global_position.z - center.z).length()
        if distance <= float(site["radius"]):
            new_site = str(site["id"])
            break
    _current_site_id = new_site

func get_current_site_id() -> String:
    return _current_site_id

func _spawn_site_enemies() -> void:
    for site in world_builder.get_encounter_sites():
        var id := str(site["id"])
        var center: Vector3 = site["center"]
        var radius := float(site["radius"])
        var enemies: Array[EnemyController] = []
        var count := int(site["enemy_count"])
        for i in range(count):
            var angle := TAU * float(i) / float(count)
            var distance := radius * 0.48
            var x := center.x + cos(angle) * distance
            var z := center.z + sin(angle) * distance
            var position := Vector3(x, world_builder.terrain_height(x, z), z)
            var enemy := EnemySceneScript.new()
            enemy.name = "%s_Sentinel_%02d" % [id, i + 1]
            var archetype := "sentinel" if i % 3 == 0 else "wraith" if i % 3 == 1 else "brute"
            enemy.configure(player, center, radius, position, site["accent"], archetype)
            enemy.defeated.connect(_on_enemy_defeated)
            add_child(enemy)
            enemies.append(enemy)
        site_enemies[id] = enemies

func _on_enemy_defeated(amount: int) -> void:
    shards_awarded.emit(maxi(1, amount))
