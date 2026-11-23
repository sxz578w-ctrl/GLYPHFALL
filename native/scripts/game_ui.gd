extends CanvasLayer
class_name GameUI

signal start_game
signal class_selected(class_id: String)
signal action_requested(action_id: String)
signal movement_changed(direction: Vector2)
signal quality_changed(quality: String)
signal pause_requested
signal resume_requested
signal new_game_requested

const WorldRules = preload("res://scripts/world_rules.gd")
const VirtualJoystickScript = preload("res://scripts/virtual_joystick.gd")

const CLASS_ORDER: PackedStringArray = ["vanguard", "phantom", "bastion"]
const ICON_PATHS: Dictionary = {
    "attack": "res://assets/icons/attack.svg",
    "heavy": "res://assets/icons/heavy.svg",
    "guard": "res://assets/icons/guard.svg",
    "dodge": "res://assets/icons/dodge.svg",
    "skill": "res://assets/icons/skill.svg",
    "interact": "res://assets/icons/interact.svg",
    "rebuild": "res://assets/icons/rebuild.svg",
    "pause": "res://assets/icons/pause.svg",
    "settings": "res://assets/icons/settings.svg",
    "map": "res://assets/icons/map.svg"
}

var selected_class: String = "vanguard"
var current_quality: String = "balanced"
var _menu_root: Control
var _hud_root: Control
var _pause_panel: PanelContainer
var _settings_panel: PanelContainer
var _class_title: Label
var _class_weapon: Label
var _class_ability: Label
var _class_description: Label
var _class_stats: VBoxContainer
var _class_buttons: Dictionary = {}
var _health_bar: ProgressBar
var _energy_bar: ProgressBar
var _shards_label: Label
var _zone_label: Label
var _objective_label: Label
var _status_label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 10
    _build_main_menu()
    _build_hud()
    _build_pause_panel()
    _build_settings_panel()
    show_menu()

func show_menu() -> void:
    _menu_root.visible = true
    _hud_root.visible = false
    _pause_panel.visible = false
    _settings_panel.visible = false

func show_hud() -> void:
    _menu_root.visible = false
    _hud_root.visible = true
    _pause_panel.visible = false
    _settings_panel.visible = false

func show_pause() -> void:
    _pause_panel.visible = true

func hide_pause() -> void:
    _pause_panel.visible = false

func update_health(current: float, maximum: float) -> void:
    if _health_bar == null:
        return
    _health_bar.max_value = maxf(1.0, maximum)
    _health_bar.value = current

func update_energy(current: float, maximum: float) -> void:
    if _energy_bar == null:
        return
    _energy_bar.max_value = maxf(1.0, maximum)
    _energy_bar.value = current

func update_hud(shards: int, zone_name: String, objective: String) -> void:
    if _shards_label != null:
        _shards_label.text = "SHARDS  %06d" % shards
    if _zone_label != null:
        _zone_label.text = zone_name
    if _objective_label != null:
        _objective_label.text = objective

func set_status(message: String) -> void:
    if _status_label != null:
        _status_label.text = message

func _build_main_menu() -> void:
    _menu_root = Control.new()
    _menu_root.name = "MainMenu"
    _menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_menu_root)

    var background := TextureRect.new()
    background.name = "CinematicBackground"
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    if ResourceLoader.exists("res://assets/main_keyart.webp"):
        background.texture = load("res://assets/main_keyart.webp")
    _menu_root.add_child(background)

    var overlay := ColorRect.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.color = Color(0.018, 0.028, 0.06, 0.69)
    _menu_root.add_child(overlay)

    var edge_glow := ColorRect.new()
    edge_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    edge_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    edge_glow.color = Color(0.02, 0.05, 0.1, 0.08)
    _menu_root.add_child(edge_glow)

    var root_margin := MarginContainer.new()
    root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_margin.add_theme_constant_override("margin_left", 30)
    root_margin.add_theme_constant_override("margin_right", 30)
    root_margin.add_theme_constant_override("margin_top", 20)
    root_margin.add_theme_constant_override("margin_bottom", 22)
    _menu_root.add_child(root_margin)

    var page := VBoxContainer.new()
    page.add_theme_constant_override("separation", 16)
    root_margin.add_child(page)

    page.add_child(_build_top_bar())
    var main_row := HBoxContainer.new()
    main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main_row.add_theme_constant_override("separation", 18)
    page.add_child(main_row)

    main_row.add_child(_build_navigation_panel())
    var center_panel := _build_class_detail_panel()
    center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main_row.add_child(center_panel)
    main_row.add_child(_build_roster_panel())

    var footer := HBoxContainer.new()
    footer.alignment = BoxContainer.ALIGNMENT_CENTER
    footer.add_theme_constant_override("separation", 18)
    var slogan := _label("عالم محطم، وقصة لم تنتهِ بعد  •  EXPLORE  ✦  FIGHT  ✦  REBUILD", 14, Color(0.72, 0.86, 1.0))
    slogan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slogan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_child(slogan)
    var version := _label("GLYPHFALL  •  NATIVE EDITION  0.2", 10, Color(0.45, 0.65, 0.82))
    footer.add_child(version)
    page.add_child(footer)

    _update_class_details()

