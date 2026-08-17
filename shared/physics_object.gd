extends StaticBody2D
class_name PhysicsObject

## A static, non-pushable world obstacle. Configure per-instance to act as a
## plain wall, a destroyable obstacle (crate, rubble, whatever), or both.
## Any weapon/projectile damages it the same way — there's no tool-gating.

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
const ITEM_INTERACTABLE = preload("uid://cgwfugy5k2bsj")

@export_category("General Settings")
@export var Name: String

@export_category("Physics Settings")
@export var can_pass_through: bool
@export var stops_bullets: bool = true

@export_category("Loot Settings")
@export var drops_something: bool
@export var drop: ItemResource
@export var drop_amount: int

@export_category("Other Settings")
@export var destroyable: bool = false
@export var max_health: int = 10
@export var health: int = 0
@export var hide_txtr: bool = false
@export var has_on_touch: bool = false

func _ready() -> void:
	init_health()
	init_settings()
	add_to_group("physics_object")

func damage(amount: float) -> void:
	if not destroyable:
		return
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	if drops_something:
		var interactable = ITEM_INTERACTABLE.instantiate()
		drop.amount = drop_amount
		interactable.item = drop
		if is_instance_valid(GlobalWorld.theWorld):
			GlobalWorld.theWorld.add_child(interactable)
			interactable.global_position = global_position
	queue_free()

func init_settings():
	visible = not hide_txtr
	if can_pass_through and stops_bullets:
		collision_layer = 4
	elif can_pass_through:
		collision_layer = 2
	else:
		collision_layer = 1
	if stops_bullets:
		add_to_group("wall")
	elif is_in_group("wall"):
		remove_from_group("wall")
	if destroyable:
		add_to_group("destructible")
	elif is_in_group("destructible"):
		remove_from_group("destructible")

func init_health():
	health = max_health

func on_touch(_area):
	pass

func _on_area_2d_area_entered(area: Area2D) -> void:
	on_touch(area)
