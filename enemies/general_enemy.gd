extends CharacterBody2D
class_name Enemy

@export var Name: String
@export var texture: Texture2D
@export var area: Area2D
@onready var timer: Timer = $Timer
@export var base: Sprite2D
@export var weapon: PackedScene
@onready var death_anim_timer: Timer = $death_anim_timer
@onready var stats: Node2D = $EnemyStats
@onready var attack_speed: Timer = $attack_speed
@onready var health_bar: ProgressBar = $"UI enemy/HealthBar"
@onready var body_collision: CollisionShape2D = $enemycollision
@export var knockback_resistance: float = 0.0
@export var pushback_strength: float = 60.0
@export var separation_padding: float = 4.0

@export var avoidance_ray_count: int    = 7
@export var avoidance_ray_length: float = 52.0
@export var avoidance_force: float      = 180.0
@export var weight: float = 0.05

@export var deals_contact_damage: bool = true
@export var contact_damage_interval: float = 1.0

## When true, this enemy only opens fire once the player is within `los`
## units AND nothing on the wall/obstacle layers is blocking the line
## between them. When false, the enemy fires purely off cooldown ("randomly")
## regardless of obstacles or distance.
@export var has_los: bool = false
@export var los: float = 400.0

var _contact_bodies: Array = []

var knockbackVelocity := Vector2.ZERO
var knockback_decay: float = 10.0
var canWalk := true
var isMelee: bool = false
var died := false
var attacking := false
var direction: Vector2

func _ready() -> void:
	base.texture = texture
	await get_tree().physics_frame
	stats.max_hp = stats.hp
	health_bar.init_health(stats.hp)
	stats.canAttack = false
	_delay_first_attack()
	if weapon != null:
		var wep = weapon.instantiate()
		add_child(wep)
	add_to_group("enemy")
	if deals_contact_damage:
		area.body_entered.connect(_on_contact_area_body_entered)
		area.body_exited.connect(_on_contact_area_body_exited)
		var contact_timer := Timer.new()
		contact_timer.wait_time = maxf(0.1, contact_damage_interval)
		contact_timer.one_shot = false
		add_child(contact_timer)
		contact_timer.timeout.connect(_deal_contact_damage)
		contact_timer.start()

func _process(_delta: float) -> void:
	if stats.hp <= 0 and !died:
		area.set_deferred("monitorable", false)
		area.set_deferred("monitoring", false)
		die()
	direction = velocity
	if direction == Vector2.ZERO:
		return

func _physics_process(delta: float) -> void:
	var separation := _compute_separation()

	knockbackVelocity = lerp(knockbackVelocity, Vector2.ZERO, weight)

	if !attacking and canWalk and is_instance_valid(GlobalPlayer.player):
		var desired := _compute_steering()
		velocity = desired + knockbackVelocity
	else:
		velocity = knockbackVelocity

	velocity += separation
	move_and_slide()

## Radius of this enemy's actual physical footprint (its "enemycollision"
## shape, in global scale), used so the push radius always matches how big
## the enemy really is instead of a single flat distance shared by everyone.
func get_separation_radius() -> float:
	if body_collision == null or body_collision.shape == null:
		return 16.0
	var shape := body_collision.shape
	var local_radius: float
	if shape is CircleShape2D:
		local_radius = shape.radius
	elif shape is RectangleShape2D:
		local_radius = (shape.size.x + shape.size.y) / 4.0
	elif shape is CapsuleShape2D:
		local_radius = max(shape.radius, shape.height / 2.0)
	else:
		local_radius = 16.0
	return local_radius * body_collision.global_scale.x

## Isaac-style separation: enemies overlapping each other's personal space get
## nudged apart proportional to how much they overlap, capped at
## pushback_strength so a pile-up can't spike into a huge shove. The personal
## space itself is the sum of both enemies' actual collision radii (plus a
## small padding), not a flat distance, so small enemies don't get shoved
## apart from empty air the way they did before. A stack of exactly-overlapping
## enemies still gets pushed (in a random direction) instead of getting stuck
## with a zero-length push vector.
func _compute_separation() -> Vector2:
	var separation := Vector2.ZERO
	var my_radius := get_separation_radius()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == self or not is_instance_valid(enemy) or not (enemy is Enemy):
			continue
		var offset: Vector2 = global_position - enemy.global_position
		var distance: float = offset.length()
		var min_distance: float = my_radius + enemy.get_separation_radius() + separation_padding
		if distance >= min_distance:
			continue
		var away := offset / distance if distance > 0.01 else Vector2.RIGHT.rotated(randf() * TAU)
		var overlap := (min_distance - distance) / min_distance
		separation += away * overlap * pushback_strength
	return separation

