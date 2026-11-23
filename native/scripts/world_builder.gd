extends Node3D
class_name WorldBuilder

const WorldRules = preload("res://scripts/world_rules.gd")

const MAP_SIZE: float = 470.0
const TERRAIN_SEGMENTS: int = 128

var _noise := FastNoiseLite.new()
var _encounter_sites: Array[Dictionary] = [
    {
        "id": "mirkwood",
        "name": "MIRKWOOD WILDS",
        "name_ar": "غابة الظلال",
        "center": Vector3(142.0, 0.0, 68.0),
        "radius": 43.0,
        "enemy_count": 7,
        "accent": Color(0.57, 0.22, 1.0)
    },
    {
        "id": "sunken_grove",
        "name": "SUNKEN GROVE",
        "name_ar": "البستان الغارق",
        "center": Vector3(-154.0, 0.0, 142.0),
        "radius": 46.0,
        "enemy_count": 8,
        "accent": Color(0.14, 0.76, 0.92)
    }
]

var _materials: Dictionary = {}
var _built: bool = false

func _ready() -> void:
    build_world()

func terrain_height(x: float, z: float) -> float:
    var rolling := sin(x * 0.018) * cos(z * 0.022) * 2.2
    var ridge := sin((x + z) * 0.009) * 2.8
    var noise_height := _noise.get_noise_2d(x, z) * 4.6
    var distance := Vector2(x, z).length()
    var mountain := maxf(0.0, distance - 155.0) * 0.045
    return rolling + ridge + noise_height + mountain

func get_encounter_sites() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for site in _encounter_sites:
        result.append(site.duplicate(true))
    return result

func build_world() -> void:
    if _built:
        return
    _built = true
    _noise.seed = 73421
    _noise.frequency = 0.012
    _noise.fractal_octaves = 4
    _noise.fractal_gain = 0.48
    _noise.fractal_lacunarity = 2.1

    _build_environment()
    _build_terrain()
    _build_river_system()
    _build_road_network()
    _build_safe_haven()
    _build_forests()
    _build_rocks_and_crystals()
    _build_site_markers()

func _build_environment() -> void:
    var world_environment := WorldEnvironment.new()
    world_environment.name = "WorldEnvironment"
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY

    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.018, 0.032, 0.095)
    sky_material.sky_horizon_color = Color(0.28, 0.39, 0.58)
    sky_material.ground_bottom_color = Color(0.025, 0.035, 0.05)
    sky_material.ground_horizon_color = Color(0.16, 0.21, 0.30)
    sky_material.sun_angle_max = 18.0
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy = 0.62
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.glow_enabled = true
    environment.glow_intensity = 0.58
    environment.glow_strength = 0.9
    environment.glow_bloom = 0.06
    environment.fog_enabled = true
    environment.fog_light_color = Color(0.17, 0.23, 0.38)
    environment.fog_density = 0.006
    environment.fog_sky_affect = 0.72
    world_environment.environment = environment
    add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.name = "EclipseSun"
    sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
    sun.light_color = Color(0.78, 0.86, 1.0)
    sun.light_energy = 1.18
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 115.0
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
    add_child(sun)

    var fill := OmniLight3D.new()
    fill.position = Vector3(0.0, 22.0, -18.0)
    fill.light_color = Color(0.08, 0.55, 1.0)
    fill.light_energy = 2.4
    fill.omni_range = 58.0
    fill.shadow_enabled = false
    add_child(fill)

