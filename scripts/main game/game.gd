extends Node2D

@onready var shard_counter_lobby: Node2D = $shard_counter_lobby

func _ready() -> void:
	get_tree().paused = false
	GlobalPlayer.stats.canAttack = false
	# Clear last run's Fahrer cards before reusing global stats in the lobby.
	FahrerDeck.clear_active()
	# Also unlock day/night in case a Sun/Moon card was active last run.
	DayNightCycle.lock_time = false
	var playerSpirit = GlobalPlayer.stats.playerSpirit.scene.instantiate()
	playerSpirit.host = GlobalPlayer.player
	GlobalPlayer.stats.playerSpiritScene = playerSpirit
	GlobalPlayer.player.add_child(playerSpirit)
	print("safe: ", GlobalSafe.safe)
	GameManager.is_in_lobby = true
	_apply_hub_bonuses()
	if not WiseTree.tree_changed.is_connected(_apply_hub_bonuses):
		WiseTree.tree_changed.connect(_apply_hub_bonuses)

func _apply_hub_bonuses() -> void:
	GlobalPlayer.visuals.init_health_display(
		WiseTree.preview_max_hp(GlobalPlayer.stats.base_max_hp)
	)
	var inv := GlobalPlayer.inventory.inventory
	inv.set_total_capacity(inv.base_slot_amount + WiseTree.get_bonus_inv_slots())
	