func _build_top_bar() -> Control:
    var bar := PanelContainer.new()
    bar.custom_minimum_size.y = 58
    bar.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.045, 0.09, 0.8), Color(0.18, 0.58, 0.82, 0.45), 12))
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 16)
    bar.add_child(row)
    var brand := VBoxContainer.new()
    brand.add_theme_constant_override("separation", 0)
    brand.add_child(_label("GLYPHFALL", 25, Color(0.84, 0.94, 1.0)))
    brand.add_child(_label("THE BROKEN WORLD  •  ECLIPSE FRONTIER", 9, Color(0.34, 0.77, 1.0)))
    row.add_child(brand)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(spacer)
    row.add_child(_badge("PLAYER 001", "LV. 01"))
    row.add_child(_badge("SHARDS", "000000"))
    row.add_child(_badge("WORLD STATUS", "STABLE"))
    return bar

func _build_navigation_panel() -> Control:
    var panel := _glass_panel()
    panel.custom_minimum_size.x = 225
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 10)
    panel.add_child(column)
    column.add_child(_label("الواجهة الرئيسية", 17, Color(0.94, 0.97, 1.0)))
    column.add_child(_label("FRONTIER OPERATIONS", 9, Color(0.27, 0.73, 0.99)))
    column.add_child(_separator())
    _add_nav_button(column, "الرئيسية  /  HOME", "⌂", true)
    _add_nav_button(column, "الشخصيات  /  HEROES", "♙", false)
    _add_nav_button(column, "المهام  /  MISSIONS", "◇", false)
    _add_nav_button(column, "المتجر  /  ARMORY", "▣", false)
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(spacer)
    var event_panel := PanelContainer.new()
    event_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.09, 0.18, 0.7), Color(0.56, 0.35, 0.92, 0.7), 10))
    var event_column := VBoxContainer.new()
    event_column.add_child(_label("✦  SEASON I", 12, Color(0.82, 0.63, 1.0)))
    event_column.add_child(_label("أصداء الانكسار", 16, Color(1.0, 0.88, 0.7)))
    event_column.add_child(_label("استعد المراسي واكشف أسرار الغابات.", 10, Color(0.76, 0.82, 0.92)))
    event_panel.add_child(event_column)
    column.add_child(event_panel)
    var settings_button := _button("الإعدادات  /  SETTINGS", Color(0.18, 0.68, 0.92), false)
    settings_button.pressed.connect(_open_settings)
    column.add_child(settings_button)
    return panel

