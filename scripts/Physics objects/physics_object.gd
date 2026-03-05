extends RigidBody2D
class_name PhysicsObject

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export_category("General Settings")
@export var Name: String

@export_category("Physics Settings")
@export var pushable: bool
@export var can_pass_through: bool
@export var stops_bullets: bool = true

@export_category("Loot Settings")
@export var drops_something: bool
@export var drop: ItemResource
@export var drop_amount: int

@export_category("Other Settings")
@export var max_health: int
@export var health: int = 0
@export var does_damage: bool
@export var damage_amount: float
@export var damage_resistance: int = 0
@export_enum("Axe", "Pickaxe", "Bullet", "Shovel") var prefered_tool
@export_range(0, 100, 0.1) var damage_amplifier = 0.0

func _ready() -> void:
	if drops_something:
		var interactable = ItemInteractable.new()
		drop.amount = drop_amount
		interactable.item = drop
		GlobalWorld.theWorld.add_child(interactable)
	init_health()
	init_settings()

func init_settings():
	if !pushable:
		freeze = true
	else:
		freeze = false
	if can_pass_through and stops_bullets:
		collision_layer = 4
	elif can_pass_through:
		collision_layer = 2
	else:
		collision_layer = 1
	if stops_bullets:
		add_to_group("wall")
	else:
		if is_in_group("wall"):
			remove_from_group("wall")

func init_health():
	health = max_health
