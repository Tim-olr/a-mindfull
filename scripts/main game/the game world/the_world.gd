extends Node2D
@onready var black: Sprite2D = $CanvasLayer/Black
@onready var load_timer: Timer = $LoadTimer
@onready var projectiles: Node2D = $projectiles
@onready var dmg_nrs: Node2D = $dmgNrs
@onready var tile_map_layer: TileMapLayer = $TileMapLayer

const ITEM_INTERACTABLE = preload("uid://cgwfugy5k2bsj")

func _ready() -> void:
	load_timer.start()
	GlobalPlayer.visuals.deleteBlack()
	GameManager.is_in_lobby = false
	GlobalWorld.projectiles = projectiles
	GlobalWorld.theWorld = self
	GlobalWorld.dmgNrs = dmg_nrs
	GlobalPlayer.stats.canAttack = true
	FogOfWar.register_tilemap(tile_map_layer)
	var playerSpirit = GlobalPlayer.stats.playerSpirit.scene.instantiate()
	playerSpirit.host = GlobalPlayer.player
	GlobalPlayer.stats.playerSpiritScene = playerSpirit
	GlobalPlayer.player.add_child(playerSpirit)
	WiseTree.apply_stat_bonuses(GlobalPlayer.stats)

	# Apply spirit cooldown reduction to the active spirit
	if is_instance_valid(GlobalPlayer.stats.playerSpiritScene):
		var spirit = GlobalPlayer.stats.playerSpiritScene
		var cdr = GlobalPlayer.stats.spirit_cooldown_reduction
		if cdr > 0.0:
			spirit.activeAbilityCooldown = maxf(0.1, spirit.activeAbilityCooldown * (1.0 - cdr))
			if is_instance_valid(spirit.active_ability_timer):
				spirit.active_ability_timer.wait_time = spirit.activeAbilityCooldown

	# Cartographer: reveal a large area around the player's starting tile
	if WiseTree.is_unlocked("station_cartographer"):
		FogOfWar.reveal_area(FogOfWar.get_player_tile(), 30)

	# Apply bonus inventory slots from Pack Rat upgrades
	if GlobalPlayer.stats.bonus_inv_slots > 0:
		GlobalPlayer.inventory.inventory.extend_capacity(GlobalPlayer.stats.bonus_inv_slots)

	for entry in GlobalSafe.saved_inventory:
		var idx: int = entry["slot_index"]
		if idx >= 0 and idx < GlobalPlayer.inventory.inventory.slots.size():
			GlobalPlayer.inventory.inventory.slots[idx].set_item(entry["item"], entry["count"])
	FahrerDeck.draw_cards()

func _on_load_timer_timeout() -> void:
	black.hide()

func _on_refresh_timer_timeout() -> void:
	pass # Replace with function body.
