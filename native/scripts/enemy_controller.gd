extends CharacterBody3D
class_name EnemyController

const WorldRules = preload("res://scripts/world_rules.gd")

signal defeated(shard_reward: int)

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
var enemy_type: String = "sentinel"
var _visual: MeshInstance3D

func configure(target: PlayerController, center: Vector3, radius: float, spawn_position: Vector3, tint: Color, variant: String = "sentinel") -> void:
    player = target
    site_center = center
    site_radius = radius
    home_position = spawn_position
    position = spawn_position
    enemy_type = variant if ["sentinel", "wraith", "brute"].has(variant) else "sentinel"
    if enemy_type == "brute":
        max_health = 155.0
        health = max_health
        move_speed = 2.65
    elif enemy_type == "wraith":
        max_health = 78.0
        health = max_health
        move_speed = 4.4
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
        defeated.emit(7)
        queue_free()

func _create_visual(tint: Color) -> void:
    var armor := StandardMaterial3D.new()
    armor.albedo_color = Color(0.035, 0.035, 0.075) if enemy_type != "brute" else Color(0.075, 0.052, 0.06)
    armor.metallic = 0.52 if enemy_type != "wraith" else 0.28
    armor.roughness = 0.34 if enemy_type != "wraith" else 0.58

    var core_material := StandardMaterial3D.new()
    core_material.albedo_color = tint
    core_material.metallic = 0.4
    core_material.roughness = 0.18
    core_material.emission_enabled = true
    core_material.emission = tint
    core_material.emission_energy_multiplier = 2.8

    var body := MeshInstance3D.new()
    body.name = "AnomalyBody"
    if enemy_type == "brute":
        var shell := BoxMesh.new()
        shell.size = Vector3(1.65, 2.45, 1.18)
        body.mesh = shell
        body.position.y = 1.38
    elif enemy_type == "wraith":
        var shell := PrismMesh.new()
        shell.size = Vector3(1.12, 2.55, 0.92)
        body.mesh = shell
        body.position.y = 1.55
    else:
        var shell := CapsuleMesh.new()
        shell.radius = 0.68
        shell.height = 2.2
        body.mesh = shell
        body.position.y = 1.1
    body.material_override = armor
    body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    add_child(body)
    _visual = body

    var core := MeshInstance3D.new()
    var core_mesh := SphereMesh.new()
    core_mesh.radius = 0.36 if enemy_type != "brute" else 0.48
    core_mesh.height = 0.76 if enemy_type != "brute" else 0.96
    core.mesh = core_mesh
    core.position = Vector3(0.0, 1.36 if enemy_type != "brute" else 1.52, -0.62)
    core.material_override = core_material
    add_child(core)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.46 if enemy_type != "brute" else 0.62
    head_mesh.height = 0.72 if enemy_type != "brute" else 0.95
    head.mesh = head_mesh
    head.position = Vector3(0.0, 2.02 if enemy_type != "brute" else 2.45, -0.08)
    head.material_override = armor
    add_child(head)

    var eye_bar := MeshInstance3D.new()
    var eye_mesh := BoxMesh.new()
    eye_mesh.size = Vector3(0.5, 0.09, 0.12) if enemy_type != "brute" else Vector3(0.68, 0.13, 0.14)
    eye_bar.mesh = eye_mesh
    eye_bar.position = head.position + Vector3(0.0, 0.0, -0.4)
    eye_bar.material_override = core_material
    add_child(eye_bar)

    for side in [-1.0, 1.0]:
        var horn := MeshInstance3D.new()
        var horn_mesh := PrismMesh.new()
        horn_mesh.size = Vector3(0.36, 1.12, 0.4) if enemy_type != "brute" else Vector3(0.52, 1.45, 0.58)
        horn.mesh = horn_mesh
        horn.position = Vector3(side * (0.4 if enemy_type != "brute" else 0.58), 2.48 if enemy_type != "brute" else 2.85, -0.04)
        horn.rotation_degrees.z = side * -24.0
        horn.material_override = core_material
        add_child(horn)

        var arm := MeshInstance3D.new()
        if enemy_type == "brute":
            var arm_mesh := BoxMesh.new()
            arm_mesh.size = Vector3(0.52, 1.35, 0.58)
            arm.mesh = arm_mesh
        else:
            var arm_mesh := CapsuleMesh.new()
            arm_mesh.radius = 0.2
            arm_mesh.height = 1.1
            arm.mesh = arm_mesh
        arm.position = Vector3(side * (0.78 if enemy_type == "brute" else 0.68), 1.08, 0.02)
        arm.rotation_degrees.z = side * 18.0
        arm.material_override = armor
        add_child(arm)

    if enemy_type == "wraith":
        var halo := MeshInstance3D.new()
        var halo_mesh := TorusMesh.new()
        halo_mesh.inner_radius = 0.78
        halo_mesh.outer_radius = 0.9
        halo.mesh = halo_mesh
        halo.position.y = 1.35
        halo.rotation_degrees.x = 90.0
        halo.material_override = core_material
        add_child(halo)
        var lower_core := MeshInstance3D.new()
        var lower_mesh := PrismMesh.new()
        lower_mesh.size = Vector3(0.56, 0.82, 0.54)
        lower_core.mesh = lower_mesh
        lower_core.position = Vector3(0.0, 0.28, -0.25)
        lower_core.material_override = core_material
        add_child(lower_core)
    elif enemy_type == "brute":
        for side in [-1.0, 1.0]:
            var plate := MeshInstance3D.new()
            var plate_mesh := BoxMesh.new()
            plate_mesh.size = Vector3(0.72, 0.34, 0.8)
            plate.mesh = plate_mesh
            plate.position = Vector3(side * 0.82, 1.82, 0.0)
            plate.material_override = core_material
            add_child(plate)
    else:
        var lower_core := MeshInstance3D.new()
        var lower_mesh := SphereMesh.new()
        lower_mesh.radius = 0.22
        lower_mesh.height = 0.44
        lower_core.mesh = lower_mesh
        lower_core.position = Vector3(0.0, 0.46, -0.4)
        lower_core.material_override = core_material
        add_child(lower_core)
