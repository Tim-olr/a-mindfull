extends CharacterBody2D
class_name  Player

@onready var player_movement = $PlayerMovement
@onready var stats = $PlayerStats
@onready var manager = $PlayerManager
@onready var player_inventory: Node2D = $PlayerInventory
@onready var camera_2d: Camera2D = $Camera2D
@onready var spirit_bullet_marker: Marker2D = $SpiritBulletMarker
@onready var player_specials: Node2D = $PlayerSpecials

func _ready() -> void:
	GlobalPlayer.player = self
	GlobalSafe.currentInventory = player_inventory.inventory
	GlobalPlayer.inventory = player_inventory
	GlobalPlayer.camera = camera_2d
	GlobalPlayer.manager = manager
	GlobalPlayer.movement = player_movement
	GlobalPlayer.spiritMarker = spirit_bullet_marker
	GlobalPlayer.specials = player_specials
