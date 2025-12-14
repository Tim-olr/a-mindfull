extends CharacterBody2D

class_name Spirit

@export var Name: String
@export var attackDamage: float
@export var attackType: String
@export var out: bool = false
@export var canGetAttacked: bool = true

@export var follow_distance: float = 60.0
@export var smooth_speed: float = 8.0

@onready var ap: AnimationPlayer = $AnimationPlayer

var host: CharacterBody2D
var last_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	top_level = true 

func _physics_process(delta: float) -> void:
	if !host:
		return
	
	add_collision_exception_with(host)

	if host.velocity.length_squared() > 200.0:
		last_direction = host.velocity.normalized()
	
	var target_pos = host.global_position
	
	if out:
		target_pos -= last_direction * follow_distance
	
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
	rotation = lerp_angle(rotation, last_direction.angle(), smooth_speed * delta)

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
