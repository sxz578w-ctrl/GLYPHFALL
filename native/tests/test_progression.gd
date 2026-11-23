extends SceneTree

const PlayerScript = preload("res://scripts/player_controller.gd")

func _initialize() -> void:
    var player: PlayerController = PlayerScript.new()
    player.select_class("vanguard")
    var base_damage: float = player._damage_multiplier
    var base_health: float = player.max_health
    if not player.purchase_upgrade("damage"):
        _fail("first damage upgrade should be purchasable")
        return
    if player._damage_multiplier <= base_damage:
        _fail("damage rank must increase weapon damage")
        return
    if not player.purchase_upgrade("vitality"):
        _fail("first vitality upgrade should be purchasable")
        return
    if player.max_health <= base_health:
        _fail("vitality rank must increase maximum health")
        return
    for i in range(9):
        player.purchase_upgrade("damage")
        player.purchase_upgrade("vitality")
    if player.purchase_upgrade("damage") or player.purchase_upgrade("vitality"):
        _fail("upgrade ranks must enforce the maximum level")
        return
    print("GLYPHFALL native progression tests: PASS")
    player.free()
    quit(0)

func _fail(message: String) -> void:
    printerr("GLYPHFALL native progression test failed: " + message)
    quit(1)
