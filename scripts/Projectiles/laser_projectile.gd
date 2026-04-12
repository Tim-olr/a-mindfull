extends Node2D
class_name LaserProjectile

@onready var life_time: Timer = $LifeTime

var rot: float = 0.0
var damage: float = 0.0
var lifetime: float = 0.0
var pierce: int = 1
var shooter_group: String = ""
var knockback_force: float = 0.0
var shake = 0.0
var txtr: Texture2D = null
var projectile_sprite_scene: PackedScene = null

var targets_hit_times: Dictionary = {}

var hasInfPierce: bool = false
var canKeepTicking: bool = false
var tick_interval: float = 0.1

var do_more_damage_to_enemies_with_hp_percent: bool = false
var enemy_health_percentage_min: int = 100
var damage_mult_for_dmdtewhp: float = 0.0

var _elapsed: float = 0.0

var laser_max_length: float = 400.0
var laser_width: float = 4.0
var canPhaseThroughWall: bool = false
var is_attached_to_shooter: bool = false
var laser_hold_while_held: bool = false
var attached_shooter: Node = null

var _laser_length: float = 0.0
var _laser_line: Line2D = null
var _laser_start: Marker2D = null
var _laser_end: Marker2D = null
var _sprite: AnimatedSprite2D = null

func _ready() -> void:
	if rot == null:
		rot = 0.0
	_elapsed = 0.0
	rotation = rot
	if laser_hold_while_held:
		life_time.stop()
	elif lifetime > 0.0:
		life_time.start(lifetime)
	_setup_visuals()

func _setup_visuals() -> void:
	_laser_start = Marker2D.new()
	_laser_end = Marker2D.new()
	add_child(_laser_start)
	add_child(_laser_end)
	_laser_start.position = Vector2.ZERO
	_laser_end.position = Vector2(laser_max_length, 0.0)

	if projectile_sprite_scene != null:
		_sprite = projectile_sprite_scene.instantiate()
		add_child(_sprite)
		_sprite.play("default")
	else:
		_laser_line = Line2D.new()
		_laser_line.width = laser_width
		_laser_line.default_color = Color.WHITE
		if txtr != null:
			_laser_line.texture = txtr
			_laser_line.texture_mode = Line2D.LINE_TEXTURE_TILE
		add_child(_laser_line)

	_update_line()

func _update_line() -> void:
	if _sprite != null:
		_sprite.position = Vector2(_laser_length / 2.0, 0.0)
		_sprite.scale.x = _laser_length / max(_sprite.sprite_frames.get_frame_texture("default", 0).get_width() if _sprite.sprite_frames else 1.0, 1.0)
		return
	if _laser_line == null or _laser_start == null or _laser_end == null:
		return
	_laser_line.clear_points()
	_laser_line.add_point(_laser_start.position)
	_laser_line.add_point(_laser_end.position)

func _physics_process(delta: float) -> void:
	_elapsed += delta
	if rot == null:
		rot = 0.0
	if laser_hold_while_held:
		var action = "attack" if shooter_group == "player" else "spirit_attack"
		if not Input.is_action_pressed(action):
			go_away()
			return
	_handle_laser_behavior()

