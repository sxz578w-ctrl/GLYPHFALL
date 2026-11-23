extends Node3D
class_name WorldBuilder

const WorldRules = preload("res://scripts/world_rules.gd")

const MAP_SIZE: float = 470.0
const TERRAIN_SEGMENTS: int = 176

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
var _restored_anchor_ids: Dictionary = {}
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
    _build_safe_haven_detail_props()
    _build_forest_understory()
    _build_crystal_gardens()


func _build_environment() -> void:
    var world_environment := WorldEnvironment.new()
    world_environment.name = "WorldEnvironment"
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY

    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.012, 0.021, 0.064)
    sky_material.sky_horizon_color = Color(0.24, 0.33, 0.5)
    sky_material.ground_bottom_color = Color(0.018, 0.026, 0.046)
    sky_material.ground_horizon_color = Color(0.105, 0.15, 0.23)
    sky_material.sun_angle_max = 16.0
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy = 0.78
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.glow_enabled = true
    environment.glow_intensity = 0.42
    environment.glow_strength = 0.82
    environment.glow_bloom = 0.045
    environment.fog_enabled = true
    environment.fog_light_color = Color(0.20, 0.27, 0.43)
    environment.fog_density = 0.0038
    environment.fog_sky_affect = 0.82
    world_environment.environment = environment
    add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.name = "EclipseSun"
    sun.rotation_degrees = Vector3(-42.0, -36.0, 0.0)
    sun.light_color = Color(0.72, 0.82, 1.0)
    sun.light_energy = 1.28
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 132.0
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
    sun.directional_shadow_blend_splits = true
    sun.shadow_bias = 0.045
    add_child(sun)

    var fill := OmniLight3D.new()
    fill.name = "CitadelBlueFill"
    fill.position = Vector3(0.0, 24.0, -22.0)
    fill.light_color = Color(0.055, 0.42, 1.0)
    fill.light_energy = 1.85
    fill.omni_range = 68.0
    fill.shadow_enabled = false
    add_child(fill)

    var warm_fill := OmniLight3D.new()
    warm_fill.name = "HavenWarmFill"
    warm_fill.position = Vector3(-27.0, 8.0, 24.0)
    warm_fill.light_color = Color(1.0, 0.48, 0.2)
    warm_fill.light_energy = 0.72
    warm_fill.omni_range = 31.0
    warm_fill.shadow_enabled = false
    add_child(warm_fill)
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

    var terrain_body := StaticBody3D.new()
    terrain_body.name = "TerrainCollision"
    var terrain_collision := CollisionShape3D.new()
    terrain_collision.shape = terrain_mesh.create_trimesh_shape()
    terrain_body.add_child(terrain_collision)
    add_child(terrain_body)


func _terrain_color(x: float, z: float, height: float) -> Color:
    var distance := Vector2(x, z).length()
    var large_noise := _noise.get_noise_2d(x * 0.72, z * 0.72)
    var fine_noise := _noise.get_noise_2d(x * 3.4, z * 3.4)
    var base := Color(0.105, 0.19, 0.16)
    if distance < 52.0:
        base = Color(0.19, 0.225, 0.26)
    elif distance > 175.0:
        base = Color(0.245, 0.17, 0.16)
    elif absf(height) > 4.0:
        base = Color(0.26, 0.295, 0.35)
    elif large_noise > 0.36:
        base = Color(0.24, 0.285, 0.22)
    var tint := 0.92 + large_noise * 0.13 + fine_noise * 0.07
    var cool_rim := clampf((distance - 150.0) / 90.0, 0.0, 0.28)
    return Color(
        clampf(base.r * tint + cool_rim * 0.04, 0.0, 1.0),
        clampf(base.g * tint + cool_rim * 0.035, 0.0, 1.0),
        clampf(base.b * tint + cool_rim * 0.08, 0.0, 1.0),
        1.0
    )
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
    var material := ShaderMaterial.new()
    material.shader = load("res://shaders/water.gdshader")
    material.set_shader_parameter("water_color", Color(0.025, 0.22, 0.34, 0.82))
    material.set_shader_parameter("crest_color", Color(0.10, 0.65, 0.95, 0.5))
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
    var stone := _material(Color(0.14, 0.19, 0.25), 0.48, 0.68)
    var dark_stone := _material(Color(0.045, 0.068, 0.105), 0.42, 0.76)
    var warm_trim := _material(Color(0.48, 0.29, 0.15), 0.68, 0.42)
    var window_glow := _emissive_material(Color(0.075, 0.56, 1.0), 1.7)
    var gold_glow := _emissive_material(Color(1.0, 0.57, 0.18), 1.4)

    _create_building(Vector3(22.0, 0.0, 10.0), Vector3(12.0, 10.0, 10.0), stone, dark_stone, warm_trim, window_glow)
    _create_building(Vector3(-21.0, 0.0, 8.0), Vector3(13.0, 8.0, 11.0), stone, dark_stone, warm_trim, window_glow)
    _create_building(Vector3(21.0, 0.0, -21.0), Vector3(10.0, 14.0, 10.0), stone, dark_stone, warm_trim, window_glow)
    _create_building(Vector3(-22.0, 0.0, -23.0), Vector3(11.0, 9.0, 9.0), stone, dark_stone, warm_trim, window_glow)
    _create_building(Vector3(0.0, 0.0, 32.0), Vector3(15.0, 7.0, 10.0), stone, dark_stone, warm_trim, gold_glow)
    _create_building(Vector3(-38.0, 0.0, 4.0), Vector3(8.0, 11.0, 10.0), stone, dark_stone, warm_trim, window_glow)
    _create_building(Vector3(35.0, 0.0, -5.0), Vector3(8.5, 9.0, 8.0), stone, dark_stone, warm_trim, window_glow)
    _create_building(Vector3(-34.0, 0.0, -7.0), Vector3(9.0, 8.0, 8.5), stone, dark_stone, warm_trim, gold_glow)
    _create_building(Vector3(8.0, 0.0, -39.0), Vector3(8.5, 10.0, 8.0), stone, dark_stone, warm_trim, window_glow)
    _create_citadel_tower(Vector3(0.0, 0.0, -32.0), stone, dark_stone, gold_glow)
    _create_city_arch(Vector3(0.0, 0.0, 15.0), warm_trim, gold_glow)
    _create_safe_lamps()


