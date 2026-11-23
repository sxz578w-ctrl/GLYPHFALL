extends Node3D

const WorldRules = preload("res://scripts/world_rules.gd")
const WorldBuilderScript = preload("res://scripts/world_builder.gd")
const PlayerControllerScript = preload("res://scripts/player_controller.gd")
const EncounterManagerScript = preload("res://scripts/encounter_manager.gd")
const GameUIScript = preload("res://scripts/game_ui.gd")
const SaveServiceScript = preload("res://scripts/save_service.gd")
const ProgressionService = preload("res://scripts/progression_service.gd")

var world: WorldBuilder
var player: PlayerController
var encounters: EncounterManager
var game_ui: GameUI
var save_data: Dictionary
var progression: Dictionary
var _playing: bool = false
var _hud_refresh: float = 0.0
var _playtime_buffer: float = 0.0

func _ready() -> void:
    save_data = SaveServiceScript.load_save()
    progression = ProgressionService.normalise(save_data.get("progression", {}))
    _create_world()
    for restored_site in progression["restored_sites"]:
        world.restore_site_anchor(str(restored_site))
    _create_player()
    _create_encounters()
    _create_ui()
    _connect_systems()
    player.damage_rank = int(save_data["damage_rank"])
    player.vitality_rank = int(save_data["vitality_rank"])
    player.shards = int(save_data["shards"])
    player.select_class(str(save_data["selected_class"]))
    _apply_quality(str(save_data["quality"]))
    game_ui.set_selected_class(str(save_data["selected_class"]))
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
    player.global_position = Vector3(0.0, world.terrain_height(0.0, 6.0) + 0.2, 6.0)

func _create_encounters() -> void:
    encounters = EncounterManagerScript.new()
    encounters.name = "EncounterManager"
    add_child(encounters)
    encounters.configure(
        player,
        world,
        progression["discovered_sites"],
        progression["cleared_sites"]
    )

func _create_ui() -> void:
    game_ui = GameUIScript.new()
    game_ui.name = "GameUI"
    add_child(game_ui)

func _connect_systems() -> void:
    game_ui.start_game.connect(_start_game)
    game_ui.class_selected.connect(_on_class_selected)
    game_ui.action_requested.connect(_on_action_requested)
    game_ui.movement_changed.connect(player.set_mobile_move)
    game_ui.quality_changed.connect(_on_quality_changed)
    game_ui.pause_requested.connect(_pause_game)
    game_ui.resume_requested.connect(_resume_game)
    game_ui.new_game_requested.connect(_return_to_menu)
    game_ui.retry_requested.connect(_retry_at_safe_haven)
    game_ui.purchase_requested.connect(_on_keeper_purchase)
    game_ui.merchant_closed.connect(_close_keeper)
    game_ui.section_requested.connect(_on_menu_section_requested)
    encounters.site_discovered.connect(_on_site_discovered)
    encounters.site_cleared.connect(_on_site_cleared)
    player.health_changed.connect(game_ui.update_health)
    player.energy_changed.connect(game_ui.update_energy)
    player.defeated.connect(_on_player_defeated)
    encounters.shards_awarded.connect(_on_shards_awarded)

func _start_game() -> void:
    get_tree().paused = false
    _playing = true
    _playtime_buffer = 0.0
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

func _retry_at_safe_haven() -> void:
    get_tree().paused = false
    player.reset_at_spawn(Vector3(0.0, world.terrain_height(0.0, 6.0) + 0.2, 6.0))
    _playing = true
    player.set_physics_process(true)
    encounters.set_process(true)
    game_ui.show_hud()
    game_ui.notify_event("تمت إعادتك إلى الملاذ الآمن.")

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
                _try_restore_current_anchor()
        "rebuild":
            if WorldRules.is_safe_haven(player.global_position):
                player.restore_health(24.0)
                player.restore_energy(28.0)
                game_ui.notify_event("تم ترميم طاقتك داخل الملاذ الآمن.")
            else:
                _try_restore_current_anchor()

