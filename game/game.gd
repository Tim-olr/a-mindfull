extends Node2D

func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	GlobalPlayer.stats.canAttack = false
	var playerSpirit = GlobalPlayer.stats.playerSpirit.scene.instantiate()
	playerSpirit.host = GlobalPlayer.player
	GlobalPlayer.stats.playerSpiritScene = playerSpirit
	GlobalPlayer.player.add_child(playerSpirit)
	print("safe (weapons brought home): ", GlobalSafe.safe)
	GameManager.is_in_lobby = true
	GlobalPlayer.visuals.init_health_display(GlobalPlayer.stats.base_max_hp)
	var inv := GlobalPlayer.inventory.inventory
	inv.set_total_capacity(GlobalPlayer.stats.max_weapons)