func _create_building(origin: Vector3, size: Vector3, wall: Material, roof: Material, trim: Material, window: Material) -> void:
    var root := Node3D.new()
    root.name = "CitadelBuilding"
    root.position = Vector3(origin.x, terrain_height(origin.x, origin.z), origin.z)
    add_child(root)

    var base_y := 0.8
    _add_box(root, "Foundation", Vector3(size.x + 2.0, 1.0, size.z + 2.0), Vector3(0.0, 0.5, 0.0), roof)
    _add_box(root, "FoundationLip", Vector3(size.x + 2.35, 0.22, size.z + 2.35), Vector3(0.0, 1.08, 0.0), trim)
    _add_box(root, "Facade", size, Vector3(0.0, size.y * 0.5 + base_y, 0.0), wall)
    _add_box(root, "LowerCourse", Vector3(size.x + 0.3, 0.34, size.z + 0.3), Vector3(0.0, 1.35, 0.0), roof)
    _add_box(root, "UpperCourse", Vector3(size.x + 0.34, 0.3, size.z + 0.34), Vector3(0.0, size.y + 0.35, 0.0), roof)
    _add_box(root, "Roof", Vector3(size.x + 1.1, 0.7, size.z + 1.1), Vector3(0.0, size.y + 0.82, 0.0), roof)
    _add_box(root, "RoofCornice", Vector3(size.x + 1.45, 0.2, size.z + 1.45), Vector3(0.0, size.y + 1.27, 0.0), trim)

    var building_body := StaticBody3D.new()
    building_body.name = "BuildingCollision"
    var building_shape := CollisionShape3D.new()
    var building_box := BoxShape3D.new()
    building_box.size = size
    building_shape.shape = building_box
    building_shape.position.y = size.y * 0.5 + base_y
    building_body.add_child(building_shape)
    root.add_child(building_body)

    var floors: int = maxi(1, floori(size.y / 4.0))
    var windows_per_floor: int = maxi(2, floori(size.x / 3.35))
    var glass_transforms: Array[Transform3D] = []
    var vertical_frame_transforms: Array[Transform3D] = []
    var horizontal_frame_transforms: Array[Transform3D] = []
    var mullion_transforms: Array[Transform3D] = []
    var floor_band_transforms: Array[Transform3D] = []
    for floor_index in range(floors):
        var y := 2.05 + float(floor_index) * 3.55
        floor_band_transforms.append(Transform3D(Basis.IDENTITY, Vector3(0.0, y + 1.0, size.z * 0.5 + 0.1)))
        for window_index in range(windows_per_floor):
            var x := -size.x * 0.5 + (float(window_index) + 0.5) * size.x / float(windows_per_floor)
            var z := size.z * 0.5 + 0.13
            glass_transforms.append(Transform3D(Basis.IDENTITY, Vector3(x, y, z)))
            vertical_frame_transforms.append(Transform3D(Basis.IDENTITY, Vector3(x - 0.48, y, z + 0.065)))
            vertical_frame_transforms.append(Transform3D(Basis.IDENTITY, Vector3(x + 0.48, y, z + 0.065)))
            horizontal_frame_transforms.append(Transform3D(Basis.IDENTITY, Vector3(x, y - 0.76, z + 0.08)))
            horizontal_frame_transforms.append(Transform3D(Basis.IDENTITY, Vector3(x, y + 0.76, z + 0.08)))
            mullion_transforms.append(Transform3D(Basis.IDENTITY, Vector3(x, y, z + 0.095)))

    _add_box_multimesh(root, "WindowGlassBatch", Vector3(0.78, 1.35, 0.08), glass_transforms, window)
    _add_box_multimesh(root, "WindowFrameVerticalBatch", Vector3(0.12, 1.54, 0.16), vertical_frame_transforms, trim)
    _add_box_multimesh(root, "WindowFrameHorizontalBatch", Vector3(1.08, 0.14, 0.22), horizontal_frame_transforms, trim)
    _add_box_multimesh(root, "WindowMullionBatch", Vector3(0.065, 1.35, 0.12), mullion_transforms, roof)
    _add_box_multimesh(root, "FloorBandBatch", Vector3(size.x + 0.28, 0.12, 0.2), floor_band_transforms, trim)

    var buttress_transforms: Array[Transform3D] = []
    var buttress_cap_transforms: Array[Transform3D] = []
    for side in [-1.0, 1.0]:
        var x_corner: float = float(side) * (size.x * 0.5 - 0.28)
        buttress_transforms.append(Transform3D(Basis.IDENTITY, Vector3(x_corner, size.y * 0.5 + base_y, size.z * 0.5 + 0.12)))
        buttress_cap_transforms.append(Transform3D(Basis.IDENTITY, Vector3(x_corner, size.y + 1.4, size.z * 0.5 + 0.12)))
    _add_box_multimesh(root, "CornerButtressBatch", Vector3(0.58, size.y + 1.0, 0.72), buttress_transforms, roof)
    _add_box_multimesh(root, "ButtressCapBatch", Vector3(0.92, 0.34, 0.94), buttress_cap_transforms, trim)

    _add_box(root, "EntranceRecess", Vector3(2.2, 3.2, 0.3), Vector3(0.0, 2.3, size.z * 0.5 + 0.14), roof)
    _add_box(root, "EntranceDoor", Vector3(1.45, 2.45, 0.18), Vector3(0.0, 2.18, size.z * 0.5 + 0.32), roof)
    _add_box(root, "DoorSigil", Vector3(0.12, 1.85, 0.16), Vector3(0.0, 2.2, size.z * 0.5 + 0.44), window)
    _add_box(root, "DoorHandle", Vector3(0.08, 0.08, 0.08), Vector3(0.48, 2.05, size.z * 0.5 + 0.46), trim)
    _add_box(root, "EntranceStepOne", Vector3(2.8, 0.22, 0.72), Vector3(0.0, 0.12, size.z * 0.5 + 0.72), trim)
    _add_box(root, "EntranceStepTwo", Vector3(2.35, 0.22, 0.48), Vector3(0.0, 0.32, size.z * 0.5 + 0.42), roof)

    var merlon_transforms: Array[Transform3D] = []
    var battlement_count: int = maxi(3, floori(size.x / 2.8))
    for i in range(battlement_count):
        var bx := -size.x * 0.5 + float(i) * size.x / float(battlement_count - 1)
        merlon_transforms.append(Transform3D(Basis.IDENTITY, Vector3(bx, size.y + 1.75, 0.0)))
    _add_box_multimesh(root, "RoofMerlonBatch", Vector3(0.72, 0.72, 0.72), merlon_transforms, wall)
    _add_box(root, "FrontInsigniaBacking", Vector3(1.0, 1.0, 0.16), Vector3(0.0, size.y + 1.9, size.z * 0.5 + 0.16), roof)
    _add_box(root, "FrontInsignia", Vector3(0.24, 0.72, 0.2), Vector3(0.0, size.y + 1.9, size.z * 0.5 + 0.27), window)
    _add_box(root, "SideBandLeft", Vector3(0.16, size.y + 0.2, size.z * 0.45), Vector3(-size.x * 0.5 - 0.1, size.y * 0.5 + base_y, 0.0), trim)
    _add_box(root, "SideBandRight", Vector3(0.16, size.y + 0.2, size.z * 0.45), Vector3(size.x * 0.5 + 0.1, size.y * 0.5 + base_y, 0.0), trim)
