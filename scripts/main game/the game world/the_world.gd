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
	# Restore each item into the exact slot it came from
	for entry in GlobalSafe.saved_inventory:
		var idx: int = entry["slot_index"]
		if idx >= 0 and idx < GlobalPlayer.inventory.inventory.slots.size():
			GlobalPlayer.inventory.inventory.slots[idx].set_item(entry["item"], entry["count"])

func _on_load_timer_timeout() -> void:
	black.hide()


func _on_refresh_timer_timeout() -> void:
	pass # Replace with function body.