func _build_class_detail_panel() -> Control:
    var panel := _glass_panel()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 11)
    panel.add_child(column)
    column.add_child(_label("SELECT YOUR PATH", 11, Color(0.35, 0.79, 1.0)))
    _class_title = _label("VANGUARD  •  الحارس", 29, Color(0.92, 0.97, 1.0))
    column.add_child(_class_title)
    _class_description = _label("", 12, Color(0.73, 0.83, 0.94))
    _class_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(_class_description)
    column.add_child(_separator())

    var equipment := HBoxContainer.new()
    equipment.add_theme_constant_override("separation", 12)
    var weapon_panel := _mini_info_panel("SIGNATURE WEAPON", "⚔", Color(0.15, 0.66, 0.94))
    weapon_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    equipment.add_child(weapon_panel)
    var skill_panel := _mini_info_panel("CLASS ABILITY", "✧", Color(0.71, 0.42, 1.0))
    skill_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    equipment.add_child(skill_panel)
    column.add_child(equipment)

    _class_weapon = _label("", 15, Color(0.88, 0.95, 1.0))
    column.add_child(_class_weapon)
    _class_ability = _label("", 14, Color(0.83, 0.72, 1.0))
    column.add_child(_class_ability)
    column.add_child(_separator())

    column.add_child(_label("COMBAT ATTRIBUTES", 10, Color(0.36, 0.76, 0.96)))
    _class_stats = VBoxContainer.new()
    _class_stats.add_theme_constant_override("separation", 7)
    column.add_child(_class_stats)
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(spacer)

    var action_row := HBoxContainer.new()
    action_row.add_theme_constant_override("separation", 12)
    var start := _button("ابدأ المغامرة  /  ENTER WORLD", Color(0.96, 0.59, 0.18), true)
    start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    start.custom_minimum_size.y = 58
    start.pressed.connect(func(): start_game.emit())
    action_row.add_child(start)
    var details := _button("تفاصيل الفئة", Color(0.28, 0.68, 0.92), false)
    details.custom_minimum_size.x = 118
    details.pressed.connect(func(): _status_label.text = "تم اختيار الفئة: " + str(WorldRules.class_profile(selected_class)["title"]))
    action_row.add_child(details)
    column.add_child(action_row)
    _status_label = _label("اختر أسلوب القتال المناسب لك.", 10, Color(0.55, 0.76, 0.92))
    column.add_child(_status_label)
    return panel

func _build_roster_panel() -> Control:
    var panel := _glass_panel()
    panel.custom_minimum_size.x = 300
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 10)
    panel.add_child(column)
    column.add_child(_label("WARRIOR ROSTER", 11, Color(0.33, 0.78, 1.0)))
    column.add_child(_label("قائمة الفئات", 18, Color(0.94, 0.97, 1.0)))
    column.add_child(_label("ثلاثة أساليب قتال، وثلاثة أسلحة مميزة.", 10, Color(0.66, 0.78, 0.9)))
    column.add_child(_separator())

    for class_id in CLASS_ORDER:
        var profile := WorldRules.class_profile(class_id)
        var card := Button.new()
        card.custom_minimum_size.y = 82
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.text = ""
        card.focus_mode = Control.FOCUS_ALL
        card.add_theme_stylebox_override("normal", _panel_style(Color(0.035, 0.065, 0.11, 0.91), Color(0.22, 0.39, 0.54, 0.7), 9))
        card.add_theme_stylebox_override("hover", _panel_style(Color(0.07, 0.13, 0.2, 0.96), profile["accent"], 9))
        card.add_theme_stylebox_override("pressed", _panel_style(Color(0.09, 0.17, 0.25, 0.99), profile["accent"], 9))
        var card_row := HBoxContainer.new()
        card_row.add_theme_constant_override("separation", 12)
        card.add_child(card_row)
        var emblem := _label(_class_emblem(class_id), 31, profile["accent"])
        emblem.custom_minimum_size.x = 46
        emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        card_row.add_child(emblem)
        var text_column := VBoxContainer.new()
        text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text_column.add_child(_label(str(profile["title"]), 14, Color(0.92, 0.97, 1.0)))
        text_column.add_child(_label(str(profile["name"]), 12, profile["accent"]))
        text_column.add_child(_label(str(profile["role"]).to_upper() + "  •  " + str(profile["weapon"]), 8, Color(0.59, 0.72, 0.84)))
        card_row.add_child(text_column)
        card.pressed.connect(_select_class.bind(class_id))
        column.add_child(card)
        _class_buttons[class_id] = card

    var note := PanelContainer.new()
    note.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.075, 0.12, 0.78), Color(0.25, 0.55, 0.78, 0.42), 10))
    var note_column := VBoxContainer.new()
    note_column.add_child(_label("CLASS MASTERY", 10, Color(0.36, 0.79, 1.0)))
    note_column.add_child(_label("طوّر أسلحتك وقدراتك من الملاذ الآمن.", 11, Color(0.78, 0.86, 0.96)))
    note.add_child(note_column)
    column.add_child(note)
    return panel