func _create_citadel_tower(origin: Vector3, stone: Material, roof: Material, beacon_material: Material) -> void:
    var root := Node3D.new()
    root.name = "EclipseCitadelTower"
    root.position = Vector3(origin.x, terrain_height(origin.x, origin.z), origin.z)
    add_child(root)
    _add_box(root, "TowerPlinth", Vector3(24.0, 1.2, 24.0), Vector3(0.0, 0.6, 0.0), roof)
    _add_box(root, "TowerPlinthTrim", Vector3(25.0, 0.26, 25.0), Vector3(0.0, 1.28, 0.0), beacon_material)
    for level in range(5):
        var scale := 1.0 - float(level) * 0.14
        var width := 18.0 * scale
        var height := 6.8
        var y := 2.0 + float(level) * 6.35
        _add_box(root, "CitadelTier", Vector3(width, height, width), Vector3(0.0, y, 0.0), stone if level % 2 == 0 else roof)
        _add_box(root, "TierCrown", Vector3(width + 1.1, 0.48, width + 1.1), Vector3(0.0, y + height * 0.5, 0.0), roof)
        for corner in range(4):
            var angle := float(corner) * PI * 0.5 + PI * 0.25
            var offset := Vector3(cos(angle) * width * 0.47, y + height * 0.5, sin(angle) * width * 0.47)
            _add_box(root, "TierButtress", Vector3(1.3, height + 0.8, 1.3), offset, roof)
        for window_index in range(3):
            var wx := -width * 0.28 + float(window_index) * width * 0.28
            _add_box(root, "BeaconWindow", Vector3(0.45, 3.0, 0.3), Vector3(wx, y + 0.8, width * 0.5 + 0.18), beacon_material)
    _add_crystal(root, Vector3(0.0, 34.0, 0.0), 9.5, Color(0.1, 0.72, 1.0))
    _add_box(root, "TowerSpire", Vector3(0.8, 17.0, 0.8), Vector3(0.0, 41.4, 0.0), beacon_material)

    for ring_index in range(2):
        var ring := MeshInstance3D.new()
        var torus := TorusMesh.new()
        torus.inner_radius = 7.2 + float(ring_index) * 2.0
        torus.outer_radius = 7.55 + float(ring_index) * 2.0
        ring.mesh = torus
        ring.position = Vector3(0.0, 33.0 + float(ring_index) * 7.5, 0.0)
        ring.rotation_degrees.x = 90.0
        ring.material_override = beacon_material
        root.add_child(ring)

