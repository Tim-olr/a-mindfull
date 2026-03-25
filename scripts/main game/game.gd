extends Node2D

@onready var shard_counter_lobby: Node2D = $shard_counter_lobby

func _ready() -> void:
	GlobalPlayer.stats.canAttack = false
	var playerSpirit = GlobalPlayer.stats.playerSpirit.scene.instantiate()
	playerSpirit.host = GlobalPlayer.player
	GlobalPlayer.stats.playerSpiritScene = playerSpirit
	GlobalPlayer.player.add_child(playerSpirit)
	print("safe: ", GlobalSafe.safe)
	GameManager.is_in_lobby = true
	
