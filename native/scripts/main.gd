extends Node3D

const WorldRules = preload("res://scripts/world_rules.gd")
const WorldBuilderScript = preload("res://scripts/world_builder.gd")
const PlayerControllerScript = preload("res://scripts/player_controller.gd")
const EncounterManagerScript = preload("res://scripts/encounter_manager.gd")
const GameUIScript = preload("res://scripts/game_ui.gd")
const SaveServiceScript = preload("res://scripts/save_service.gd")

var world: WorldBuilder
var player: PlayerController
var encounters: EncounterManager
var game_ui: GameUI
var save_data: Dictionary
var _playing: bool = false
var _hud_refresh: float = 0.0

func _ready() -> void:
    save_data = SaveServiceScript.load_save()
    _create_world()
    _create_player()
    _create_encounters()
    _create_ui()
    _connect_systems()
    _apply_quality(str(save_data["quality"]))
    player.damage_rank = int(save_data["damage_rank"])
    player.vitality_rank = int(save_data["vitality_rank"])
    player.select_class(str(save_data["selected_class"]))
    game_ui.set_selected_class(str(save_data["selected_class"]))
    player.shards = int(save_data["shards"])
    player.set_physics_process(false)
    encounters.set_process(false)
    game_ui.show_menu()

func _create_world() -> void:
    world = WorldBuilderScript.new()
    world.name = "WorldBuilder"
    add_child(world)

func _create_player() -> void:
    player = PlayerControllerScript.new()
    player.name = "Player"
    add_child(player)
    var spawn := Vector3(0.0, world.terrain_height(0.0, 6.0) + 0.2, 6.0)
    player.global_position = spawn

func _create_encounters() -> void:
    encounters = EncounterManagerScript.new()
    encounters.name = "EncounterManager"
    add_child(encounters)
    encounters.configure(player, world)

func _create_ui() -> void:
    game_ui = GameUIScript.new()
    game_ui.name = "GameUI"
    add_child(game_ui)

func _connect_systems() -> void:
    game_ui.start_game.connect(_start_game)
    game_ui.class_selected.connect(_on_class_selected)
    game_ui.action_requested.connect(_on_action_requested)
    game_ui.movement_changed.connect(player.set_mobile_move)
    game_ui.quality_changed.connect(_apply_quality)
    game_ui.pause_requested.connect(_pause_game)
    game_ui.resume_requested.connect(_resume_game)
    game_ui.new_game_requested.connect(_return_to_menu)
    game_ui.retry_requested.connect(_retry_at_safe_haven)
    game_ui.purchase_requested.connect(_on_keeper_purchase)
    game_ui.merchant_closed.connect(_close_keeper)
    encounters.shards_awarded.connect(_on_shards_awarded)
    player.health_changed.connect(game_ui.update_health)
    player.energy_changed.connect(game_ui.update_energy)
    player.defeated.connect(_on_player_defeated)

func _start_game() -> void:
    get_tree().paused = false
    _playing = true
    player.set_physics_process(true)
    encounters.set_process(true)
    game_ui.show_hud()
    game_ui.update_health(player.health, player.max_health)
    game_ui.update_energy(player.energy, player.max_energy)
    _refresh_hud()
    _persist_save()

func _pause_game() -> void:
    if not _playing:
        return
    get_tree().paused = true
    game_ui.show_pause()

func _resume_game() -> void:
    get_tree().paused = false
    game_ui.hide_pause()

func _return_to_menu() -> void:
    get_tree().paused = false
    _playing = false
    player.set_physics_process(false)
    player.clear_mobile_move()
    encounters.set_process(false)
    game_ui.show_menu()
    _persist_save()

func _on_class_selected(class_id: String) -> void:
    player.select_class(class_id)
    save_data["selected_class"] = class_id
    _persist_save()

func _on_action_requested(action_id: String) -> void:
    match action_id:
        "attack":
            player.attack_light()
        "heavy":
            player.attack_heavy()
        "guard":
            player.guard()
        "dodge":
            player.dodge()
        "skill":
            player.use_class_skill()
        "interact":
            if WorldRules.is_safe_haven(player.global_position):
                get_tree().paused = true
                game_ui.show_keeper(player.shards)
            else:
                game_ui.notify_event("لا يوجد تاجر قريب. عد إلى الملاذ الآمن.")
        "rebuild":
            if WorldRules.is_safe_haven(player.global_position):
                player.restore_health(24.0)
                player.restore_energy(28.0)
                game_ui.set_status("تم ترميم طاقتك داخل الملاذ الآمن.")
            else:
                game_ui.set_status("اقترب من أثر قابل للترميم لإعادة بناء المنطقة.")

func _on_player_defeated() -> void:
    if not _playing:
        return
    _playing = false
    get_tree().paused = true
    player.set_physics_process(false)
    game_ui.show_game_over()

func _retry_at_safe_haven() -> void:
    get_tree().paused = false
    var spawn := Vector3(0.0, world.terrain_height(0.0, 6.0) + 0.2, 6.0)
    player.reset_at_spawn(spawn)
    _playing = true
    player.set_physics_process(true)
    encounters.set_process(true)
    game_ui.show_hud()
    game_ui.update_hud(player.shards, "SAFE HAVEN  •  الملاذ الآمن", "عد إلى تجهيزاتك ثم استكشف البراري.")