func _create_city_arch(origin: Vector3, stone: Material, glow: Material) -> void:
    var root := Node3D.new()
    root.name = "CitadelGate"
    root.position = Vector3(origin.x, terrain_height(origin.x, origin.z), origin.z)
    add_child(root)
    for side in [-1.0, 1.0]:
        _add_box(root, "GatePillar", Vector3(2.4, 11.0, 2.6), Vector3(side * 7.0, 5.5, 0.0), stone)
        _add_box(root, "GatePillarBase", Vector3(3.5, 0.8, 3.6), Vector3(side * 7.0, 0.5, 0.0), glow)
        _add_box(root, "GateCap", Vector3(3.2, 0.8, 3.2), Vector3(side * 7.0, 11.2, 0.0), stone)
        _add_box(root, "GateInlay", Vector3(0.22, 8.4, 0.22), Vector3(side * 7.0, 5.8, 1.34), glow)
    _add_box(root, "GateBeam", Vector3(17.0, 1.6, 2.7), Vector3(0.0, 10.9, 0.0), stone)
    _add_box(root, "GateLight", Vector3(10.0, 0.18, 0.32), Vector3(0.0, 9.8, 1.42), glow)
    var sigil := MeshInstance3D.new()
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 2.25
    ring_mesh.outer_radius = 2.55
    sigil.mesh = ring_mesh
    sigil.position = Vector3(0.0, 11.0, 1.65)
    sigil.material_override = glow
    root.add_child(sigil)

