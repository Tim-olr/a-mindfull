extends Node2D

func _ready() -> void:
	GlobalPlayer.stats.canAttack = false
	var playerSpirit = GlobalPlayer.stats.playerSpirit.scene.instantiate()
	playerSpirit.host = GlobalPlayer.player
	playerSpirit.canAttack = false
	print(playerSpirit.canAttack)
	GlobalPlayer.stats.playerSpiritScene = playerSpirit
	GlobalPlayer.player.add_child(playerSpirit)
	GlobalPlayer.inventory.inventory = GlobalSafe.currentInventory
	print("safe: ", GlobalSafe.safe)