func _build_terrain() -> void:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var row := TERRAIN_SEGMENTS + 1
    for z in range(row):
        for x in range(row):
            var world_x := -MAP_SIZE * 0.5 + float(x) / TERRAIN_SEGMENTS * MAP_SIZE
            var world_z := -MAP_SIZE * 0.5 + float(z) / TERRAIN_SEGMENTS * MAP_SIZE
            var height := terrain_height(world_x, world_z)
            surface.set_color(_terrain_color(world_x, world_z, height))
            surface.set_uv(Vector2(float(x) / TERRAIN_SEGMENTS, float(z) / TERRAIN_SEGMENTS) * 24.0)
            surface.add_vertex(Vector3(world_x, height - 0.16, world_z))

    for z in range(TERRAIN_SEGMENTS):
        for x in range(TERRAIN_SEGMENTS):
            var a := z * row + x
            var b := a + 1
            var c := a + row
            var d := c + 1
            surface.add_index(a)
            surface.add_index(c)
            surface.add_index(b)
            surface.add_index(b)
            surface.add_index(c)
            surface.add_index(d)

    surface.generate_normals()
    var terrain_mesh := surface.commit()
    var terrain_instance := MeshInstance3D.new()
    terrain_instance.name = "Terrain"
    terrain_instance.mesh = terrain_mesh
    var terrain_material := StandardMaterial3D.new()
    terrain_material.vertex_color_use_as_albedo = true
    terrain_material.roughness = 0.94
    terrain_material.metallic = 0.035
    terrain_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    terrain_instance.material_override = terrain_material
    terrain_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    terrain_instance.gi_mode = GeometryInstance3D.GI_MODE_STATIC
    add_child(terrain_instance)

func _terrain_color(x: float, z: float, height: float) -> Color:
    var distance := Vector2(x, z).length()
    var noise_color := _noise.get_noise_2d(x * 2.3, z * 2.3)
    var base := Color(0.18, 0.27, 0.22)
    if distance < 52.0:
        base = Color(0.22, 0.26, 0.28)
    elif distance > 175.0:
        base = Color(0.28, 0.20, 0.19)
    elif absf(height) > 4.0:
        base = Color(0.30, 0.32, 0.36)
    var tint := 0.91 + noise_color * 0.12
    return Color(base.r * tint, base.g * tint, base.b * tint, 1.0)

func _build_river_system() -> void:
    _add_water_plane(Vector3(-36.0, 0.18, 82.0), Vector2(36.0, 152.0), -0.19)
    _add_water_plane(Vector3(67.0, 0.11, 34.0), Vector2(20.0, 82.0), 0.24)
    _add_waterfall(Vector3(72.0, 1.4, 24.0), 13.0)

func _add_water_plane(position: Vector3, dimensions: Vector2, yaw: float) -> void:
    var water := MeshInstance3D.new()
    water.name = "AnomalyWater"
    var plane := PlaneMesh.new()
    plane.size = dimensions
    plane.subdivide_width = 32
    plane.subdivide_depth = 64
    water.mesh = plane
    water.position = position
    water.rotation.y = yaw
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.035, 0.19, 0.28, 0.86)
    material.metallic = 0.68
    material.roughness = 0.16
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.emission_enabled = true
    material.emission = Color(0.015, 0.12, 0.2)
    material.emission_energy_multiplier = 0.42
    water.material_override = material
    water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(water)

func _add_waterfall(position: Vector3, height: float) -> void:
    var fall := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(8.0, height)
    fall.mesh = plane
    fall.position = position + Vector3(0.0, height * 0.5, 0.0)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.22, 0.64, 0.9, 0.54)
    material.emission_enabled = true
    material.emission = Color(0.08, 0.36, 0.72)
    material.emission_energy_multiplier = 0.62
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    fall.material_override = material
    fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(fall)

func _build_road_network() -> void:
    _add_road(Vector3(0.0, 0.03, 28.0), Vector2(11.0, 78.0), 0.0)
    _add_road(Vector3(0.0, 0.04, 74.0), Vector2(8.0, 65.0), 0.0)
    _add_road(Vector3(46.0, 0.04, 58.0), Vector2(7.0, 92.0), -0.34)

func _add_road(position: Vector3, dimensions: Vector2, yaw: float) -> void:
    var road := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = dimensions
    plane.subdivide_width = 4
    plane.subdivide_depth = 16
    road.mesh = plane
    road.position = position
    road.rotation.y = yaw
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.14, 0.17, 0.19)
    material.roughness = 0.95
    material.metallic = 0.08
    road.material_override = material
    road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(road)