func _build_hud() -> void:
    _hud_root = Control.new()
    _hud_root.name = "GameplayHUD"
    _hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _hud_root.visible = false
    _hud_root.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(_hud_root)

    var top_left := PanelContainer.new()
    top_left.position = Vector2(26, 22)
    top_left.custom_minimum_size = Vector2(300, 88)
    top_left.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.032, 0.065, 0.84), Color(0.18, 0.58, 0.82, 0.52), 11))
    var status := VBoxContainer.new()
    status.add_child(_label("GLYPHFALL  •  LEVEL 01", 13, Color(0.84, 0.94, 1.0)))
    _health_bar = _progress_bar(Color(0.92, 0.21, 0.3))
    status.add_child(_health_bar)
    _energy_bar = _progress_bar(Color(0.15, 0.66, 1.0))
    status.add_child(_energy_bar)
    top_left.add_child(status)
    _hud_root.add_child(top_left)

    var objective_panel := PanelContainer.new()
    objective_panel.anchor_left = 0.5
    objective_panel.anchor_right = 0.5
    objective_panel.offset_left = -180
    objective_panel.offset_right = 180
    objective_panel.offset_top = 24
    objective_panel.offset_bottom = 84
    objective_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.035, 0.07, 0.79), Color(0.28, 0.65, 0.88, 0.43), 9))
    var objective_column := VBoxContainer.new()
    objective_column.add_child(_label("ACTIVE OBJECTIVE", 9, Color(0.4, 0.78, 1.0)))
    _objective_label = _label("استكشف البراري وابحث عن أول مرساة.", 12, Color(0.95, 0.97, 1.0))
    _objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    objective_column.add_child(_objective_label)
    objective_panel.add_child(objective_column)
    _hud_root.add_child(objective_panel)

    var right_top := VBoxContainer.new()
    right_top.anchor_left = 1.0
    right_top.anchor_right = 1.0
    right_top.offset_left = -240
    right_top.offset_right = -26
    right_top.offset_top = 24
    right_top.offset_bottom = 140
    right_top.add_child(_label("WORLD MAP  •  FRONTIER", 10, Color(0.59, 0.82, 1.0)))
    var map_panel := PanelContainer.new()
    map_panel.custom_minimum_size = Vector2(214, 88)
    map_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.05, 0.09, 0.78), Color(0.24, 0.63, 0.84, 0.52), 12))
    map_panel.add_child(_label("✦  SAFE HAVEN\n   Mirkwood  •  Sunken Grove", 11, Color(0.8, 0.91, 1.0)))
    right_top.add_child(map_panel)
    _zone_label = _label("SAFE HAVEN  •  الملاذ الآمن", 11, Color(0.42, 0.96, 0.68))
    right_top.add_child(_zone_label)
    _hud_root.add_child(right_top)

    var shard_panel := PanelContainer.new()
    shard_panel.anchor_left = 1.0
    shard_panel.anchor_right = 1.0
    shard_panel.offset_left = -220
    shard_panel.offset_right = -26
    shard_panel.offset_top = 156
    shard_panel.offset_bottom = 198
    shard_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.04, 0.08, 0.76), Color(0.23, 0.47, 0.72, 0.42), 8))
    _shards_label = _label("SHARDS  000000", 12, Color(0.92, 0.82, 0.58))
    shard_panel.add_child(_shards_label)
    _hud_root.add_child(shard_panel)

    var joystick := VirtualJoystickScript.new()
    joystick.name = "MoveJoystick"
    joystick.anchor_left = 0.0
    joystick.anchor_right = 0.0
    joystick.anchor_top = 1.0
    joystick.anchor_bottom = 1.0
    joystick.offset_left = 24
    joystick.offset_right = 212
    joystick.offset_top = -214
    joystick.offset_bottom = -26
    joystick.direction_changed.connect(func(value: Vector2): movement_changed.emit(value))
    _hud_root.add_child(joystick)

    var actions := HBoxContainer.new()
    actions.anchor_left = 1.0
    actions.anchor_right = 1.0
    actions.anchor_top = 1.0
    actions.anchor_bottom = 1.0
    actions.offset_left = -565
    actions.offset_right = -22
    actions.offset_top = -116
    actions.offset_bottom = -22
    actions.alignment = BoxContainer.ALIGNMENT_END
    actions.add_theme_constant_override("separation", 9)
    actions.mouse_filter = Control.MOUSE_FILTER_STOP
    actions.add_child(_action_button("dodge", "تفادي", "dodge", 78))
    actions.add_child(_action_button("guard", "درع", "guard", 78))
    actions.add_child(_action_button("skill", "مهارة", "skill", 86))
    actions.add_child(_action_button("heavy", "ثقيل", "heavy", 78))
    actions.add_child(_action_button("attack", "هجوم", "attack", 108, true))
    _hud_root.add_child(actions)

    var upper_actions := HBoxContainer.new()
    upper_actions.anchor_left = 1.0
    upper_actions.anchor_right = 1.0
    upper_actions.offset_left = -220
    upper_actions.offset_right = -22
    upper_actions.offset_top = 218
    upper_actions.offset_bottom = 270
    upper_actions.alignment = BoxContainer.ALIGNMENT_END
    upper_actions.add_child(_action_button("interact", "تفاعل", "interact", 64))
    upper_actions.add_child(_action_button("rebuild", "ترميم", "rebuild", 64))
    _hud_root.add_child(upper_actions)

    var pause_button := _icon_button("Ⅱ", 48, Color(0.2, 0.62, 0.88))
    pause_button.anchor_left = 1.0
    pause_button.anchor_right = 1.0
    pause_button.offset_left = -78
    pause_button.offset_right = -26
    pause_button.offset_top = 22
    pause_button.offset_bottom = 74
    pause_button.pressed.connect(func(): pause_requested.emit())
    _hud_root.add_child(pause_button)

