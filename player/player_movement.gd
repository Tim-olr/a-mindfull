extends Node2D
class_name PlayerMovement

const DashSmokeParticles: PackedScene = preload("res://player/dash_smoke_particles.tscn")

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

func _ready() -> void:
	Player.collision_mask = COLLISION_BIT_WALKABLE | COLLISION_BIT_WALL

func _physics_process(delta):
	if not movement_enabled:
		direction = Vector2.ZERO
		handle_animations()
		return
	direction = Input.get_vector("left", "right", "up", "down")
	if direction.length() > 0:
		last_movement_direction = direction
	if Input.is_action_just_pressed("dodge") and canDodge and direction:
		dodge()
	var target = direction * Stats.speed * ArtifactManager.adrenal_speed_mult()
	walkingVelocity = lerp(Player.velocity, target, Stats.slideAmount * delta)
	Player.velocity = walkingVelocity + dodgeVelocity + extraVelocity + knockbackVelocity
	knockbackVelocity = lerp(knockbackVelocity, Vector2.ZERO, 10 * delta)
	dodgeVelocity = lerp(dodgeVelocity, Vector2.ZERO, 13 * delta)
	handle_animations()
	Player.move_and_slide()

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
	call_deferred("_deferred_dash_trail", token)

func _deferred_wait_for_dodge(token: int) -> void:
	await player_sprites.animation_finished
	if token == _dodge_token:
		isDodgingAnim = false

## Dash afterimage trail: every frame of the walk animation that's currently
## playing gets spawned in white, shortly after one another, along the dash
## path. Each frame is given less time to fade than the last (duration =
## total trail lifetime minus how late it spawned) so despite spawning
## staggered, they all hit zero alpha and disappear at the same moment,
## instead of fading out one by one. A smoke puff also kicks up from the
## spot the dash started.
func _deferred_dash_trail(token: int) -> void:
	_spawn_dash_smoke(player_sprites.global_position)

	var anim_name := String(player_sprites.animation)
	var frames := player_sprites.sprite_frames
	if frames == null or not frames.has_animation(anim_name):
		return
	var frame_count := frames.get_frame_count(anim_name)
	if frame_count <= 0:
		return

	var flip := player_sprites.flip_h
	var stagger := 0.045
	var trail_lifetime := 0.3
	for i in range(frame_count):
		if i > 0:
			await get_tree().create_timer(stagger).timeout
			if token != _dodge_token:
				return
		var remaining: float = maxf(trail_lifetime - stagger * i, 0.06)
		_spawn_walk_frame_ghost(frames.get_frame_texture(anim_name, i), flip, remaining)

func _spawn_walk_frame_ghost(tex: Texture2D, flip: bool, duration: float) -> void:
	if tex == null:
		return
	var parent := Player.get_parent()
	if parent == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = tex
	ghost.flip_h = flip
	ghost.global_position = player_sprites.global_position
	ghost.global_rotation = player_sprites.global_rotation
	ghost.scale = player_sprites.get_global_transform().get_scale()
	ghost.z_index = Player.z_index - 1
	ghost.modulate = Color(1.0, 1.0, 1.0, 0.85)
	parent.add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, duration)
	tween.tween_callback(ghost.queue_free)

func _spawn_dash_smoke(pos: Vector2) -> void:
	var parent := Player.get_parent()
	if parent == null:
		return
	var smoke := DashSmokeParticles.instantiate()
	smoke.global_position = pos
	smoke.z_index = Player.z_index - 1
	parent.add_child(smoke)

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
