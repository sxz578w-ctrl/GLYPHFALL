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
    print("GLYPHFALL native UI contract tests: PASS")
    ui.queue_free()
    quit()
