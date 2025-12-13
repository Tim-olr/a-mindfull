extends Node2D

@onready var Player = $".."
@onready var Stats: Node2D = $"../PlayerStats"
var direction
var walkingVelocity = Vector2.ZERO
var extraVelocity = Vector2.ZERO

func _physics_process(delta):
	direction = Input.get_vector("left", "right", "up", "down")    
	var target = direction * Stats.Speed                                           
	walkingVelocity = lerp(Player.velocity, target, Stats.SlideAmount * delta)     
	Player.velocity = walkingVelocity + extraVelocity
	Player.move_and_slide()     
