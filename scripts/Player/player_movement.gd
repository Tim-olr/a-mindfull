extends Node2D

@onready var Player = $".."
@onready var Stats: Node2D = $"../PlayerStats"
@onready var dash_cooldown: Timer = $DashCooldown
@onready var immunity_time: Timer = $ImmunityTime

var direction = Vector2.ZERO
var last_movement_direction = Vector2.DOWN 
var walkingVelocity = Vector2.ZERO
var dodgeVelocity = Vector2.ZERO
var extraVelocity = Vector2.ZERO

var canDodge = true
var isDodging = false

func _physics_process(delta):
	direction = Input.get_vector("left", "right", "up", "down")
	if direction.length() > 0:
		last_movement_direction = direction
	if Input.is_action_just_pressed("dodge") and canDodge and direction:
		dodge()
	var target = direction * Stats.speed                                           
	walkingVelocity = lerp(Player.velocity, target, Stats.slideAmount * delta)     
	Player.velocity = walkingVelocity + dodgeVelocity + extraVelocity
	dodgeVelocity = lerp(dodgeVelocity, Vector2(0,0), 13 * delta)
	Player.move_and_slide()     

func dodge():
	dodgeVelocity = Vector2(direction.x, direction.y) * Stats.dashAmount
	dash_cooldown.start(Stats.dashCooldown)
	canDodge = false
	isDodging = true
	immunity_time.start(Stats.dashImmuneTime)

func _on_dash_cooldown_timeout() -> void:
	canDodge = true

func _on_immunity_time_timeout():
	isDodging = false