func _build_safe_haven() -> void:
    var stone := _material(Color(0.16, 0.21, 0.27), 0.42, 0.72)
    var dark_stone := _material(Color(0.055, 0.085, 0.12), 0.36, 0.78)
    var warm_trim := _material(Color(0.45, 0.28, 0.16), 0.62, 0.48)
    var window_glow := _emissive_material(Color(0.1, 0.66, 1.0), 1.9)
    var gold_glow := _emissive_material(Color(1.0, 0.58, 0.18), 1.35)

    _create_building(Vector3(22.0, 0.0, 10.0), Vector3(12.0, 10.0, 10.0), stone, dark_stone, warm_trim, window_glow)
    _create_building(Vector3(-21.0, 0.0, 8.0), Vector3(13.0, 8.0, 11.0), stone, dark_stone, warm_trim, window_glow)
    _create_building(Vector3(21.0, 0.0, -21.0), Vector3(10.0, 14.0, 10.0), stone, dark_stone, warm_trim, window_glow)
    _create_building(Vector3(-22.0, 0.0, -23.0), Vector3(11.0, 9.0, 9.0), stone, dark_stone, warm_trim, window_glow)
    _create_building(Vector3(0.0, 0.0, 32.0), Vector3(15.0, 7.0, 10.0), stone, dark_stone, warm_trim, gold_glow)
    _create_building(Vector3(-38.0, 0.0, 4.0), Vector3(8.0, 11.0, 10.0), stone, dark_stone, warm_trim, window_glow)
    _create_citadel_tower(Vector3(0.0, 0.0, -32.0), stone, dark_stone, gold_glow)
    _create_city_arch(Vector3(0.0, 0.0, 15.0), warm_trim, gold_glow)
    _create_safe_lamps()

func _create_building(origin: Vector3, size: Vector3, wall: Material, roof: Material, trim: Material, window: Material) -> void:
    var root := Node3D.new()
    root.position = Vector3(origin.x, terrain_height(origin.x, origin.z), origin.z)
    add_child(root)
    _add_box(root, "Foundation", Vector3(size.x + 1.6, 0.8, size.z + 1.6), Vector3(0.0, 0.4, 0.0), roof)
    _add_box(root, "Facade", Vector3(size.x, size.y, size.z), Vector3(0.0, size.y * 0.5 + 0.8, 0.0), wall)
    _add_box(root, "Roof", Vector3(size.x + 1.2, 0.6, size.z + 1.2), Vector3(0.0, size.y + 1.0, 0.0), roof)
    _add_box(root, "RoofTrim", Vector3(size.x + 1.5, 0.18, size.z + 1.5), Vector3(0.0, size.y + 1.33, 0.0), trim)

    var floors := maxi(1, floori(size.y / 3.2))
    var windows_per_floor := maxi(2, floori(size.x / 2.8))
    for floor_index in range(floors):
        var y := 1.75 + float(floor_index) * 3.0
        for window_index in range(windows_per_floor):
            var x := -size.x * 0.5 + (float(window_index) + 0.5) * size.x / float(windows_per_floor)
            _add_box(root, "Window", Vector3(0.78, 1.35, 0.12), Vector3(x, y, size.z * 0.5 + 0.08), window)
            _add_box(root, "WindowFrame", Vector3(0.95, 0.10, 0.18), Vector3(x, y - 0.76, size.z * 0.5 + 0.12), trim)

    for side in [-1.0, 1.0]:
        _add_box(root, "CornerPilaster", Vector3(0.4, size.y + 0.6, 0.42), Vector3(side * (size.x * 0.5 - 0.2), size.y * 0.5 + 0.8, size.z * 0.5 + 0.08), trim)
    _add_box(root, "Entrance", Vector3(1.8, 2.8, 0.18), Vector3(0.0, 2.2, size.z * 0.5 + 0.12), dark_stone)
    _add_box(root, "EntranceGlyph", Vector3(0.18, 2.4, 0.2), Vector3(0.0, 2.25, size.z * 0.5 + 0.24), window)

