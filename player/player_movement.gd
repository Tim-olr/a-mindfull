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

## Ghostly afterimage trail: a bright expanding flash at the moment of the
## dash, followed by a string of translucent player-silhouette afterimages
## left behind along the dash path, each fading and shrinking away.
func _deferred_dash_trail(token: int) -> void:
	_spawn_ghost(1.0, 2.4, 0.85, 0.0, 0.18, Color(0.75, 0.95, 1.0))
	var ghost_count := 5
	for i in range(ghost_count):
		await get_tree().create_timer(0.035).timeout
		if token != _dodge_token:
			return
		_spawn_ghost(1.0, 0.75, 0.5, 0.0, 0.3, Color(0.5, 0.6, 1.0))

func _spawn_ghost(scale_from: float, scale_to: float, alpha_from: float, alpha_to: float, duration: float, tint: Color) -> void:
	var frames := player_sprites.sprite_frames
	if frames == null or not frames.has_animation(player_sprites.animation):
		return
	var tex := frames.get_frame_texture(player_sprites.animation, player_sprites.frame)
	if tex == null:
		return
	var parent := Player.get_parent()
	if parent == null:
		return
	var base_scale: Vector2 = player_sprites.get_global_transform().get_scale()
	var ghost := Sprite2D.new()
	ghost.texture = tex
	ghost.flip_h = player_sprites.flip_h
	ghost.global_position = player_sprites.global_position
	ghost.global_rotation = player_sprites.global_rotation
	ghost.scale = base_scale * scale_from
	ghost.z_index = Player.z_index - 1
	ghost.modulate = Color(tint.r, tint.g, tint.b, alpha_from)
	parent.add_child(ghost)
	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", alpha_to, duration)
	tween.tween_property(ghost, "scale", base_scale * scale_to, duration)
	tween.chain().tween_callback(ghost.queue_free)

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
