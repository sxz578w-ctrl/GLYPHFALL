extends CharacterBody3D
class_name PlayerController

signal health_changed(current: float, maximum: float)
signal energy_changed(current: float, maximum: float)
signal defeated

const WorldRules = preload("res://scripts/world_rules.gd")
const GRAVITY: float = 26.0

var class_id: String = "vanguard"
var max_health: float = 145.0
var health: float = 145.0
var max_energy: float = 110.0
var energy: float = 110.0
var shards: int = 0

var _mobile_move := Vector2.ZERO
var _mobile_move_active := false
var _move_speed: float = 7.0
var _damage_multiplier: float = 1.0
var _guard_multiplier: float = 0.78
var _attack_cooldown: float = 0.0
var _skill_cooldown: float = 0.0
var _dodge_timer: float = 0.0
var _guard_timer: float = 0.0
var _invulnerable_timer: float = 0.0
var _attack_phase: float = 0.0
var _weapon_root: Node3D
var _body_root: Node3D
var _camera_arm: SpringArm3D
var _camera: Camera3D
var _last_move_direction := Vector3.FORWARD

func _ready() -> void:
    name = "Player"
    add_to_group("player")
    floor_snap_length = 0.35
    floor_max_angle = deg_to_rad(48.0)
    _create_collision()
    _create_camera()
    select_class(class_id)

func select_class(new_class_id: String) -> void:
    var profile := WorldRules.class_profile(new_class_id)
    class_id = str(profile["id"])
    max_health = float(profile["health"])
    max_energy = float(profile["stamina"])
    health = max_health
    energy = max_energy
    _move_speed = float(profile["speed"])
    _damage_multiplier = float(profile["damage"])
    _guard_multiplier = float(profile["guard"])
    _rebuild_visual_model(profile)
    health_changed.emit(health, max_health)
    energy_changed.emit(energy, max_energy)

func set_mobile_move(direction: Vector2) -> void:
    _mobile_move = direction.limit_length(1.0)
    _mobile_move_active = _mobile_move.length() > 0.05

func clear_mobile_move() -> void:
    _mobile_move = Vector2.ZERO
    _mobile_move_active = false

func attack_light() -> void:
    if _attack_cooldown > 0.0 or _guard_timer > 0.0:
        return
    _attack_cooldown = 0.34 if class_id != "bastion" else 0.55
    _attack_phase = 0.32
    _swing_weapon(false)
    _hit_arc(4.5, 14.0, 31.0 * _damage_multiplier)

func attack_heavy() -> void:
    if _attack_cooldown > 0.0 or energy < 16.0:
        return
    energy -= 16.0
    _attack_cooldown = 0.8 if class_id != "bastion" else 1.1
    _attack_phase = 0.5
    _swing_weapon(true)
    _hit_arc(5.8, 18.0, 62.0 * _damage_multiplier)
    energy_changed.emit(energy, max_energy)

func guard() -> void:
    if _guard_timer > 0.0 or energy < 8.0:
        return
    energy -= 8.0
    _guard_timer = 1.0
    energy_changed.emit(energy, max_energy)

func dodge(direction: Vector3 = Vector3.ZERO) -> void:
    if _dodge_timer > 0.0 or energy < 12.0:
        return
    var move_direction := direction
    if move_direction.length() < 0.05:
        move_direction = _last_move_direction
    move_direction.y = 0.0
    if move_direction.length() < 0.05:
        move_direction = -global_transform.basis.z
    move_direction = move_direction.normalized()
    energy -= 12.0
    _dodge_timer = 0.28
    _invulnerable_timer = 0.36
    velocity.x = move_direction.x * 17.0
    velocity.z = move_direction.z * 17.0
    energy_changed.emit(energy, max_energy)

func use_class_skill() -> void:
    if _skill_cooldown > 0.0 or energy < 28.0:
        return
    energy -= 28.0
    var profile := WorldRules.class_profile(class_id)
    _skill_cooldown = float(profile["cooldown"])
    energy_changed.emit(energy, max_energy)

    match class_id:
        "vanguard":
            _guard_timer = 1.55
            _hit_arc(8.5, 360.0, 78.0)
        "phantom":
            var forward := -global_transform.basis.z
            global_position += forward * 7.5
            _invulnerable_timer = 0.48
            _hit_arc(5.8, 360.0, 92.0)
        "bastion":
            _hit_arc(11.5, 360.0, 112.0)