func _create_citadel_tower(origin: Vector3, stone: Material, roof: Material, beacon_material: Material) -> void:
    var root := Node3D.new()
    root.position = Vector3(origin.x, terrain_height(origin.x, origin.z), origin.z)
    add_child(root)
    for level in range(4):
        var scale := 1.0 - float(level) * 0.16
        var width := 17.0 * scale
        var height := 7.5
        var y := 0.8 + float(level) * 7.2
        _add_box(root, "CitadelTier", Vector3(width, height, width), Vector3(0.0, y, 0.0), stone if level % 2 == 0 else roof)
        _add_box(root, "TierCrown", Vector3(width + 1.0, 0.42, width + 1.0), Vector3(0.0, y + height * 0.5, 0.0), roof)
        for angle_step in range(4):
            var angle := float(angle_step) * PI * 0.5
            var offset := Vector3(cos(angle) * width * 0.38, y + 1.0, sin(angle) * width * 0.38)
            _add_box(root, "BeaconWindow", Vector3(0.36, 3.2, 0.28), offset, beacon_material)
    _add_crystal(root, Vector3(0.0, 33.0, 0.0), 8.0, Color(0.1, 0.72, 1.0))
    _add_box(root, "TowerSpire", Vector3(1.0, 14.0, 1.0), Vector3(0.0, 40.0, 0.0), beacon_material)
    var ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 7.2
    torus.outer_radius = 7.55
    ring.mesh = torus
    ring.position = Vector3(0.0, 33.0, 0.0)
    ring.rotation_degrees.x = 90.0
    ring.material_override = beacon_material
    root.add_child(ring)

func _create_city_arch(origin: Vector3, stone: Material, glow: Material) -> void:
    var root := Node3D.new()
    root.position = Vector3(origin.x, terrain_height(origin.x, origin.z), origin.z)
    add_child(root)
    for side in [-1.0, 1.0]:
        _add_box(root, "GatePillar", Vector3(1.8, 10.0, 2.0), Vector3(side * 7.0, 5.0, 0.0), stone)
        _add_box(root, "GateCap", Vector3(3.0, 0.65, 3.0), Vector3(side * 7.0, 10.3, 0.0), glow)
    _add_box(root, "GateBeam", Vector3(16.0, 1.2, 2.0), Vector3(0.0, 10.0, 0.0), stone)
    _add_box(root, "GateLight", Vector3(9.0, 0.16, 0.25), Vector3(0.0, 9.2, 1.1), glow)

func _create_safe_lamps() -> void:
    var lamp_material := _emissive_material(Color(0.06, 0.68, 1.0), 2.1)
    for position in [Vector3(-36.0, 0.0, -36.0), Vector3(36.0, 0.0, -36.0), Vector3(-36.0, 0.0, 36.0), Vector3(36.0, 0.0, 36.0)]:
        var y := terrain_height(position.x, position.z)
        var pole := MeshInstance3D.new()
        var pole_mesh := CylinderMesh.new()
        pole_mesh.top_radius = 0.22
        pole_mesh.bottom_radius = 0.52
        pole_mesh.height = 9.0
        pole.mesh = pole_mesh
        pole.position = Vector3(position.x, y + 4.5, position.z)
        pole.material_override = _material(Color(0.16, 0.24, 0.31), 0.25, 0.8)
        add_child(pole)
        var cap := MeshInstance3D.new()
        var cap_mesh := SphereMesh.new()
        cap_mesh.radius = 0.76
        cap_mesh.height = 1.5
        cap.mesh = cap_mesh
        cap.position = Vector3(position.x, y + 9.1, position.z)
        cap.material_override = lamp_material
        add_child(cap)
        var light := OmniLight3D.new()
        light.position = Vector3(position.x, y + 9.0, position.z)
        light.light_color = Color(0.08, 0.62, 1.0)
        light.light_energy = 1.8
        light.omni_range = 20.0
        add_child(light)

func _build_forests() -> void:
    for site in _encounter_sites:
        _create_forest_site(site)
    _create_scattered_forest()