func _create_safe_lamps() -> void:
    var lamp_material := _emissive_material(Color(0.09, 0.7, 1.0), 2.0)
    var metal := _material(Color(0.11, 0.17, 0.24), 0.78, 0.34)
    for position in [Vector3(-36.0, 0.0, -36.0), Vector3(36.0, 0.0, -36.0), Vector3(-36.0, 0.0, 36.0), Vector3(36.0, 0.0, 36.0)]:
        var y := terrain_height(position.x, position.z)
        var lamp_root := Node3D.new()
        lamp_root.name = "HavenBeaconLamp"
        lamp_root.position = Vector3(position.x, y, position.z)
        add_child(lamp_root)
        var pole_mesh := CylinderMesh.new()
        pole_mesh.top_radius = 0.17
        pole_mesh.bottom_radius = 0.42
        pole_mesh.height = 8.6
        var pole := MeshInstance3D.new()
        pole.mesh = pole_mesh
        pole.position.y = 4.3
        pole.material_override = metal
        lamp_root.add_child(pole)
        _add_box(lamp_root, "LampBase", Vector3(1.4, 0.55, 1.4), Vector3(0.0, 0.4, 0.0), metal)
        _add_box(lamp_root, "LampArm", Vector3(1.3, 0.16, 0.16), Vector3(0.45, 8.45, 0.0), metal)
        var cap := MeshInstance3D.new()
        var cap_mesh := SphereMesh.new()
        cap_mesh.radius = 0.55
        cap_mesh.height = 1.1
        cap.mesh = cap_mesh
        cap.position = Vector3(0.45, 8.95, 0.0)
        cap.material_override = lamp_material
        lamp_root.add_child(cap)
        var ring := MeshInstance3D.new()
        var ring_mesh := TorusMesh.new()
        ring_mesh.inner_radius = 0.52
        ring_mesh.outer_radius = 0.7
        ring.mesh = ring_mesh
        ring.position = Vector3(0.45, 8.95, 0.0)
        ring.rotation_degrees.x = 90.0
        ring.material_override = lamp_material
        lamp_root.add_child(ring)
        var light := OmniLight3D.new()
        light.position = Vector3(0.45, 8.95, 0.0)
        light.light_color = Color(0.08, 0.6, 1.0)
        light.light_energy = 1.55
        light.omni_range = 18.0
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
    var tree_count := 64 if site["id"] == "mirkwood" else 56

    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.26
    trunk_mesh.bottom_radius = 0.55
    trunk_mesh.height = 6.2
    var trunk_multi := _new_multimesh(trunk_mesh, tree_count)
    var lower_mesh := CylinderMesh.new()
    lower_mesh.top_radius = 0.16
    lower_mesh.bottom_radius = 2.75
    lower_mesh.height = 4.6
    var middle_mesh := CylinderMesh.new()
    middle_mesh.top_radius = 0.1
    middle_mesh.bottom_radius = 2.08
    middle_mesh.height = 3.8
    var upper_mesh := CylinderMesh.new()
    upper_mesh.top_radius = 0.04
    upper_mesh.bottom_radius = 1.35
    upper_mesh.height = 3.0
    var lower_multi := _new_multimesh(lower_mesh, tree_count)
    var middle_multi := _new_multimesh(middle_mesh, tree_count)
    var upper_multi := _new_multimesh(upper_mesh, tree_count)

    var pine_color := Color(0.09, 0.25, 0.19) if site["id"] == "mirkwood" else Color(0.08, 0.25, 0.3)
    for i in range(tree_count):
        var angle := rng.randf_range(0.0, TAU)
        var distance := rng.randf_range(14.0, radius + 9.0)
        var x := center.x + cos(angle) * distance
        var z := center.z + sin(angle) * distance
        var y := terrain_height(x, z)
        var scale := rng.randf_range(0.72, 1.38)
        var yaw := rng.randf_range(0.0, TAU)
        var basis := Basis(Vector3.UP, yaw).scaled(Vector3(scale, scale, scale))
        trunk_multi.set_instance_transform(i, Transform3D(basis, Vector3(x, y + 3.0 * scale, z)))
        lower_multi.set_instance_transform(i, Transform3D(basis, Vector3(x, y + 4.0 * scale, z)))
        middle_multi.set_instance_transform(i, Transform3D(basis, Vector3(x, y + 6.2 * scale, z)))
        upper_multi.set_instance_transform(i, Transform3D(basis, Vector3(x, y + 8.15 * scale, z)))
        var tint := Color(
            rng.randf_range(0.76, 1.0),
            rng.randf_range(0.82, 1.0),
            rng.randf_range(0.82, 1.0),
            1.0
        )
        lower_multi.set_instance_color(i, tint)
        middle_multi.set_instance_color(i, tint.lightened(0.04))
        upper_multi.set_instance_color(i, tint.lightened(0.08))

    var trunks := MultiMeshInstance3D.new()
    trunks.name = "%s_TreeTrunks" % site["id"]
    trunks.multimesh = trunk_multi
    trunks.material_override = _material(Color(0.12, 0.075, 0.055), 0.08, 0.92)
    add_child(trunks)

    for pair in [
        [lower_multi, Color(0.1, 0.28, 0.2)],
        [middle_multi, pine_color],
        [upper_multi, pine_color.lightened(0.14)]
    ]:
        var canopy := MultiMeshInstance3D.new()
        canopy.name = "%s_TreeCanopyLayer" % site["id"]
        canopy.multimesh = pair[0]
        canopy.material_override = _material(pair[1], 0.02, 0.94)
        add_child(canopy)

    if site["id"] == "sunken_grove":
        _create_broadleaf_species(center, radius, rng)

    _add_ruin_gate(center + Vector3(0.0, 0.0, -radius - 8.0), site["accent"])
    _add_zone_beacon(center, site["accent"])

