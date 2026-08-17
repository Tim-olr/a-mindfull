extends CharacterBody2D
class_name Projectile

@onready var life_time: Timer = $LifeTime

var rot: float = 0.0
@export var damage: float
@export var lifetime: float
@export var projectileSpeed: float
@export var pierce: int
@export var collision_area: Area2D
@export var area_shape: CollisionShape2D
var shooter_group: String = ""
var knockback_force: float = 0.0
var projectile_sprite_scene: PackedScene = null
var has_no_rot: bool = false
@onready var proj_middle: Marker2D = $ProjMiddle

var is_boomerang: bool = false
var shooter: Node2D = null

@export var local_proj: AnimatedSprite2D

@export var txtr: Texture2D

var shake
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
var _sprite: AnimatedSprite2D = null

func _ready() -> void:
	if rot == null:
		rot = rotation if typeof(rotation) == TYPE_FLOAT or typeof(rotation) == TYPE_INT else 0.0
	_initial_speed = projectileSpeed
	_elapsed = 0.0
	if lifetime > 0.0:
		life_time.start(lifetime)
	collision_area.monitoring = true
	collision_area.monitorable = true
	if projectile_sprite_scene != null:
		_sprite = projectile_sprite_scene.instantiate()
		add_child(_sprite)
		_sprite.play("default")
		local_proj.hide()
	elif projectile_sprite_scene == null: local_proj.show()
	if has_no_rot:
		rotation = 0.0

func _physics_process(delta: float):
	_elapsed += delta
	if is_boomerang and is_instance_valid(shooter):
		var t = clamp(_elapsed / lifetime, 0.0, 1.0)
		rotation += delta * 15.0
		if t < 0.5:
			projectileSpeed = lerp(_initial_speed, 0.0, t * 2.0)
			velocity = Vector2(projectileSpeed, 0).rotated(rot)
		else:
			var dir = (shooter.global_position - global_position).normalized()
			var return_speed = _initial_speed * lerp(0.0, 1.5, (t - 0.5) * 2.0)
			velocity = dir * return_speed
			rot = dir.angle()
			if global_position.distance_to(shooter.global_position) < 20.0:
				go_away()
				return
	else:
		if speed_mode != 0 and lifetime > 0.0:
			var t = clamp(_elapsed / lifetime, 0.0, 1.0)
			projectileSpeed = _initial_speed * lerp(1.0, end_speed_multiplier, t)
		velocity = Vector2(projectileSpeed, 0).rotated(rot)
	move_and_slide()
	if has_no_rot:
		rotation = 0.0
	_check_overlaps()

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
		if body.is_in_group("destructible"):
			if body.has_method("damage"):
				body.damage(damage)
			go_away()
			return
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
