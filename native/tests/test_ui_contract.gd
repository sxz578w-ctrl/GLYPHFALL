extends SceneTree

const GameUIScript = preload("res://scripts/game_ui.gd")

func _initialize() -> void:
    var ui := GameUIScript.new()
    root.add_child(ui)
    await process_frame
    assert(ui.has_signal("start_game"))
    assert(ui.has_signal("class_selected"))
    assert(ui.has_signal("action_requested"))
    assert(ui.has_signal("movement_changed"))
    assert(ui.has_signal("retry_requested"))
    ui.set_selected_class("phantom")
    assert(ui.selected_class == "phantom")
    ui.set_selected_class("bastion")
    assert(ui.selected_class == "bastion")
    var merchant_closed := [false]
    ui.merchant_closed.connect(func(): merchant_closed[0] = true)
    ui.show_keeper(125)
    assert(ui._keeper_panel != null and ui._keeper_panel.visible)
    ui.update_keeper_shards(75)
    ui.close_keeper()
    assert(merchant_closed[0])
    assert(not ui._keeper_panel.visible)
    print("GLYPHFALL native UI contract tests: PASS")
    ui.queue_free()
    quit()
