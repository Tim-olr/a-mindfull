extends CharacterBody2D

@onready var player_movement = $PlayerMovement
@onready var stats = $PlayerStats
@onready var manager = $PlayerManager
@onready var player_inventory: Node2D = $PlayerInventory
@onready var camera_2d: Camera2D = $Camera2D

func _ready() -> void:
	GlobalPlayer.player = self
	GlobalSafe.currentInventory = player_inventory.inventory
	GlobalPlayer.inventory = player_inventory
	GlobalPlayer.camera = camera_2d
