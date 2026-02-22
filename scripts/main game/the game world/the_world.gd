extends Node2D
@onready var black: Sprite2D = $CanvasLayer/Black
@onready var load_timer: Timer = $LoadTimer
@onready var projectiles: Node2D = $projectiles
@onready var dmg_nrs: Node2D = $dmgNrs

func _ready() -> void:
	load_timer.start()
	GlobalPlayer.visuals.deleteBlack()
	GlobalWorld.projectiles = projectiles
	GlobalWorld.theWorld = self
	GlobalWorld.dmgNrs = dmg_nrs
	GlobalPlayer.stats.canAttack = true
	var playerSpirit = GlobalPlayer.stats.playerSpirit.scene.instantiate()
	playerSpirit.host = GlobalPlayer.player
	playerSpirit.canAttack = true
	GlobalPlayer.stats.playerSpiritScene = playerSpirit
	GlobalPlayer.player.add_child(playerSpirit)
	GlobalPlayer.inventory.setPlayerInvToGlobal()

func _on_load_timer_timeout() -> void:
	black.hide()


func _on_refresh_timer_timeout() -> void:
	pass # Replace with function body.
