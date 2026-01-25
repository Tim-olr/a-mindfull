extends CharacterBody2D

class_name Spirit

@export var Name: String
@export var attackDamage: float
@export var attackType: String
@export var out: bool = false
@export var canGetAttacked: bool = true

@export var follow_distance: float = 150.0
@export var smooth_speed: float = 8.0

@onready var ap: AnimationPlayer = $AnimationPlayer

var host: CharacterBody2D

func _ready() -> void:
	top_level = true 
	host = get_parent()
	print(host)

func _physics_process(delta: float) -> void:
	if !host:
		return
	add_collision_exception_with(host)
	var movement_script = host.player_movement
	if !movement_script:
		return
	var move_dir = movement_script.last_movement_direction
	
	var target_pos = host.global_position
	if out:
		target_pos -= move_dir * follow_distance
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
	rotation = lerp_angle(rotation, move_dir.angle(), smooth_speed * delta)

func bring_out():
	if !out:
		out = true
		canGetAttacked = true
		ap.play("BringOut")

func bring_in():
	if out:
		out = false
		canGetAttacked = false
		ap.play("BringIn")

func attack():
	pass

func applyPassive():
	pass