func _create_scattered_forest() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 88412
    var tree_mesh := CylinderMesh.new()
    tree_mesh.top_radius = 0.02
    tree_mesh.bottom_radius = 2.5
    tree_mesh.height = 5.4
    var multimesh := _new_multimesh(tree_mesh, 168)
    for i in range(168):
        var angle := rng.randf_range(0.0, TAU)
        var distance := rng.randf_range(62.0, 220.0)
        var x := cos(angle) * distance
        var z := sin(angle) * distance
        var position := Vector3(x, 0.0, z)
        if WorldRules.is_safe_haven(position):
            x = cos(angle) * 64.0
            z = sin(angle) * 64.0
        for site in _encounter_sites:
            if WorldRules.is_inside_site(Vector3(x, 0.0, z), site["center"], site["radius"] + 5.0):
                x += 42.0
                z -= 36.0
        var scale := rng.randf_range(0.7, 1.4)
        var tint := Color(rng.randf_range(0.72, 0.95), rng.randf_range(0.84, 1.0), rng.randf_range(0.72, 0.94), 1.0)
        multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(1.4, 1.2, 1.4) * scale), Vector3(x, terrain_height(x, z) + 3.1 * scale, z)))
        multimesh.set_instance_color(i, tint)
    var foliage := MultiMeshInstance3D.new()
    foliage.name = "WorldPineSilhouette"
    foliage.multimesh = multimesh
    foliage.material_override = _material(Color(0.13, 0.29, 0.24), 0.02, 0.94)
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

func _add_box_multimesh(parent: Node, node_name: String, dimensions: Vector3, transforms: Array[Transform3D], material: Material) -> MultiMeshInstance3D:
    if transforms.is_empty():
        return null
    var box := BoxMesh.new()
    box.size = dimensions
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = box
    multimesh.instance_count = transforms.size()
    for i in range(transforms.size()):
        multimesh.set_instance_transform(i, transforms[i])
    var instance := MultiMeshInstance3D.new()
    instance.name = node_name
    instance.multimesh = multimesh
    instance.material_override = material
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(instance)
    return instance

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


func get_visual_contract() -> Dictionary:
    return {
        "terrain_segments": TERRAIN_SEGMENTS,
        "tree_species": 3,
        "architecture_modules": 18,
        "art_direction": "eclipse_frontier",
        "restored_anchor_support": true,
        "rendering": "mobile_pbr_multimesh"
    }

func _build_site_markers() -> void:
    var stone := _material(Color(0.09, 0.14, 0.22), 0.42, 0.72)
    for site in _encounter_sites:
        var center: Vector3 = site["center"]
        var accent: Color = site["accent"]
        var marker_root := Node3D.new()
        marker_root.name = "%s_ApproachMarkers" % str(site["id"])
        marker_root.position = Vector3(center.x, terrain_height(center.x, center.z), center.z)
        add_child(marker_root)
        var radius: float = float(site["radius"]) + 4.0
        for side in [-1.0, 1.0]:
            var marker_position := Vector3(float(side) * radius * 0.42, 0.0, -radius - 5.0)
            _add_box(marker_root, "SitePylon", Vector3(0.72, 4.3, 0.72), marker_position + Vector3(0.0, 2.15, 0.0), stone)
            _add_box(marker_root, "SitePylonGlyph", Vector3(0.18, 2.2, 0.16), marker_position + Vector3(0.0, 2.3, -0.4), _emissive_material(accent, 1.8))

