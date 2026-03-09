extends RigidBody2D
class_name PhysicsObject

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export_category("General Settings")
@export var Name: String

@export_category("Physics Settings")
@export var pushable: bool
@export var can_pass_through: bool
@export var stops_bullets: bool = true
@export var friction: float = 20.0

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
@export var hide_txtr: bool = false
@export var has_on_touch: bool = false

func _ready() -> void:
	init_health()
	init_settings()

func _physics_process(delta: float) -> void:
	if health <= 0:
		if drops_something:
			var interactable = ItemInteractable.new()
			drop.amount = drop_amount
			interactable.item = drop
			GlobalWorld.theWorld.add_child(interactable)
		queue_free()

func init_settings():
	linear_damp = friction
	if hide_txtr:
		visible = false
	else:
		visible = true
	if !pushable:
		freeze = true
	else:
		freeze = false
		linear_damp = 20.0
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

func on_touch(_area):
	pass

func _on_area_2d_area_entered(area: Area2D) -> void:
	on_touch(area)
