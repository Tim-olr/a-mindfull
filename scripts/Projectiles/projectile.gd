extends CharacterBody2D
class_name Projectile

@onready var life_time: Timer = $LifeTime

# Ensure rot is a float so rotated(...) never receives Nil
var rot: float = 0.0
@export var damage: float
@export var lifetime: float
@export var projectileSpeed: float
@export var pierce: int
@onready var collision_area: Area2D = $CollisionArea
var shooter_group: String = ""
var knockback_force: float = 0.0

var shake

var targets_hit_times: Dictionary = {}

@export_enum("Constant", "Accelerate", "Decelerate") var speed_mode: int = 0
@export var end_speed_multiplier: float = 1.0

# NEW exports
@export var hasInfPierce: bool = false
@export var canKeepTicking: bool = false
@export var tick_interval: float = 0.1

# Runtime values
var _initial_speed: float = 0.0
var _elapsed: float = 0.0

func _ready() -> void:
	# Defensive: if an external script assigned rot before _ready it will keep that value.
	# If rot was never set, fall back to node rotation (or 0.0).
	if rot == null:
		rot = rotation if typeof(rotation) == TYPE_FLOAT or typeof(rotation) == TYPE_INT else 0.0

	_initial_speed = projectileSpeed
	_elapsed = 0.0
	if lifetime > 0.0:
		life_time.start(lifetime)
	collision_area.monitoring = true
	collision_area.monitorable = true

func _physics_process(delta: float):
	_elapsed += delta

	# update speed over time
	if speed_mode != 0 and lifetime > 0.0:
		var t = clamp(_elapsed / lifetime, 0.0, 1.0)
		projectileSpeed = _initial_speed * lerp(1.0, end_speed_multiplier, t)

	# Defensive: ensure rot is a number
	if rot == null:
		rot = rotation if typeof(rotation) == TYPE_FLOAT or typeof(rotation) == TYPE_INT else 0.0

	# move first so Area2D overlaps reflect new position
	velocity = Vector2(projectileSpeed, 0).rotated(rot)
	move_and_slide()

	# check overlaps each frame so canKeepTicking works while overlapping
	_check_overlaps()

func _check_overlaps() -> void:
	# compute which groups to ignore according to Option A:
	# Player bullets should NOT hit spirits; Spirit bullets should NOT hit players.
	var ignore_groups: Array = [shooter_group]
	if shooter_group == "player":
		ignore_groups.append("spirit")
	elif shooter_group == "spirit":
		ignore_groups.append("player")

	# collect current overlapping bodies and their ids
	var overlapping = collision_area.get_overlapping_bodies()
	var overlapping_ids: Dictionary = {}
	for body in overlapping:
		if body == null:
			continue

		# ignore the configured groups (shooter_group plus the counterpart)
		var should_ignore := false
		for g in ignore_groups:
			if body.is_in_group(g):
				should_ignore = true
				break
		if should_ignore:
			continue

		# if we hit a wall, destroy the projectile
		if body.is_in_group("wall"):
			go_away()
			return

		if body.is_in_group("enemy") or body.is_in_group("player"):
			var id = body.get_instance_id()
			overlapping_ids[id] = true

			if not canKeepTicking:
				# only hit once while overlapping (previous behavior)
				if not targets_hit_times.has(id):
					hit(body)
			else:
				# allow repeated hits but only if tick_interval has passed
				var last_hit_time: float = -9999.0
				if targets_hit_times.has(id):
					last_hit_time = targets_hit_times[id]
				if _elapsed - last_hit_time >= tick_interval:
					hit(body)

	# Remove entries for bodies no longer overlapping so they'll be hittable again on re-entry
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
	# compute contact point if needed (keeps your existing code)
	var my_shape = $CollisionArea/CollisionShape2D.shape
	var my_transform = $CollisionArea/CollisionShape2D.global_transform
	# some bodies might not have shape_owner_get_owner; protect with checks
	if hitBody.has_method("shape_owner_get_owner") and hitBody.has_method("shape_owner_get_shape"):
		var body_shape_owner = hitBody.shape_owner_get_owner(0)
		var body_shape = hitBody.shape_owner_get_shape(0, 0)
		var body_transform = body_shape_owner.global_transform
		var contacts = my_shape.collide_and_get_contacts(my_transform, body_shape, body_transform)
		if contacts.size() > 0:
			# spawn_pos = contacts[0]  # unused in current code but kept for compatibility
			pass

	do_damage(hitBody)
	apply_knockback_to_target(hitBody)

func do_damage(hitBody):
	var id = hitBody.get_instance_id()
	if hitBody.is_in_group("enemy"):
		if hitBody.has_method("damage"):
			hitBody.damage(damage)
		elif hitBody.get_parent().has_method("damage"):
			hitBody.get_parent().damage(damage)
		# record last hit time
		targets_hit_times[id] = _elapsed
		# decrement pierce unless infinite
		if not hasInfPierce:
			pierce -= 1
			if pierce <= 0:
				go_away()
	elif hitBody.is_in_group("player"):
		if hitBody.manager.has_method("damage"):
			hitBody.manager.damage(damage, get_parent().get_parent(), shake)
		elif hitBody.get_parent().manager.has_method("damage"):
			hitBody.get_parent().manager.damage(damage, get_parent().get_parent(), shake)
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

	# Defensive: ensure rot is valid
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