func _handle_laser_behavior() -> void:
	if is_attached_to_shooter and attached_shooter and attached_shooter.is_inside_tree():
		global_position = attached_shooter.global_position
		if attached_shooter.is_in_group("player") or attached_shooter.is_in_group("spirit"):
			rot = (get_global_mouse_position() - global_position).angle()
		elif attached_shooter.is_in_group("enemy") and GlobalPlayer.player:
			rot = (GlobalPlayer.player.global_position - global_position).angle()
		rotation = rot

	var dir = Vector2(1, 0).rotated(rot)
	var max_len = laser_max_length
	var space_state = get_world_2d().direct_space_state

	if not canPhaseThroughWall:
		var exclude: Array = [self, get_parent()]
		var origin = global_position
		var remaining = max_len
		var iterations = 0
		while remaining > 0 and iterations < 12:
			var to_point = origin + dir * remaining
			var ray_params = PhysicsRayQueryParameters2D.new()
			ray_params.from = origin
			ray_params.to = to_point
			ray_params.exclude = exclude
			ray_params.collide_with_bodies = true
			ray_params.collide_with_areas = true
			var res = space_state.intersect_ray(ray_params)
			var collider = res.get("collider")
			if collider and collider.is_in_group("wall"):
				max_len = global_position.distance_to(res.position)
				break
			if collider:
				exclude.append(collider)
				origin = res.position + dir * 0.01
				remaining = max_len - global_position.distance_to(origin)
			else:
				break
			iterations += 1

	_laser_length = max_len

	if _laser_end != null:
		_laser_end.position = Vector2(_laser_length, 0.0)
	_update_line()

	var shape = RectangleShape2D.new()
	shape.extents = Vector2(_laser_length / 2.0, laser_width / 2.0)
	var center = global_position + dir * (_laser_length / 2.0)
	var transform = Transform2D(rot, center)
	var shape_params = PhysicsShapeQueryParameters2D.new()
	shape_params.shape = shape
	shape_params.transform = transform
	shape_params.exclude = [self, get_parent()]
	shape_params.collide_with_bodies = true
	shape_params.collide_with_areas = true
	var collisions = space_state.intersect_shape(shape_params, 32)
	var overlapping_ids: Dictionary = {}

	for col in collisions:
		var body = col.get("collider")
		if body == null:
			continue
		var should_process = false
		if shooter_group == "player" or shooter_group == "spirit":
			if body.is_in_group("enemy"):
				should_process = true
		elif shooter_group == "enemy":
			if body.is_in_group("player") or body.is_in_group("spirit"):
				should_process = true
		if not should_process:
			continue
		var id = body.get_instance_id()
		overlapping_ids[id] = true
		if not canKeepTicking:
			if not targets_hit_times.has(id):
				do_damage(body)
				apply_knockback_to_target(body)
		else:
			var last_hit_time: float = -9999.0
			if targets_hit_times.has(id):
				last_hit_time = targets_hit_times[id]
			if _elapsed - last_hit_time >= tick_interval:
				do_damage(body)
				apply_knockback_to_target(body)

	var to_remove: Array = []
	for key in targets_hit_times.keys():
		if not overlapping_ids.has(key):
			to_remove.append(key)
	for k in to_remove:
		targets_hit_times.erase(k)

func _on_life_time_timeout() -> void:
	queue_free()

func go_away() -> void:
	queue_free()

func do_damage(hitBody) -> void:
	var id = hitBody.get_instance_id()
	var total_damage = damage
	if do_more_damage_to_enemies_with_hp_percent:
		if hitBody.is_in_group("enemy"):
			var enemy_stats = hitBody.get("stats")
			if enemy_stats != null and enemy_stats.max_hp > 0:
				var hp_percent = (float(enemy_stats.hp) / float(enemy_stats.max_hp)) * 100.0
				if hp_percent >= enemy_health_percentage_min:
					total_damage *= damage_mult_for_dmdtewhp
	if hitBody.is_in_group("enemy") or hitBody.is_in_group("spirit"):
		if hitBody.has_method("damage"):
			hitBody.damage(total_damage, get_parent().get_parent(), shake)
		elif hitBody.get_parent().has_method("damage"):
			hitBody.get_parent().damage(total_damage, get_parent(), 0)
		targets_hit_times[id] = _elapsed
		if not hasInfPierce:
			pierce -= 1
			if pierce <= 0:
				go_away()
	elif hitBody.is_in_group("player"):
		if hitBody.manager.has_method("damage"):
			hitBody.manager.damage(total_damage, get_parent().get_parent(), shake)
		elif hitBody.get_parent().manager.has_method("damage"):
			hitBody.get_parent().manager.damage(total_damage, get_parent().get_parent(), shake)
		targets_hit_times[id] = _elapsed
		if not hasInfPierce:
			pierce -= 1
			if pierce <= 0:
				go_away()

func apply_knockback_to_target(hitBody) -> void:
	if knockback_force <= 0:
		return
	var knockback_direction = Vector2(1, 0).rotated(rot)
	if hitBody.is_in_group("enemy"):
		if hitBody.has_method("apply_knockback"):
			hitBody.apply_knockback(knockback_direction, knockback_force)
		elif hitBody.get_parent().has_method("apply_knockback"):
			hitBody.get_parent().apply_knockback(knockback_direction, knockback_force)
	elif hitBody.is_in_group("player"):
		if hitBody.manager.has_method("apply_knockback"):
			hitBody.manager.apply_knockback(knockback_direction, knockback_force)
		elif hitBody.get_parent().manager.has_method("apply_knockback"):
			hitBody.get_parent().manager.apply_knockback(knockback_direction, knockback_force)