func _compute_steering() -> Vector2:
	var to_player := GlobalPlayer.player.global_position - global_position
	var dist      := to_player.length()

	var pursuit := Vector2.ZERO
	if dist > 1.0:
		pursuit = to_player.normalized() * stats.speed

	var avoidance := _get_avoidance()
	var blended   := pursuit + avoidance

	if blended.length() > stats.speed:
		blended = blended.normalized() * stats.speed

	return blended

func _get_avoidance() -> Vector2:
	var space  := get_world_2d().direct_space_state
	var avoid  := Vector2.ZERO
	var spread := PI

	for i in avoidance_ray_count:
		var t       := float(i) / float(avoidance_ray_count - 1)
		var angle   := (t - 0.5) * spread
		var to_player_angle := (GlobalPlayer.player.global_position - global_position).angle()
		var ray_dir := Vector2.RIGHT.rotated(to_player_angle + angle)

		var query := PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + ray_dir * avoidance_ray_length
		)
		query.exclude    = [self]
		query.collision_mask = 1

		var result := space.intersect_ray(query)
		if result:
			var hit_normal: Vector2 = result.normal
			var closeness: float   = 1.0 - (result.position.distance_to(global_position) / avoidance_ray_length)
			avoid += hit_normal * closeness * avoidance_force

	return avoid

## Keeps enemies from opening fire the instant the player enters their room.
## Uses a real Timer node (not get_tree().create_timer()) because rooms sit at
## PROCESS_MODE_DISABLED until the player enters them, and a Timer node
## honors that — it only starts counting down once the room (and this enemy)
## actually becomes active. A SceneTreeTimer would ignore process_mode
## entirely and keep counting down in the background while the room is still
## disabled, so it would always be long expired by the time the player walked
## in, making the delay pointless.
func _delay_first_attack() -> void:
	var delay_timer := Timer.new()
	delay_timer.one_shot = true
	delay_timer.wait_time = maxf(stats.attackSpeed, 1.0)
	add_child(delay_timer)
	delay_timer.start()
	await delay_timer.timeout
	if is_instance_valid(self) and not died:
		stats.canAttack = true
	delay_timer.queue_free()

## Used by Weapon to gate enemy attacks. See has_los/los above.
func can_attack_player() -> bool:
	if not has_los:
		return true
	if not is_instance_valid(GlobalPlayer.player):
		return false
	var to_player := GlobalPlayer.player.global_position - global_position
	if to_player.length() > los:
		return false
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, GlobalPlayer.player.global_position)
	query.exclude = [self]
	query.collision_mask = 1 | 4
	var result := space.intersect_ray(query)
	return result.is_empty()

func _on_navigation_agent_2d_velocity_computed(_safe_velocity: Vector2) -> void:
	pass

func _on_contact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _contact_bodies.has(body):
		_contact_bodies.append(body)
		_apply_contact_damage(body)

func _on_contact_area_body_exited(body: Node2D) -> void:
	_contact_bodies.erase(body)

func _deal_contact_damage() -> void:
	for body in _contact_bodies:
		_apply_contact_damage(body)

func _apply_contact_damage(body: Node2D) -> void:
	if died or not is_instance_valid(body):
		return
	if body.manager != null and body.manager.has_method("damage"):
		body.manager.damage(stats.attackDamage, self, 0)

func damage(damageAmount, _dmgr, _camShake):
	var newDmg = damageAmount
	stats.hp -= newDmg
	health_bar.set_health(stats.hp)
	damaged()
	GlobalhitMarker.show_hit_marker(newDmg, self, false)

func die():
	canWalk = false
	died = true
	Currency.add(stats.shard_reward)
	queue_free()

func attack(_b):
	pass

func attackCooldownActivator():
	timer.start(stats.attackCooldown)

func _on_timer_timeout() -> void:
	attacking = false

func _on_attack_speed_timeout() -> void:
	attacking = false

func _on_death_anim_timer_timeout() -> void:
	queue_free()

func damaged():
	var tween = create_tween()
	tween.tween_property(base, "modulate", Color.RED, 0.1)
	tween.tween_property(base, "modulate", Color.WHITE, 0.1)

func apply_knockback(direction_vec: Vector2, force: float):
	var effective_force = force * (1.0 - clamp(knockback_resistance, 0.0, 1.0))
	knockbackVelocity = direction_vec.normalized() * effective_force
