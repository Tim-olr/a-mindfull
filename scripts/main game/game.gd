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
	