func receive_hit(amount: float) -> void:
    if amount <= 0.0 or _invulnerable_timer > 0.0:
        return
    var applied := amount
    if _guard_timer > 0.0:
        applied *= _guard_multiplier
    health = maxf(0.0, health - applied)
    health_changed.emit(health, max_health)
    if health <= 0.0:
        defeated.emit()

func restore_health(amount: float) -> void:
    health = minf(max_health, health + maxf(0.0, amount))
    health_changed.emit(health, max_health)

func restore_energy(amount: float) -> void:
    energy = minf(max_energy, energy + maxf(0.0, amount))
    energy_changed.emit(energy, max_energy)

func _physics_process(delta: float) -> void:
    _attack_cooldown = maxf(0.0, _attack_cooldown - delta)
    _skill_cooldown = maxf(0.0, _skill_cooldown - delta)
    _dodge_timer = maxf(0.0, _dodge_timer - delta)
    _guard_timer = maxf(0.0, _guard_timer - delta)
    _invulnerable_timer = maxf(0.0, _invulnerable_timer - delta)
    _attack_phase = maxf(0.0, _attack_phase - delta)
    if _attack_phase <= 0.0 and _weapon_root != null:
        _weapon_root.rotation = Vector3.ZERO

    var move := _get_move_input()
    var camera_forward := -_camera.global_transform.basis.z
    camera_forward.y = 0.0
    camera_forward = camera_forward.normalized()
    var camera_right := _camera.global_transform.basis.x
    camera_right.y = 0.0
    camera_right = camera_right.normalized()
    var direction := camera_right * move.x + camera_forward * -move.y
    direction.y = 0.0
    if direction.length() > 0.05:
        direction = direction.normalized()
        _last_move_direction = direction
        if _dodge_timer <= 0.0:
            velocity.x = direction.x * _move_speed
            velocity.z = direction.z * _move_speed
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 11.0))
    elif _dodge_timer <= 0.0:
        velocity.x = move_toward(velocity.x, 0.0, _move_speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, _move_speed * 5.0 * delta)

    if is_on_floor():
        if velocity.y < 0.0:
            velocity.y = -0.2
    else:
        velocity.y -= GRAVITY * delta

    if energy < max_energy and _guard_timer <= 0.0:
        restore_energy(13.0 * delta)
    move_and_slide()
    _keep_inside_world()

    if _body_root != null:
        _body_root.position.y = sin(Time.get_ticks_msec() * 0.0017) * 0.025
    if _camera_arm != null and _camera != null:
        _camera_arm.spring_length = lerpf(_camera_arm.spring_length, 6.3, minf(1.0, delta * 4.0))

func _get_move_input() -> Vector2:
    if _mobile_move_active:
        return _mobile_move
    return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func _keep_inside_world() -> void:
    var limit := WorldRules.WORLD_LIMIT - 2.0
    global_position.x = clampf(global_position.x, -limit, limit)
    global_position.z = clampf(global_position.z, -limit, limit)

func _hit_arc(radius: float, angle_degrees: float, damage: float) -> void:
    var forward := -global_transform.basis.z
    for enemy in get_tree().get_nodes_in_group("hostiles"):
        if not is_instance_valid(enemy):
            continue
        var offset: Vector3 = enemy.global_position - global_position
        var flat := Vector3(offset.x, 0.0, offset.z)
        var distance := flat.length()
        if distance > radius or distance < 0.05:
            continue
        if angle_degrees < 359.0:
            var alignment := forward.dot(flat.normalized())
            if alignment < cos(deg_to_rad(angle_degrees * 0.5)):
                continue
        enemy.take_damage(damage)

func _swing_weapon(heavy: bool) -> void:
    if _weapon_root == null:
        return
    var swing := 1.1 if heavy else 0.62
    _weapon_root.rotation.z = -swing
    var tween := create_tween()
    tween.tween_property(_weapon_root, "rotation:z", swing, 0.15)
    tween.tween_property(_weapon_root, "rotation:z", 0.0, 0.17)

func _create_collision() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.48
    capsule.height = 2.15
    collision.shape = capsule
    collision.position.y = 1.08
    add_child(collision)

