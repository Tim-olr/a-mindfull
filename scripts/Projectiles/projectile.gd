extends CharacterBody2D
class_name Projectile

@onready var life_time: Timer = $LifeTime

var rot
@export var damage: float
@export var lifetime: float
@export var projectileSpeed: float
@export var pierce: int = 1

func _ready() -> void:
	life_time.start(lifetime)

func _on_life_time_timeout() -> void:
	queue_free()

func _physics_process(delta):
	velocity = Vector2(projectileSpeed,0).rotated(rot)
	move_and_slide()