func restore_site_anchor(site_id: String) -> bool:
    if not ["mirkwood", "sunken_grove"].has(site_id):
        return false
    if _restored_anchor_ids.has(site_id):
        return true

    for site in _encounter_sites:
        if str(site["id"]) != site_id:
            continue
        var center: Vector3 = site["center"]
        var accent: Color = site["accent"]
        var root := Node3D.new()
        root.name = "RestoredAnchor_%s" % site_id
        root.position = Vector3(center.x, terrain_height(center.x, center.z), center.z)
        add_child(root)

        var dark_stone := _material(Color(0.025, 0.045, 0.075), 0.62, 0.35)
        var gold := _emissive_material(Color(1.0, 0.69, 0.3), 2.8)
        var awakened := _emissive_material(accent.lightened(0.38), 4.2)

        var plinth := MeshInstance3D.new()
        var plinth_mesh := CylinderMesh.new()
        plinth_mesh.top_radius = 2.1
        plinth_mesh.bottom_radius = 3.0
        plinth_mesh.height = 0.8
        plinth.mesh = plinth_mesh
        plinth.position.y = 0.4
        plinth.material_override = dark_stone
        root.add_child(plinth)

        var base_ring := MeshInstance3D.new()
        var ring_mesh := TorusMesh.new()
        ring_mesh.inner_radius = 2.25
        ring_mesh.outer_radius = 2.55
        base_ring.mesh = ring_mesh
        base_ring.position.y = 0.7
        base_ring.rotation_degrees.x = 90.0
        base_ring.material_override = gold
        root.add_child(base_ring)

        var energy_ring := MeshInstance3D.new()
        var energy_mesh := TorusMesh.new()
        energy_mesh.inner_radius = 4.0
        energy_mesh.outer_radius = 4.16
        energy_ring.mesh = energy_mesh
        energy_ring.position.y = 0.28
        energy_ring.rotation_degrees.x = 90.0
        energy_ring.material_override = awakened
        root.add_child(energy_ring)

        _add_crystal(root, Vector3(0.0, 0.75, 0.0), 5.2, accent.lightened(0.5))
        var beam := MeshInstance3D.new()
        var beam_mesh := CylinderMesh.new()
        beam_mesh.top_radius = 0.035
        beam_mesh.bottom_radius = 0.14
        beam_mesh.height = 8.5
        beam.mesh = beam_mesh
        beam.position.y = 7.1
        beam.material_override = awakened
        root.add_child(beam)

        for side in [-1.0, 1.0]:
            for depth in [-1.0, 1.0]:
                var pylon := MeshInstance3D.new()
                var pylon_mesh := BoxMesh.new()
                pylon_mesh.size = Vector3(0.5, 2.1, 0.5)
                pylon.mesh = pylon_mesh
                pylon.position = Vector3(side * 4.6, 1.05, depth * 4.6)
                pylon.material_override = gold
                root.add_child(pylon)

        var light := OmniLight3D.new()
        light.name = "AnchorRestorationLight"
        light.position.y = 3.2
        light.light_color = accent.lightened(0.42)
        light.light_energy = 3.4
        light.omni_range = 32.0
        root.add_child(light)

        _restored_anchor_ids[site_id] = true
        return true

    return false

func get_restored_anchor_count() -> int:
    return _restored_anchor_ids.size()

func _create_broadleaf_species(center: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 2.7
    crown_mesh.height = 3.8
    var crown_multi := _new_multimesh(crown_mesh, 34)
    for i in range(34):
        var angle := rng.randf_range(0.0, TAU)
        var distance := rng.randf_range(18.0, radius + 5.0)
        var x := center.x + cos(angle) * distance
        var z := center.z + sin(angle) * distance
        var y := terrain_height(x, z) + 7.2
        var scale := rng.randf_range(0.72, 1.25)
        crown_multi.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(1.25, 0.92, 1.35) * scale), Vector3(x, y, z)))
        crown_multi.set_instance_color(i, Color(rng.randf_range(0.72, 0.9), rng.randf_range(0.9, 1.0), rng.randf_range(0.8, 0.95), 1.0))
    var crowns := MultiMeshInstance3D.new()
    crowns.name = "SunkenGroveBroadleafCanopies"
    crowns.multimesh = crown_multi
    crowns.material_override = _material(Color(0.09, 0.33, 0.3), 0.02, 0.9)
    add_child(crowns)

