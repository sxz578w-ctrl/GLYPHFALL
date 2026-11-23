extends SceneTree

const Progression = preload("res://scripts/progression_service.gd")

func _initialize() -> void:
    var state: Dictionary = Progression.defaults()
    assert(Progression.current_objective(state)["id"] == "discover_mirkwood")

    state = Progression.mark_site_discovered(state, "sunken_grove")
    assert(Progression.current_objective(state)["id"] == "discover_mirkwood", "Out-of-order discoveries must not skip the first region")

    state = Progression.mark_site_discovered(state, "mirkwood")
    assert(Progression.current_objective(state)["id"] == "clear_mirkwood")

    state = Progression.mark_site_cleared(state, "mirkwood")
    assert(Progression.current_objective(state)["id"] == "restore_mirkwood")
    assert(not Progression.is_site_restored(state, "sunken_grove"), "A site cannot be restored before it is cleared")

    state = Progression.mark_site_restored(state, "mirkwood")
    assert(Progression.current_objective(state)["id"] == "clear_mirkwood" or Progression.current_objective(state)["id"] == "discover_sunken_grove" or Progression.current_objective(state)["id"] == "clear_sunken_grove")

    state = Progression.mark_site_discovered(state, "sunken_grove")
    state = Progression.mark_site_cleared(state, "sunken_grove")
    state = Progression.mark_site_restored(state, "sunken_grove")
    assert(Progression.current_objective(state)["id"] == "return_haven")
    assert(not bool(state["campaign_complete"]))

    state = Progression.mark_returned_to_haven(state)
    assert(bool(state["campaign_complete"]))
    assert(Progression.current_objective(state)["id"] == "campaign_complete")
    assert(Progression.completed_steps(state) == Progression.TOTAL_STEPS)

    var safe := Progression.normalise({
        "discovered_sites": ["mirkwood", "../../unknown", "mirkwood", "sunken_grove"],
        "cleared_sites": ["mirkwood", "invalid"],
        "restored_sites": ["sunken_grove"],
        "kills": -20,
        "deaths": 9999999999,
        "play_time_seconds": -2.0,
        "campaign_complete": true
    })
    assert(safe["discovered_sites"].size() == 2)
    assert(safe["cleared_sites"].size() == 1)
    assert(safe["restored_sites"].is_empty(), "Restored sites require a cleared site")
    assert(safe["kills"] == 0)
    assert(safe["deaths"] == 999999)
    assert(safe["play_time_seconds"] == 0.0)
    assert(not safe["campaign_complete"])

    state = Progression.record_kill(state)
    state = Progression.record_death(state)
    state = Progression.add_play_time(state, 12.5)
    assert(state["kills"] == 1)
    assert(state["deaths"] == 1)
    assert(state["play_time_seconds"] == 12.5)

    print("GLYPHFALL progression service tests: PASS")
    quit(0)