func _create_forest_site(site: Dictionary) -> void:
    var center: Vector3 = site["center"]
    var radius: float = site["radius"]
    var rng := RandomNumberGenerator.new()
    rng.seed = 9127 if site["id"] == "mirkwood" else 42719
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.34
    trunk_mesh.bottom_radius = 0.62
    trunk_mesh.height = 5.4
    var canopy_mesh := SphereMesh.new()
    canopy_mesh.radius = 3.0
    canopy_mesh.height = 4.9
    var trunk_multimesh := _new_multimesh(trunk_mesh, 58)
    var canopy_multimesh := _new_multimesh(canopy_mesh, 58)
    var canopy_material := _material(
        Color(0.18, 0.34, 0.26) if site["id"] == "mirkwood" else Color(0.14, 0.38, 0.48),
        0.08,
        0.88
    )
    for i in range(58):
        var angle := rng.randf_range(0.0, TAU)
        var distance := rng.randf_range(15.0, radius + 8.0)
        var x := center.x + cos(angle) * distance
        var z := center.z + sin(angle) * distance
        var y := terrain_height(x, z)
        var scale := rng.randf_range(0.72, 1.32)
        var tree_basis := Basis.from_scale(Vector3(scale, scale, scale))
        trunk_multimesh.set_instance_transform(i, Transform3D(tree_basis, Vector3(x, y + 2.7 * scale, z)))
        canopy_multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(1.45, 1.5, 1.45) * scale), Vector3(x, y + 6.0 * scale, z)))
        var tint := Color(
            rng.randf_range(0.76, 1.0),
            rng.randf_range(0.78, 1.0),
            rng.randf_range(0.82, 1.0),
            1.0
        )
        canopy_multimesh.set_instance_color(i, tint)

    var trunks := MultiMeshInstance3D.new()
    trunks.name = "%s_Trees_Trunks" % site["id"]
    trunks.multimesh = trunk_multimesh
    trunks.material_override = _material(Color(0.17, 0.105, 0.075), 0.03, 0.98)
    add_child(trunks)

    var canopies := MultiMeshInstance3D.new()
    canopies.name = "%s_Trees_Canopies" % site["id"]
    canopies.multimesh = canopy_multimesh
    canopies.material_override = canopy_material
    add_child(canopies)

    _add_ruin_gate(center + Vector3(0.0, 0.0, -radius - 8.0), site["accent"])
    _add_zone_beacon(center, site["accent"])

func _create_scattered_forest() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 88412
    var tree_mesh := SphereMesh.new()
    tree_mesh.radius = 2.3
    tree_mesh.height = 3.7
    var multimesh := _new_multimesh(tree_mesh, 145)
    for i in range(145):
        var angle := rng.randf_range(0.0, TAU)
        var distance := rng.randf_range(62.0, 220.0)
        var x := cos(angle) * distance
        var z := sin(angle) * distance
        if WorldRules.is_safe_haven(Vector3(x, 0.0, z)):
            distance = 62.0
            x = cos(angle) * distance
            z = sin(angle) * distance
        for site in _encounter_sites:
            if WorldRules.is_inside_site(Vector3(x, 0.0, z), site["center"], site["radius"] + 4.0):
                x += 54.0
                z -= 48.0
        var scale := rng.randf_range(0.7, 1.3)
        multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(1.6, 1.8, 1.6) * scale), Vector3(x, terrain_height(x, z) + 3.0 * scale, z)))
        multimesh.set_instance_color(i, Color(0.84, rng.randf_range(0.78, 1.0), 0.94, 1.0))
    var foliage := MultiMeshInstance3D.new()
    foliage.name = "WorldCanopy"
    foliage.multimesh = multimesh
    foliage.material_override = _material(Color(0.2, 0.32, 0.24), 0.02, 0.9)
    add_child(foliage)

func _new_multimesh(mesh: Mesh, count: int) -> MultiMesh:
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.use_colors = true
    multimesh.mesh = mesh
    multimesh.instance_count = count
    multimesh.visible_instance_count = count
    return multimesh