func _process(delta: float) -> void:
    if not _playing:
        return
    _hud_refresh += delta
    if _hud_refresh >= 0.14:
        _hud_refresh = 0.0
        _refresh_hud()

func _refresh_hud() -> void:
    var zone_name := "SAFE HAVEN  •  الملاذ الآمن"
    var objective := "تحدّث مع الحارس وجهّز أسلحتك قبل الرحيل."
    if WorldRules.is_safe_haven(player.global_position):
        zone_name = "SAFE HAVEN  •  الملاذ الآمن"
    else:
        var site_id := encounters.get_current_site_id()
        if site_id == "mirkwood":
            zone_name = "MIRKWOOD WILDS  •  غابة الظلال"
            objective = "استكشف الغابة وواجه الحراس داخل نطاقها."
        elif site_id == "sunken_grove":
            zone_name = "SUNKEN GROVE  •  البستان الغارق"
            objective = "عطّل الشذوذ واستعد البلورة القديمة."
        else:
            zone_name = "THE OUTSKIRTS  •  البراري"
            objective = "استكشف أطراف العالم وابحث عن مواقع المراسي."
    game_ui.update_hud(player.shards, zone_name, objective)

func _apply_quality(quality: String) -> void:
    save_data["quality"] = quality
    var viewport := get_viewport()
    match quality:
        "performance":
            viewport.scaling_3d_scale = 0.72
            viewport.msaa_3d = Viewport.MSAA_DISABLED
        "high":
            viewport.scaling_3d_scale = 1.0
            viewport.msaa_3d = Viewport.MSAA_4X
        _:
            viewport.scaling_3d_scale = 0.86
            viewport.msaa_3d = Viewport.MSAA_2X
    _persist_save()

func _persist_save() -> void:
    save_data["selected_class"] = player.class_id if player != null else "vanguard"
    save_data["shards"] = player.shards if player != null else 0
    save_data["damage_rank"] = player.damage_rank if player != null else 0
    save_data["vitality_rank"] = player.vitality_rank if player != null else 0
    SaveServiceScript.write_save(save_data)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
            if _playing and not get_tree().paused:
                _pause_game()
            elif get_tree().paused:
                _resume_game()
        elif event.keycode == KEY_J and _playing:
            player.attack_light()
        elif event.keycode == KEY_K and _playing:
            player.attack_heavy()
        elif event.keycode == KEY_L and _playing:
            player.use_class_skill()
        elif event.keycode == KEY_SHIFT and _playing:
            player.dodge()
 
func _on_shards_awarded(amount: int) -> void:
    player.shards += amount
    game_ui.update_hud(player.shards, _current_zone_title(), "اجمع الشظايا وطوّر سلاحك من الملاذ الآمن.")
    game_ui.notify_event("+%d SHARDS  •  تم جمع الشظايا" % amount)
    if get_tree().paused:
        game_ui.update_keeper_shards(player.shards)
    _persist_save()

func _on_keeper_purchase(item_id: String) -> void:
    var costs := {
        "health": 10,
        "energy": 8,
        "damage": 45,
        "vitality": 40
    }
    var cost := int(costs.get(item_id, 999999))
    if player.shards < cost:
        game_ui.notify_event("لا توجد شظايا كافية  •  INSUFFICIENT SHARDS")
        return
    var purchased := true
    match item_id:
        "health":
            player.shards -= cost
            player.restore_health(65.0)
        "energy":
            player.shards -= cost
            player.restore_energy(65.0)
        "damage":
            purchased = player.purchase_upgrade("damage")
            if purchased:
                player.shards -= cost
        "vitality":
            purchased = player.purchase_upgrade("vitality")
            if purchased:
                player.shards -= cost
        _:
            purchased = false
    if not purchased:
        game_ui.notify_event("وصلت هذه الترقية إلى الحد الأقصى.")
        return
    game_ui.update_keeper_shards(player.shards)
    game_ui.update_hud(player.shards, "SAFE HAVEN  •  الملاذ الآمن", "تم الشراء. يمكنك متابعة الاستكشاف.")
    game_ui.notify_event("تم تنفيذ عملية الشراء بنجاح.")
    _persist_save()

func _close_keeper() -> void:
    get_tree().paused = false

func _on_shards_awarded(amount: int) -> void:
    player.shards += amount
    game_ui.update_hud(player.shards, _current_zone_title(), "اجمع الشظايا وطوّر سلاحك من الملاذ الآمن.")
    game_ui.notify_event("+%d SHARDS  •  تم جمع الشظايا" % amount)
    _persist_save()

func _current_zone_title() -> String:
    if WorldRules.is_safe_haven(player.global_position):
        return "SAFE HAVEN  •  الملاذ الآمن"
    var site_id := encounters.get_current_site_id()
    if site_id == "mirkwood":
        return "MIRKWOOD WILDS  •  غابة الظلال"
    if site_id == "sunken_grove":
        return "SUNKEN GROVE  •  البستان الغارق"
    return "THE OUTSKIRTS  •  البراري"