func _build_pause_panel() -> void:
    _pause_panel = _overlay_panel()
    _pause_panel.visible = false
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    _pause_panel.add_child(column)
    column.add_child(_label("PAUSED  •  توقف مؤقت", 26, Color(0.9, 0.96, 1.0)))
    var resume := _button("متابعة اللعب  /  RESUME", Color(0.19, 0.72, 0.95), true)
    resume.pressed.connect(func(): resume_requested.emit())
    column.add_child(resume)
    var settings := _button("إعدادات الرسوم والصوت", Color(0.58, 0.47, 0.92), false)
    settings.pressed.connect(_open_settings)
    column.add_child(settings)
    var menu := _button("العودة إلى القائمة", Color(0.83, 0.47, 0.32), false)
    menu.pressed.connect(func(): new_game_requested.emit())
    column.add_child(menu)
    _hud_root.add_child(_pause_panel)

func _build_settings_panel() -> void:
    _settings_panel = _overlay_panel()
    _settings_panel.visible = false
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    _settings_panel.add_child(column)
    column.add_child(_label("GRAPHICS PRESET  •  جودة الرسوم", 21, Color(0.92, 0.97, 1.0)))
    column.add_child(_label("يتكيف الأداء مع قدرة الهاتف وحرارته.", 11, Color(0.68, 0.8, 0.93)))
    for quality in ["performance", "balanced", "high"]:
        var label_text := "الأداء  /  PERFORMANCE" if quality == "performance" else "متوازن  /  BALANCED" if quality == "balanced" else "مرتفع  /  HIGH"
        var button := _button(label_text, Color(0.22, 0.7, 0.94), quality == current_quality)
        button.pressed.connect(_set_quality.bind(quality))
        column.add_child(button)
    var back := _button("عودة  /  BACK", Color(0.84, 0.6, 0.27), false)
    back.pressed.connect(_close_settings)
    column.add_child(back)
    add_child(_settings_panel)

func _open_settings() -> void:
    _settings_panel.visible = true
    if _pause_panel != null:
        _pause_panel.visible = false

func _close_settings() -> void:
    _settings_panel.visible = false
    if _hud_root.visible and _pause_panel != null:
        _pause_panel.visible = true

