extends CharacterBody2D
class_name Projectile

@onready var life_time: Timer = $LifeTime

var rot: float = 0.0
@export var damage: float
@export var lifetime: float
@export var projectileSpeed: float
@export var pierce: int
@onready var collision_area: Area2D = $CollisionArea
@onready var area_shape: CollisionShape2D = $CollisionArea/AreaShape
var shooter_group: String = ""
var knockback_force: float = 0.0
@onready var projectile_sprite: Button = $CollisionArea/AreaShape/ProjectileSprite
@onready var proj_middle: Marker2D = $ProjMiddle

@export var txtr: Texture2D

var shake
var projectile_sprite_size:= Vector2(0, 0)

var targets_hit_times: Dictionary = {}

@export_enum("Constant", "Accelerate", "Decelerate") var speed_mode: int = 0
@export var end_speed_multiplier: float = 1.0

@export var hasInfPierce: bool = false
@export var canKeepTicking: bool = false
@export var tick_interval: float = 0.1

var do_more_damage_to_enemies_with_hp_percent: bool = false
var enemy_health_percentage_min: int = 100
var damage_mult_for_dmdtewhp: float = 0.0

var _initial_speed: float = 0.0
var _elapsed: float = 0.0

var is_laser: bool = false
var laser_max_length: float = 400.0
var laser_width: float = 4.0
var canPhaseThroughWall: bool = false

var is_attached_to_shooter: bool = false
var attached_shooter: Node = null

var _laser_length: float = 0.0

func _ready() -> void:
	if rot == null:
		rot = rotation if typeof(rotation) == TYPE_FLOAT or typeof(rotation) == TYPE_INT else 0.0
	_initial_speed = projectileSpeed
	_elapsed = 0.0
	if lifetime > 0.0:
		life_time.start(lifetime)
	collision_area.monitoring = true
	collision_area.monitorable = true
	if is_laser:
		if shooter_group == "player":
			projectile_sprite.global_position = proj_middle.global_position
		elif shooter_group == "spirit":
			projectile_sprite.global_position = collision_area.global_position

func _physics_process(delta: float):
	_elapsed += delta
	if speed_mode != 0 and lifetime > 0.0:
		var t = clamp(_elapsed / lifetime, 0.0, 1.0)
		projectileSpeed = _initial_speed * lerp(1.0, end_speed_multiplier, t)
	if rot == null:
		rot = rotation if typeof(rotation) == TYPE_FLOAT or typeof(rotation) == TYPE_INT else 0.0
	if is_laser:
		_handle_laser_behavior()
		projectile_sprite.size = projectile_sprite_size
	else:
		velocity = Vector2(projectileSpeed, 0).rotated(rot)
		move_and_slide()
		_check_overlaps()

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

func _check_overlaps() -> void:
	var ignore_groups: Array = [shooter_group]
	if shooter_group == "player":
		ignore_groups.append("spirit")
	elif shooter_group == "spirit":
		ignore_groups.append("player")
	var overlapping = collision_area.get_overlapping_bodies()
	var overlapping_ids: Dictionary = {}
	for body in overlapping:
		if body == null:
			continue
		var should_ignore := false
		for g in ignore_groups:
			if body.is_in_group(g):
				should_ignore = true
				break
		if should_ignore:
			continue
		if body.is_in_group("wall"):
			go_away()
			return
		if body.is_in_group("enemy") or body.is_in_group("player") or body.is_in_group("spirit"):
			var id = body.get_instance_id()
			overlapping_ids[id] = true
			if not canKeepTicking:
				if not targets_hit_times.has(id):
					hit(body)
			else:
				var last_hit_time: float = -9999.0
				if targets_hit_times.has(id):
					last_hit_time = targets_hit_times[id]
				if _elapsed - last_hit_time >= tick_interval:
					hit(body)
	var to_remove: Array = []
	for key in targets_hit_times.keys():
		if not overlapping_ids.has(key):
			to_remove.append(key)
	for k in to_remove:
		targets_hit_times.erase(k)

func _on_life_time_timeout() -> void:
	queue_free()

func go_away():
	queue_free()

func hit(hitBody):
	var my_shape = area_shape.shape
	var my_transform = $CollisionArea/AreaShape.global_transform
	if hitBody.has_method("shape_owner_get_owner") and hitBody.has_method("shape_owner_get_shape"):
		var body_shape_owner = hitBody.shape_owner_get_owner(0)
		var body_shape = hitBody.shape_owner_get_shape(0, 0)
		var body_transform = body_shape_owner.global_transform
		var contacts = my_shape.collide_and_get_contacts(my_transform, body_shape, body_transform)
		if contacts.size() > 0:
			pass
	do_damage(hitBody)
	apply_knockback_to_target(hitBody)

func do_damage(hitBody):
	var id = hitBody.get_instance_id()
	var total_damage = damage
	if do_more_damage_to_enemies_with_hp_percent:
		var enemy_stats = hitBody.get("stats")
		if enemy_stats != null and enemy_stats.max_hp > 0:
			var hp_percent = (float(enemy_stats.hp) / float(enemy_stats.max_hp)) * 100.0
			print("h: ", hp_percent)
			if hp_percent >= enemy_health_percentage_min:
				print("Yeehaw")
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

func apply_knback_direction(rot_angle: float) -> Vector2:
	return Vector2(1, 0).rotated(rot_angle)

func apply_knockback_to_target(hitBody):
	if knockback_force <= 0:
		return
	if rot == null:
		rot = rotation if typeof(rotation) == TYPE_FLOAT or typeof(rotation) == TYPE_INT else 0.0
	var knockback_direction = apply_knback_direction(rot)
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