func _try_restore_current_anchor() -> void:
    var site_id := encounters.get_current_site_id()
    if site_id.is_empty():
        game_ui.notify_event("لا توجد مرساة معروفة في هذا الموقع.")
        return
    if ProgressionService.is_site_restored(progression, site_id):
        game_ui.notify_event("هذه المرساة أعيد بناؤها بالفعل.")
        return
    if not encounters.is_site_cleared(site_id):
        game_ui.notify_event("لا يمكن الترميم قبل تطهير الموقع. المتبقي: %d" % encounters.get_site_remaining(site_id))
        return

    var site_center := Vector3.ZERO
    var found := false
    for site in world.get_encounter_sites():
        if str(site["id"]) == site_id:
            site_center = site["center"]
            found = true
            break
    if not found:
        game_ui.notify_event("تعذر تحديد موقع المرساة.")
        return
    var distance := Vector2(player.global_position.x - site_center.x, player.global_position.z - site_center.z).length()
    if distance > 13.0:
        game_ui.notify_event("اقترب من البلورة المركزية للمرساة.")
        return

    const RESTORE_COST: int = 30
    if player.shards < RESTORE_COST:
        game_ui.notify_event("تحتاج إلى 30 شظية لإعادة بناء المرساة.")
        return
    if not world.restore_site_anchor(site_id):
        game_ui.notify_event("تعذر تشغيل المرساة. حاول مجدداً.")
        return

    player.shards -= RESTORE_COST
    progression = ProgressionService.mark_site_restored(progression, site_id)
    game_ui.notify_event("تمت إعادة بناء المرساة. عاد جزء من العالم إلى الحياة.")
    game_ui.update_hud(player.shards, _current_zone_title(), str(ProgressionService.current_objective(progression)["description_ar"]))
    _refresh_hud()
    _persist_save()

func _on_site_discovered(site_id: String) -> void:
    if ProgressionService.is_site_discovered(progression, site_id):
        return
    progression = ProgressionService.mark_site_discovered(progression, site_id)
    game_ui.notify_event("تم اكتشاف منطقة جديدة: " + site_id.to_upper())
    _refresh_hud()
    _persist_save()

func _on_site_cleared(site_id: String) -> void:
    if ProgressionService.is_site_cleared(progression, site_id):
        return
    progression = ProgressionService.mark_site_cleared(progression, site_id)
    player.shards += 25
    game_ui.notify_event("تم تطهير الموقع. مكافأة إكمال: +25 شظية")
    _refresh_hud()
    _persist_save()

func _on_menu_section_requested(section_id: String) -> void:
    var entries: Array[String] = []
    match section_id:
        "heroes":
            for profile in WorldRules.all_class_profiles():
                entries.append("%s — %s | %s | %s" % [
                    profile["title"],
                    profile["name"],
                    profile["weapon_ar"],
                    profile["ability_ar"]
                ])
            game_ui.show_intel_panel("دليل الفئات / HERO CODEX", entries)
        "missions":
            for step in ProgressionService.QUEST_STEPS:
                var done := false
                var site_id := str(step["site_id"])
                match str(step["kind"]):
                    "discover":
                        done = ProgressionService.is_site_discovered(progression, site_id)
                    "clear":
                        done = ProgressionService.is_site_cleared(progression, site_id)
                    "restore":
                        done = ProgressionService.is_site_restored(progression, site_id)
                    "return":
                        done = ProgressionService.is_campaign_complete(progression)
                entries.append("%s  %s" % ["✓" if done else "○", step["title_ar"]])
            game_ui.show_intel_panel("سجل الرحلة / QUEST LOG", entries)
        "armory":
            entries.append("الشظايا المتاحة: %d" % int(player.shards))
            entries.append("إتقان السلاح: %d / 10" % int(player.damage_rank))
            entries.append("الحيوية: %d / 10" % int(player.vitality_rank))
            entries.append("ترقية الضرر تكلف 45 شظية، وترقية الحيوية تكلف 40.")
            entries.append("استخدم تاجر الملاذ لشراء الجرعات والترقيات الدائمة.")
            game_ui.show_intel_panel("ترسانة الملاذ / ARMORY", entries)
    if section_id == "home":
        game_ui.hide_intel_panel()