func _set_quality(quality: String) -> void:
    current_quality = quality
    quality_changed.emit(quality)
    _settings_panel.visible = false
    if _hud_root.visible and _pause_panel != null:
        _pause_panel.visible = true
    else:
        show_menu()

func _select_class(class_id: String) -> void:
    selected_class = class_id
    _update_class_details()
    class_selected.emit(class_id)
    _status_label.text = "تم اختيار الفئة: " + str(WorldRules.class_profile(class_id)["title"])

func _update_class_details() -> void:
    var profile := WorldRules.class_profile(selected_class)
    _class_title.text = str(profile["title"]) + "  •  " + str(profile["name"])
    _class_weapon.text = "⚔  " + str(profile["weapon_ar"]) + "  /  " + str(profile["weapon"])
    _class_ability.text = "✧  " + str(profile["ability_ar"]) + "  /  " + str(profile["ability"])
    _class_description.text = str(profile["description"])
    for class_id in _class_buttons:
        var button: Button = _class_buttons[class_id]
        button.modulate = Color.WHITE if class_id == selected_class else Color(0.72, 0.8, 0.92)
    for child in _class_stats.get_children():
        child.queue_free()
    _add_stat_row("HEALTH", float(profile["health"]) / 200.0, Color(0.94, 0.29, 0.39))
    _add_stat_row("MOBILITY", float(profile["speed"]) / 10.0, Color(0.16, 0.72, 1.0))
    _add_stat_row("DAMAGE", float(profile["damage"]) / 1.4, Color(0.98, 0.66, 0.2))
    _add_stat_row("GUARD", 1.0 - float(profile["guard"]), Color(0.58, 0.45, 1.0))

func _add_stat_row(title: String, value: float, accent: Color) -> void:
    var row := VBoxContainer.new()
    var header := HBoxContainer.new()
    header.add_child(_label(title, 9, Color(0.72, 0.84, 0.96)))
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(spacer)
    header.add_child(_label("%d%%" % roundi(clampf(value, 0.0, 1.0) * 100.0), 9, accent))
    row.add_child(header)
    var bar := _progress_bar(accent)
    bar.max_value = 100.0
    bar.value = clampf(value, 0.0, 1.0) * 100.0
    row.add_child(bar)
    _class_stats.add_child(row)

func _add_nav_button(parent: VBoxContainer, text_value: String, emblem: String, active: bool) -> void:
    var button := Button.new()
    button.text = emblem + "   " + text_value
    button.custom_minimum_size.y = 44
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.add_theme_font_size_override("font_size", 11)
    var accent := Color(0.9, 0.62, 0.24) if active else Color(0.28, 0.66, 0.9)
    button.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
    button.add_theme_stylebox_override("normal", _panel_style(Color(0.035, 0.065, 0.11, 0.76), accent.darkened(0.35), 8))
    button.add_theme_stylebox_override("hover", _panel_style(Color(0.08, 0.15, 0.24, 0.9), accent, 8))
    button.pressed.connect(func(): _status_label.text = text_value)
    parent.add_child(button)

func _mini_info_panel(title: String, icon_text: String, accent: Color) -> Control:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.065, 0.12, 0.8), accent.darkened(0.28), 9))
    var column := VBoxContainer.new()
    column.add_child(_label(icon_text, 26, accent))
    column.add_child(_label(title, 8, accent))
    panel.add_child(column)
    return panel

func _action_button(action_id: String, label_text: String, icon_key: String, dimension: float, primary: bool = false) -> Button:
    var button := Button.new()
    button.custom_minimum_size = Vector2(dimension, dimension)
    button.text = _action_symbol(icon_key) + "\n" + label_text
    button.add_theme_font_size_override("font_size", 13 if primary else 11)
    button.add_theme_color_override("font_color", Color(0.97, 0.99, 1.0))
    button.add_theme_stylebox_override("normal", _panel_style(Color(0.025, 0.065, 0.12, 0.89), Color(0.24, 0.68, 0.96, 0.82), 100 if primary else 16))
    button.add_theme_stylebox_override("hover", _panel_style(Color(0.09, 0.17, 0.27, 0.97), Color(0.62, 0.85, 1.0), 100 if primary else 16))
    button.add_theme_stylebox_override("pressed", _panel_style(Color(0.14, 0.23, 0.35, 1.0), Color(1.0, 0.7, 0.25), 100 if primary else 16))
    button.tooltip_text = label_text
    button.pressed.connect(func(): action_requested.emit(action_id))
    return button