func _create_camera() -> void:
    _camera_arm = SpringArm3D.new()
    _camera_arm.name = "CameraArm"
    _camera_arm.position = Vector3(0.0, 2.2, 0.0)
    _camera_arm.rotation_degrees.x = -9.0
    _camera_arm.spring_length = 6.3
    _camera_arm.margin = 0.18
    add_child(_camera_arm)
    _camera = Camera3D.new()
    _camera.name = "Camera3D"
    _camera.current = true
    _camera.fov = 66.0
    _camera_arm.add_child(_camera)

func _rebuild_visual_model(profile: Dictionary) -> void:
    if _body_root != null:
        _body_root.queue_free()
    _body_root = Node3D.new()
    _body_root.name = "CharacterModel"
    add_child(_body_root)

    var accent: Color = profile["accent"]
    var armor := _make_material(Color(0.045, 0.075, 0.12), 0.58, 0.35)
    var metal := _make_material(Color(0.28, 0.35, 0.45), 0.82, 0.24)
    var glow := _make_material(accent, 0.32, 0.2, true)
    var cloth := _make_material(Color(0.025, 0.035, 0.065), 0.08, 0.86)

    _add_part(_body_root, CapsuleMesh.new(), Vector3(0.0, 1.14, 0.0), Vector3(0.72, 1.0, 0.48), armor)
    _add_part(_body_root, SphereMesh.new(), Vector3(0.0, 1.98, 0.0), Vector3(0.42, 0.48, 0.4), metal)
    _add_part(_body_root, BoxMesh.new(), Vector3(0.0, 0.84, 0.15), Vector3(0.68, 0.72, 0.3), cloth)
    _add_part(_body_root, BoxMesh.new(), Vector3(0.0, 1.42, -0.28), Vector3(0.11, 0.82, 0.12), glow)
    _add_part(_body_root, BoxMesh.new(), Vector3(-0.55, 1.48, 0.0), Vector3(0.32, 0.28, 0.5), metal)
    _add_part(_body_root, BoxMesh.new(), Vector3(0.55, 1.48, 0.0), Vector3(0.32, 0.28, 0.5), metal)
    _add_part(_body_root, CapsuleMesh.new(), Vector3(-0.22, 0.42, 0.0), Vector3(0.26, 0.66, 0.28), armor)
    _add_part(_body_root, CapsuleMesh.new(), Vector3(0.22, 0.42, 0.0), Vector3(0.26, 0.66, 0.28), armor)

    _weapon_root = Node3D.new()
    _weapon_root.name = "SignatureWeapon"
    _weapon_root.position = Vector3(0.55, 1.15, -0.05)
    _body_root.add_child(_weapon_root)
    match class_id:
        "vanguard":
            _add_weapon_sword(_weapon_root, glow, metal, 1.25)
            _add_part(_body_root, BoxMesh.new(), Vector3(-0.67, 1.05, -0.12), Vector3(0.55, 0.72, 0.18), glow)
        "phantom":
            _add_weapon_sword(_weapon_root, glow, metal, 0.92)
            var second := Node3D.new()
            second.position = Vector3(-1.1, 0.0, 0.0)
            _weapon_root.add_child(second)
            _add_weapon_sword(second, glow, metal, 0.92)
        "bastion":
            _add_part(_weapon_root, CylinderMesh.new(), Vector3(0.0, 0.6, 0.0), Vector3(0.11, 0.85, 0.11), metal)
            _add_part(_weapon_root, BoxMesh.new(), Vector3(0.0, 1.28, 0.0), Vector3(0.72, 0.62, 0.68), glow)

func _add_weapon_sword(parent: Node3D, blade_material: Material, hilt_material: Material, length: float) -> void:
    _add_part(parent, BoxMesh.new(), Vector3(0.0, length * 0.58, 0.0), Vector3(0.12, length, 0.07), blade_material)
    _add_part(parent, BoxMesh.new(), Vector3(0.0, 0.05, 0.0), Vector3(0.42, 0.07, 0.12), hilt_material)
    _add_part(parent, CylinderMesh.new(), Vector3(0.0, -0.15, 0.0), Vector3(0.07, 0.34, 0.07), hilt_material)

func _add_part(parent: Node3D, mesh: PrimitiveMesh, position: Vector3, scale: Vector3, material: Material) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = position
    instance.scale = scale
    instance.material_override = material
    parent.add_child(instance)
    return instance

func _make_material(color: Color, metallic: float, roughness: float, emissive: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    if emissive:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 1.8
    return material