func _build_safe_haven_detail_props() -> void:
    var props := Node3D.new()
    props.name = "SafeHavenDetailProps"
    add_child(props)
    var timber := _material(Color(0.25, 0.13, 0.075), 0.08, 0.88)
    var metal := _material(Color(0.12, 0.19, 0.28), 0.82, 0.36)
    var warm := _emissive_material(Color(1.0, 0.48, 0.16), 1.55)
    var crate_positions := [
        Vector3(14.0, 0.0, 18.0), Vector3(17.0, 0.0, 17.0), Vector3(-15.0, 0.0, 17.0),
        Vector3(-18.0, 0.0, 16.0), Vector3(26.0, 0.0, -8.0), Vector3(-28.0, 0.0, -11.0)
    ]
    for position in crate_positions:
        var y := terrain_height(position.x, position.z)
        _add_box(props, "SupplyCrate", Vector3(1.65, 1.35, 1.45), Vector3(position.x, y + 0.68, position.z), timber)
        _add_box(props, "CrateBand", Vector3(1.72, 0.12, 0.1), Vector3(position.x, y + 0.68, position.z + 0.76), metal)
    for stall_position in [Vector3(27.0, 0.0, 22.0), Vector3(-27.0, 0.0, 22.0), Vector3(28.0, 0.0, -25.0)]:
        var stall := Node3D.new()
        stall.name = "KeeperMarketStall"
        stall.position = Vector3(stall_position.x, terrain_height(stall_position.x, stall_position.z), stall_position.z)
        props.add_child(stall)
        _add_box(stall, "StallCounter", Vector3(5.0, 1.2, 2.2), Vector3(0.0, 1.0, 0.0), timber)
        _add_box(stall, "StallCanopy", Vector3(5.8, 0.22, 3.0), Vector3(0.0, 3.1, 0.0), warm)
        for side in [-1.0, 1.0]:
            _add_box(stall, "StallPost", Vector3(0.18, 3.1, 0.18), Vector3(side * 2.35, 1.55, 0.0), metal)
    for banner_position in [Vector3(-34.0, 0.0, 18.0), Vector3(34.0, 0.0, 18.0), Vector3(0.0, 0.0, 39.0)]:
        var banner := Node3D.new()
        banner.name = "HavenBanner"
        banner.position = Vector3(banner_position.x, terrain_height(banner_position.x, banner_position.z), banner_position.z)
        props.add_child(banner)
        _add_box(banner, "BannerPole", Vector3(0.12, 7.2, 0.12), Vector3(0.0, 3.6, 0.0), metal)
        _add_box(banner, "BannerCloth", Vector3(2.4, 2.2, 0.12), Vector3(1.15, 5.3, 0.0), warm)
        _add_box(banner, "BannerSigil", Vector3(0.24, 1.45, 0.16), Vector3(1.15, 5.3, 0.09), _emissive_material(Color(0.08, 0.7, 1.0), 2.0))

func _build_forest_understory() -> void:
    var undergrowth := Node3D.new()
    undergrowth.name = "ForestUnderstory"
    add_child(undergrowth)
    var rng := RandomNumberGenerator.new()
    rng.seed = 572841
    var fern_mesh := PrismMesh.new()
    fern_mesh.size = Vector3(0.48, 0.82, 0.16)
    var fern_multi := _new_multimesh(fern_mesh, 310)
    for i in range(310):
        var angle := rng.randf_range(0.0, TAU)
        var distance := rng.randf_range(65.0, 218.0)
        var x := cos(angle) * distance
        var z := sin(angle) * distance
        for site in _encounter_sites:
            if WorldRules.is_inside_site(Vector3(x, 0.0, z), site["center"], site["radius"] + 2.0):
                x += 48.0
                z -= 24.0
        var y := terrain_height(x, z)
        var scale := rng.randf_range(0.55, 1.7)
        var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(scale, scale, scale))
        fern_multi.set_instance_transform(i, Transform3D(basis, Vector3(x, y + 0.36 * scale, z)))
        fern_multi.set_instance_color(i, Color(rng.randf_range(0.72, 0.95), rng.randf_range(0.86, 1.0), rng.randf_range(0.65, 0.9), 1.0))
    var ferns := MultiMeshInstance3D.new()
    ferns.name = "FernClusters"
    ferns.multimesh = fern_multi
    ferns.material_override = _material(Color(0.12, 0.38, 0.23), 0.02, 0.92)
    undergrowth.add_child(ferns)

func _build_crystal_gardens() -> void:
    var garden := Node3D.new()
    garden.name = "CrystalGardens"
    add_child(garden)
    var sites := [
        [Vector3(10.0, 0.0, 59.0), Color(0.1, 0.7, 1.0)],
        [Vector3(-78.0, 0.0, -58.0), Color(0.68, 0.34, 1.0)],
        [Vector3(112.0, 0.0, 42.0), Color(0.14, 0.84, 0.78)],
        [Vector3(-129.0, 0.0, 116.0), Color(0.8, 0.42, 1.0)]
    ]
    for entry in sites:
        var center: Vector3 = entry[0]
        var color: Color = entry[1]
        var base_y := terrain_height(center.x, center.z)
        for i in range(5):
            var angle := TAU * float(i) / 5.0
            var offset := Vector3(cos(angle) * 2.8, 0.0, sin(angle) * 2.8)
            var height := 2.8 + float((i * 3) % 4) * 0.9
            _add_crystal(garden, Vector3(center.x, base_y, center.z) + offset, height, color.lightened(float(i) * 0.035))
        var halo := MeshInstance3D.new()
        var ring := TorusMesh.new()
        ring.inner_radius = 3.6
        ring.outer_radius = 3.82
        halo.mesh = ring
        halo.position = Vector3(center.x, base_y + 0.28, center.z)
        halo.rotation_degrees.x = 90.0
        halo.material_override = _emissive_material(color, 1.35)
        garden.add_child(halo)

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var key := "%s:%s:%s" % [color.to_html(false), str(metallic), str(roughness)]
    if _materials.has(key):
        return _materials[key]
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.vertex_color_use_as_albedo = true
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
