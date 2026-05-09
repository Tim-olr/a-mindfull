extends Node2D
@onready var black: Sprite2D = $CanvasLayer/Black
@onready var load_timer: Timer = $LoadTimer
@onready var projectiles: Node2D = $projectiles
@onready var dmg_nrs: Node2D = $dmgNrs

const ITEM_INTERACTABLE = preload("uid://cgwfugy5k2bsj")
const FOG_MAP_SCRIPT = preload("res://scripts/main game/ui/fog_of_war_map.gd")

var fog_map: CanvasLayer

func _ready() -> void:
	load_timer.start()
	GlobalPlayer.visuals.deleteBlack()
	GameManager.is_in_lobby = false
	GlobalWorld.projectiles = projectiles
	GlobalWorld.theWorld = self
	GlobalWorld.dmgNrs = dmg_nrs
	GlobalPlayer.stats.canAttack = true
	var playerSpirit = GlobalPlayer.stats.playerSpirit.scene.instantiate()
	playerSpirit.host = GlobalPlayer.player
	GlobalPlayer.stats.playerSpiritScene = playerSpirit
	GlobalPlayer.player.add_child(playerSpirit)
	for entry in GlobalSafe.saved_inventory:
		var idx: int = entry["slot_index"]
		if idx >= 0 and idx < GlobalPlayer.inventory.inventory.slots.size():
			GlobalPlayer.inventory.inventory.slots[idx].set_item(entry["item"], entry["count"])
	FahrerDeck.draw_cards()
	_setup_fog_map()

func _setup_fog_map() -> void:
	fog_map = CanvasLayer.new()
	fog_map.set_script(FOG_MAP_SCRIPT)
	add_child(fog_map)
	var proc_gen = get_node_or_null("ProceduralGeneration")
	var tile_map_layer = get_node_or_null("TileMapLayer")
	if proc_gen != null and tile_map_layer != null:
		fog_map.setup(tile_map_layer, proc_gen.world_size)

func _on_load_timer_timeout() -> void:
	black.hide()

func _on_refresh_timer_timeout() -> void:
	pass # Replace with function body.