func _action_symbol(icon_key: String) -> String:
    match icon_key:
        "attack": return "⚔"
        "heavy": return "✦"
        "guard": return "◈"
        "dodge": return "➤"
        "skill": return "✧"
        "interact": return "✋"
        "rebuild": return "⌘"
    return "•"

func _icon_button(text_value: String, dimension: float, accent: Color) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(dimension, dimension)
    button.add_theme_font_size_override("font_size", 20)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.05, 0.1, 0.85), accent, 14))
    return button

func _progress_bar(accent: Color) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.custom_minimum_size.y = 12
    bar.min_value = 0.0
    bar.max_value = 100.0
    bar.value = 100.0
    bar.show_percentage = false
    var background := StyleBoxFlat.new()
    background.bg_color = Color(0.015, 0.025, 0.05, 0.92)
    background.set_corner_radius_all(8)
    var fill := StyleBoxFlat.new()
    fill.bg_color = accent
    fill.set_corner_radius_all(8)
    bar.add_theme_stylebox_override("background", background)
    bar.add_theme_stylebox_override("fill", fill)
    return bar

func _badge(title: String, value: String) -> Control:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.05, 0.095, 0.7), Color(0.21, 0.53, 0.73, 0.4), 8))
    var column := VBoxContainer.new()
    column.add_child(_label(title, 8, Color(0.37, 0.76, 0.99)))
    column.add_child(_label(value, 11, Color(0.91, 0.96, 1.0)))
    panel.add_child(column)
    return panel

func _button(text_value: String, accent: Color, primary: bool) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size.y = 42
    button.add_theme_font_size_override("font_size", 12)
    button.add_theme_color_override("font_color", Color(0.035, 0.055, 0.08) if primary else Color(0.91, 0.96, 1.0))
    button.add_theme_stylebox_override("normal", _panel_style(accent if primary else Color(0.035, 0.07, 0.12, 0.88), accent, 9))
    button.add_theme_stylebox_override("hover", _panel_style(accent.lightened(0.18), Color(0.92, 0.96, 1.0), 9))
    button.add_theme_stylebox_override("pressed", _panel_style(accent.darkened(0.12), accent.lightened(0.24), 9))
    return button

func _label(text_value: String, size: int, tint: Color) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", tint)
    label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.04, 0.82))
    label.add_theme_constant_override("outline_size", 1)
    return label

func _separator() -> Control:
    var line := ColorRect.new()
    line.custom_minimum_size.y = 1
    line.color = Color(0.36, 0.65, 0.84, 0.26)
    return line

func _glass_panel() -> PanelContainer:
    var panel := PanelContainer.new()
    var style := _panel_style(Color(0.018, 0.032, 0.065, 0.82), Color(0.2, 0.56, 0.8, 0.46), 12)
    style.content_margin_left = 15
    style.content_margin_right = 15
    style.content_margin_top = 13
    style.content_margin_bottom = 13
    panel.add_theme_stylebox_override("panel", style)
    return panel

func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style

func _overlay_panel() -> PanelContainer:
    var overlay := PanelContainer.new()
    overlay.anchor_left = 0.5
    overlay.anchor_right = 0.5
    overlay.anchor_top = 0.5
    overlay.anchor_bottom = 0.5
    overlay.offset_left = -210
    overlay.offset_right = 210
    overlay.offset_top = -205
    overlay.offset_bottom = 205
    var style := _panel_style(Color(0.02, 0.045, 0.09, 0.97), Color(0.28, 0.72, 0.98), 15)
    style.content_margin_left = 22
    style.content_margin_right = 22
    style.content_margin_top = 24
    style.content_margin_bottom = 24
    overlay.add_theme_stylebox_override("panel", style)
    return overlay

func _class_emblem(class_id: String) -> String:
    match class_id:
        "vanguard": return "✦"
        "phantom": return "◈"
        "bastion": return "⬡"
    return "✧"