func _add_ruin_gate(position: Vector3, accent: Color) -> void:
    var root := Node3D.new()
    root.position = Vector3(position.x, terrain_height(position.x, position.z), position.z)
    add_child(root)
    var stone := _material(Color(0.17, 0.2, 0.27), 0.3, 0.82)
    for side in [-1.0, 1.0]:
        _add_box(root, "RuinPillar", Vector3(2.1, 8.0, 2.1), Vector3(side * 7.0, 4.0, 0.0), stone)
        _add_box(root, "PillarCap", Vector3(2.9, 0.6, 2.9), Vector3(side * 7.0, 8.3, 0.0), stone)
    _add_box(root, "RuinLintel", Vector3(17.0, 1.4, 2.4), Vector3(0.0, 8.0, 0.0), stone)
    _add_box(root, "RuinSigil", Vector3(1.5, 2.6, 0.3), Vector3(0.0, 6.0, 1.4), _emissive_material(accent, 1.4))

func _add_zone_beacon(position: Vector3, accent: Color) -> void:
    var y := terrain_height(position.x, position.z)
    _add_crystal(self, Vector3(position.x, y + 4.0, position.z), 3.2, accent)
    var light := OmniLight3D.new()
    light.position = Vector3(position.x, y + 5.0, position.z)
    light.light_color = accent
    light.light_energy = 2.2
    light.omni_range = 26.0
    add_child(light)

func _build_rocks_and_crystals() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 112233
    var rock_mesh := SphereMesh.new()
    rock_mesh.radius = 1.0
    rock_mesh.height = 1.8
    var rock_multi := _new_multimesh(rock_mesh, 230)
    for i in range(230):
        var angle := rng.randf_range(0.0, TAU)
        var distance := rng.randf_range(48.0, 226.0)
        var x := cos(angle) * distance
        var z := sin(angle) * distance
        var scale := Vector3(rng.randf_range(0.7, 2.5), rng.randf_range(0.45, 1.6), rng.randf_range(0.7, 2.5))
        rock_multi.set_instance_transform(i, Transform3D(Basis.from_scale(scale), Vector3(x, terrain_height(x, z) + scale.y * 0.45, z)))
        rock_multi.set_instance_color(i, Color(0.68, 0.73, 0.83, 1.0) * rng.randf_range(0.72, 1.0))
    var rocks := MultiMeshInstance3D.new()
    rocks.name = "WorldRockFormations"
    rocks.multimesh = rock_multi
    rocks.material_override = _material(Color(0.28, 0.32, 0.39), 0.24, 0.9)
    add_child(rocks)

    for position in [Vector3(12.0, 0.0, 56.0), Vector3(-27.0, 0.0, -58.0), Vector3(110.0, 0.0, 44.0), Vector3(-124.0, 0.0, 120.0)]:
        var crystal_color := Color(0.13, 0.7, 1.0) if position.x > 0.0 else Color(0.72, 0.34, 1.0)
        _add_crystal(self, Vector3(position.x, terrain_height(position.x, position.z), position.z), 4.0, crystal_color)

func _add_crystal(parent: Node, origin: Vector3, height: float, color: Color) -> void:
    var crystal := MeshInstance3D.new()
    var prism := PrismMesh.new()
    prism.size = Vector3(1.2, height, 1.15)
    prism.subdivide_depth = 1
    crystal.mesh = prism
    crystal.position = origin + Vector3(0.0, height * 0.5, 0.0)
    crystal.rotation_degrees = Vector3(0.0, 32.0, 8.0)
    crystal.material_override = _emissive_material(color, 2.4)
    parent.add_child(crystal)

func _add_box(parent: Node, node_name: String, dimensions: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = node_name
    var box := BoxMesh.new()
    box.size = dimensions
    instance.mesh = box
    instance.position = position
    instance.material_override = material
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    instance.gi_mode = GeometryInstance3D.GI_MODE_STATIC
    parent.add_child(instance)
    return instance

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var key := "%s:%s:%s" % [color.to_html(false), str(metallic), str(roughness)]
    if _materials.has(key):
        return _materials[key]
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    _materials[key] = material
    return material

func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
    var key := "emissive:%s:%s" % [color.to_html(false), str(energy)]
    if _materials.has(key):
        return _materials[key]
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = energy
    material.metallic = 0.28
    material.roughness = 0.22
    _materials[key] = material
    return material