func _on_keeper_purchase(item_id: String) -> void:
    var costs: Dictionary = {
        "health": 10,
        "energy": 8,
        "damage": 45,
        "vitality": 40
    }
    var cost := int(costs.get(item_id, 999999))
    if player.shards < cost:
        game_ui.notify_event("لا توجد شظايا كافية  •  INSUFFICIENT SHARDS")
        return

    match item_id:
        "health":
            if player.health >= player.max_health:
                game_ui.notify_event("الصحة ممتلئة بالفعل.")
                return
            player.shards -= cost
            player.restore_health(65.0)
        "energy":
            if player.energy >= player.max_energy:
                game_ui.notify_event("الطاقة ممتلئة بالفعل.")
                return
            player.shards -= cost
            player.restore_energy(65.0)
        "damage":
            if not player.purchase_upgrade("damage"):
                game_ui.notify_event("وصلت ترقية السلاح إلى الحد الأقصى.")
                return
            player.shards -= cost
        "vitality":
            if not player.purchase_upgrade("vitality"):
                game_ui.notify_event("وصلت ترقية الحيوية إلى الحد الأقصى.")
                return
            player.shards -= cost
        _:
            return

    game_ui.update_keeper_shards(player.shards)
    game_ui.update_hud(player.shards, "SAFE HAVEN  •  الملاذ الآمن", "تم الشراء. يمكنك متابعة الاستكشاف.")
    game_ui.notify_event("تم تنفيذ عملية الشراء بنجاح.")
    _persist_save()

func _close_keeper() -> void:
    get_tree().paused = false

func _on_shards_awarded(amount: int) -> void:
    player.shards += amount
    progression = ProgressionService.record_kill(progression)
    game_ui.update_hud(player.shards, _current_zone_title(), str(ProgressionService.current_objective(progression)["description_ar"]))
    game_ui.notify_event("+%d SHARDS  •  تم جمع الشظايا" % amount)
    _persist_save()

func _on_player_defeated() -> void:
    if not _playing:
        return
    _playing = false
    progression = ProgressionService.record_death(progression)
    get_tree().paused = true
    player.set_physics_process(false)
    game_ui.show_game_over()
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

func _process(delta: float) -> void:
    if not _playing:
        return
    _hud_refresh += delta
    _playtime_buffer += delta
    if _playtime_buffer >= 10.0:
        progression = ProgressionService.add_play_time(progression, _playtime_buffer)
        _playtime_buffer = 0.0
        _persist_save()
    if _hud_refresh >= 0.14:
        _hud_refresh = 0.0
        _refresh_hud()

func _refresh_hud() -> void:
    var zone_name := _current_zone_title()
    var objective: Dictionary = ProgressionService.current_objective(progression)
    if str(objective["id"]) == "return_haven" and WorldRules.is_safe_haven(player.global_position):
        var was_complete := ProgressionService.is_campaign_complete(progression)
        progression = ProgressionService.mark_returned_to_haven(progression)
        if not was_complete and ProgressionService.is_campaign_complete(progression):
            game_ui.notify_event("اكتملت الرحلة الأولى. المراسي عادت إلى العمل.")
            _persist_save()
        objective = ProgressionService.current_objective(progression)
    game_ui.update_hud(player.shards, zone_name, str(objective["description_ar"]))
    game_ui.update_progress(
        ProgressionService.completed_steps(progression),
        ProgressionService.TOTAL_STEPS,
        int(progression["kills"]),
        int(progression["deaths"])
    )

func _apply_quality(quality: String) -> void:
    save_data["quality"] = quality
    var viewport := get_viewport()
    match quality:
        "performance":
            viewport.scaling_3d_scale = 0.68
            viewport.msaa_3d = Viewport.MSAA_DISABLED
        "balanced":
            viewport.scaling_3d_scale = 0.82
            viewport.msaa_3d = Viewport.MSAA_2X
        "high":
            viewport.scaling_3d_scale = 1.0
            viewport.msaa_3d = Viewport.MSAA_4X
        "ultra":
            viewport.scaling_3d_scale = 1.15
            viewport.msaa_3d = Viewport.MSAA_4X
        _:
            viewport.scaling_3d_scale = 0.82
            viewport.msaa_3d = Viewport.MSAA_2X
func _persist_save() -> void:
    if player == null:
        return
    save_data["selected_class"] = player.class_id
    save_data["shards"] = player.shards
    save_data["damage_rank"] = player.damage_rank
    save_data["vitality_rank"] = player.vitality_rank
    save_data["progression"] = progression
    SaveServiceScript.write_save(save_data)

func _on_quality_changed(quality: String) -> void:
    _apply_quality(quality)
    _persist_save()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
            if _playing and not get_tree().paused:
                _pause_game()
            elif get_tree().paused and _playing:
                _resume_game()
        elif event.keycode == KEY_J and _playing:
            player.attack_light()
        elif event.keycode == KEY_K and _playing:
            player.attack_heavy()
        elif event.keycode == KEY_L and _playing:
            player.use_class_skill()
        elif event.keycode == KEY_SHIFT and _playing:
            player.dodge()
