extends CharacterBody3D
class_name EnemyController

const WorldRules = preload("res://scripts/world_rules.gd")

enum State { DORMANT, ALERT, ENGAGE, RETURN_HOME, DEFEATED }

var player: PlayerController
var site_center := Vector3.ZERO
var site_radius: float = 42.0
var aggro_radius: float = 16.0
var home_position := Vector3.ZERO
var health: float = 100.0
var max_health: float = 100.0
var move_speed: float = 3.6
var attack_cooldown: float = 0.0
var state: State = State.DORMANT
var _visual: MeshInstance3D

func configure(target: PlayerController, center: Vector3, radius: float, spawn_position: Vector3, tint: Color) -> void:
    player = target
    site_center = center
    site_radius = radius
    home_position = spawn_position
    global_position = spawn_position
    _create_visual(tint)

func _ready() -> void:
    add_to_group("hostiles")
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.62
    shape.height = 2.2
    collision.shape = shape
    collision.position.y = 1.1
    add_child(collision)

func _physics_process(delta: float) -> void:
    if state == State.DEFEATED or player == null or not is_instance_valid(player):
        return
    attack_cooldown = maxf(0.0, attack_cooldown - delta)

    var can_engage := WorldRules.can_enemy_engage(
        global_position,
        player.global_position,
        site_center,
        site_radius,
        aggro_radius
    )
    if can_engage:
        state = State.ENGAGE
        _move_toward_player(delta)
    else:
        var distance_home := Vector2(global_position.x - home_position.x, global_position.z - home_position.z).length()
        if distance_home > 1.2:
            state = State.RETURN_HOME
            _move_home(delta)
        else:
            state = State.DORMANT
            velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
            velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = -0.2
    move_and_slide()

func _move_toward_player(delta: float) -> void:
    var offset := player.global_position - global_position
    offset.y = 0.0
    var distance := offset.length()
    if distance > 2.15:
        var direction := offset.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 8.0)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
        if attack_cooldown <= 0.0:
            attack_cooldown = 1.45
            player.receive_hit(15.0)

func _move_home(delta: float) -> void:
    var offset := home_position - global_position
    offset.y = 0.0
    var direction := offset.normalized()
    velocity.x = direction.x * move_speed * 0.7
    velocity.z = direction.z * move_speed * 0.7
    rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 5.0)

func take_damage(amount: float) -> void:
    if state == State.DEFEATED or amount <= 0.0:
        return
    health = maxf(0.0, health - amount)
    if health <= 0.0:
        state = State.DEFEATED
        remove_from_group("hostiles")
        queue_free()

func _create_visual(tint: Color) -> void:
    _visual = MeshInstance3D.new()
    var body := CapsuleMesh.new()
    body.radius = 0.68
    body.height = 2.0
    _visual.mesh = body
    _visual.position.y = 1.08
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.045, 0.035, 0.09)
    material.metallic = 0.38
    material.roughness = 0.42
    _visual.material_override = material
    add_child(_visual)

    var core := MeshInstance3D.new()
    var core_mesh := SphereMesh.new()
    core_mesh.radius = 0.34
    core_mesh.height = 0.7
    core.mesh = core_mesh
    core.position = Vector3(0.0, 1.35, -0.58)
    var core_material := StandardMaterial3D.new()
    core_material.albedo_color = tint
    core_material.emission_enabled = true
    core_material.emission = tint
    core_material.emission_energy_multiplier = 2.4
    core.material_override = core_material
    add_child(core)
