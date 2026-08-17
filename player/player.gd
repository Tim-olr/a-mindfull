extends CharacterBody2D
class_name  Player

@onready var player_movement = $PlayerMovement
@onready var stats = $PlayerStats
@onready var manager = $PlayerManager
@onready var player_inventory: Node2D = $PlayerInventory
@onready var camera_2d: Camera2D = $Camera2D
@onready var spirit_bullet_marker: Marker2D = $SpiritBulletMarker
@onready var player_specials: Node2D = $PlayerSpecials
@onready var player_components: Node2D = $PlayerComponents


func _ready() -> void:
	GlobalPlayer.player = self
	GlobalPlayer.inventory = player_inventory
	GlobalPlayer.camera = camera_2d
	GlobalPlayer.manager = manager
	GlobalPlayer.movement = player_movement
	GlobalPlayer.spiritMarker = spirit_bullet_marker
	GlobalPlayer.specials = player_specials
	GlobalPlayer.components = player_components

var _debug_timer := 0.0
func _process(delta: float) -> void:
	_debug_timer += delta
	if _debug_timer >= 0.5:
		_debug_timer = 0.0
		var sprite = $PlayerVisuals/PlayerSprites
		var room = GlobalWorld.current_room
		print("DEBUG pos=", global_position, " visible=", sprite.visible, " modulate=", sprite.modulate,
			" self_modulate=", sprite.self_modulate, " z_index=", z_index,
			" room=", (room.grid_position if room else "none"),
			" cam_pos=", (camera_2d.global_position if camera_2d else "none"))
