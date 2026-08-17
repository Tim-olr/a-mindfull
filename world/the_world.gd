extends Node2D
@onready var black: Sprite2D = $CanvasLayer/Black
@onready var load_timer: Timer = $LoadTimer
@onready var projectiles: Node2D = $projectiles
@onready var dmgNrs: Node2D = $dmgNrs
@onready var dungeon_generator: DungeonGenerator = $DungeonGenerator

## Entry point for a dungeon run: generates the floor layout, then wires up
## the player, globals, and the weapons carried in from the hub.

func _ready() -> void:
	GlobalWorld.dungeon_generator = dungeon_generator
	var start_room: DungeonRoom = dungeon_generator.rooms.get(Vector2i.ZERO)
	if start_room and is_instance_valid(GlobalPlayer.camera):
		GlobalPlayer.camera.snap_to_room(start_room)
	load_timer.start()
	GlobalPlayer.visuals.deleteBlack()
	GameManager.is_in_lobby = false
	GlobalWorld.projectiles = projectiles
	GlobalWorld.theWorld = self
	GlobalWorld.dmgNrs = dmgNrs
	GlobalPlayer.stats.canAttack = true
	var playerSpirit = GlobalPlayer.stats.playerSpirit.scene.instantiate()
	playerSpirit.host = GlobalPlayer.player
	GlobalPlayer.stats.playerSpiritScene = playerSpirit
	GlobalPlayer.player.add_child(playerSpirit)
	GlobalPlayer.visuals.init_health_display(GlobalPlayer.stats.maxHp)

	# Apply spirit cooldown reduction to the active spirit
	if is_instance_valid(GlobalPlayer.stats.playerSpiritScene):
		var spirit = GlobalPlayer.stats.playerSpiritScene
		var cdr = GlobalPlayer.stats.spirit_cooldown_reduction
		if cdr > 0.0:
			spirit.activeAbilityCooldown = maxf(0.1, spirit.activeAbilityCooldown * (1.0 - cdr))
			if is_instance_valid(spirit.active_ability_timer):
				spirit.active_ability_timer.wait_time = spirit.activeAbilityCooldown

	# Weapons carried in from the hub (set by max_weapons, extended by upgrades)
	var inv := GlobalPlayer.inventory.inventory
	inv.set_total_capacity(GlobalPlayer.stats.max_weapons)

	for entry in GlobalSafe.saved_inventory:
		var idx: int = entry["slot_index"]
		if idx >= 0 and idx < GlobalPlayer.inventory.inventory.slots.size():
			GlobalPlayer.inventory.inventory.slots[idx].set_item(entry["item"], entry["count"])
	ArtifactManager.clear()

func _on_load_timer_timeout() -> void:
	black.hide()
