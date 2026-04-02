extends Node2D
class_name PlayerMovement

@onready var Player = $".."
@onready var Stats: Node2D = $"../PlayerStats"
@onready var dash_cooldown: Timer = $DashCooldown
@onready var immunity_time: Timer = $ImmunityTime
@onready var player_sprites: AnimatedSprite2D = $"../PlayerVisuals/PlayerSprites"
@onready var climb_timer: Timer = $ClimbTimer

var direction = Vector2.ZERO
var last_movement_direction = Vector2.DOWN
var walkingVelocity = Vector2.ZERO
var dodgeVelocity = Vector2.ZERO
var extraVelocity = Vector2.ZERO
var knockbackVelocity = Vector2.ZERO
var canDodge = true
var isDodging = false
var isDodgingAnim = false
var movement_enabled = true
var is_priority_animation = false
var priority_animation_name = ""
var _priority_token: int = 0
var _dodge_token: int = 0

const COLLISION_BIT_WALKABLE := 1
const COLLISION_BIT_WALL := 8

@export var push_force: float = 200.0

func _ready() -> void:
	Player.collision_mask = COLLISION_BIT_WALKABLE | COLLISION_BIT_WALL

func _physics_process(delta):
	if not movement_enabled:
		return
	direction = Input.get_vector("left", "right", "up", "down")
	if direction.length() > 0:
		last_movement_direction = direction
	if Input.is_action_just_pressed("dodge") and canDodge and direction:
		dodge()
	var target = direction * Stats.speed
	walkingVelocity = lerp(Player.velocity, target, Stats.slideAmount * delta)
	Player.velocity = walkingVelocity + dodgeVelocity + extraVelocity + knockbackVelocity
	knockbackVelocity = lerp(knockbackVelocity, Vector2.ZERO, 10 * delta)
	dodgeVelocity = lerp(dodgeVelocity, Vector2.ZERO, 13 * delta)
	handle_animations()
	Player.move_and_slide()
	_handle_physics_pushes()

func add_knockback(knockback: Vector2):
	knockbackVelocity += knockback

func dodge():
	dodgeVelocity = Vector2(direction.x, direction.y) * Stats.dashAmount
	dash_cooldown.start(Stats.dashCooldown)
	canDodge = false
	isDodging = true
	isDodgingAnim = true
	immunity_time.start(Stats.dashImmuneTime)
	player_sprites.flip_h = false
	if direction.x < 0:
		player_sprites.flip_h = true
	elif direction.x > 0:
		player_sprites.flip_h = false
	_dodge_token += 1
	var token = _dodge_token
	call_deferred("_deferred_wait_for_dodge", token)

func _deferred_wait_for_dodge(token: int) -> void:
	await player_sprites.animation_finished
	if token == _dodge_token:
		isDodgingAnim = false

func _on_dash_cooldown_timeout() -> void:
	canDodge = true

func _on_immunity_time_timeout():
	isDodging = false

func play_priority_animation(anim_name: String, block_movement: bool):
	is_priority_animation = true
	priority_animation_name = anim_name
	if block_movement:
		movement_enabled = false
	_priority_token += 1
	var token = _priority_token
	player_sprites.play(anim_name)
	call_deferred("_deferred_wait_for_priority_animation", anim_name, token)

func _deferred_wait_for_priority_animation(anim_name: String, token: int) -> void:
	await player_sprites.animation_finished
	if token == _priority_token:
		is_priority_animation = false
		priority_animation_name = ""
		movement_enabled = true

func wait_for_animation(anim_name: String):
	while player_sprites.animation != anim_name:
		await get_tree().process_frame
	while player_sprites.is_playing():
		await get_tree().process_frame
	is_priority_animation = false
	priority_animation_name = ""
	movement_enabled = true

func handle_animations():
	if is_priority_animation:
		return

	if direction == Vector2.ZERO:
		match last_movement_direction:
			Vector2.UP:
				player_sprites.flip_h = false
				player_sprites.play("idle_up")
			Vector2.DOWN:
				player_sprites.flip_h = false
				player_sprites.play("idle_down")
			Vector2.LEFT:
				player_sprites.flip_h = true
				player_sprites.play("idle_down")
			Vector2.RIGHT:
				player_sprites.flip_h = false
				player_sprites.play("idle_down")
		return

	if abs(direction.x) >= abs(direction.y):
		if direction.x > 0:
			player_sprites.flip_h = false
			if player_sprites.animation != "walk_right":
				player_sprites.play("walk_right")
		else:
			player_sprites.flip_h = true
			if player_sprites.animation != "walk_right":
				player_sprites.play("walk_right")
	else:
		if direction.y < 0:
			player_sprites.flip_h = false
			if player_sprites.animation != "walk_up":
				player_sprites.play("walk_up")
		else:
			player_sprites.flip_h = false
			if player_sprites.animation != "walk_down":
				player_sprites.play("walk_down")

func _handle_physics_pushes() -> void:
	for i in Player.get_slide_collision_count():
		var collision = Player.get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is PhysicsObject and collider.pushable:
			collider.apply_central_impulse(-collision.get_normal() * push_force)
