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
@export var knockback_resistance: float = 0.0
@export var can_drop_shards := true
@export var shard_amount := 0.0
@export var pushback_distance: float = 38.0

@export var avoidance_ray_count: int    = 7
@export var avoidance_ray_length: float = 52.0
@export var avoidance_force: float      = 180.0
@export var weight: float = 0.05

var knockbackVelocity := Vector2.ZERO
var knockback_decay: float = 10.0
var pushback_vel: Array[Vector2] = []
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
	if weapon != null:
		var wep = weapon.instantiate()
		add_child(wep)
	add_to_group("enemy")
	stats.speed *= FahrerDeck.enemy_speed_mult()

func _process(_delta: float) -> void:
	if stats.hp <= 0 and !died:
		area.set_deferred("monitorable", false)
		area.set_deferred("monitoring", false)
		die()
	direction = velocity
	if direction == Vector2.ZERO:
		return

func _physics_process(delta: float) -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == self or not is_instance_valid(enemy):
			continue
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance <= pushback_distance:
			var dir: Vector2 = enemy.global_position - global_position
			dir = dir.normalized()
			var force: Vector2 = -dir * (2.0 / (distance + 0.1))
			pushback_vel.append(force)

	knockbackVelocity = lerp(knockbackVelocity, Vector2.ZERO, weight)

	if !attacking and canWalk and is_instance_valid(GlobalPlayer.player):
		var desired := _compute_steering()
		velocity = desired + knockbackVelocity
	elif knockbackVelocity.length() > 0:
		velocity = knockbackVelocity

	for pushback in pushback_vel:
		velocity += pushback
	move_and_slide()
	pushback_vel.clear()

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

func _on_navigation_agent_2d_velocity_computed(_safe_velocity: Vector2) -> void:
	pass

func damage(damageAmount, _dmgr, _camShake):
	var newDmg = damageAmount
	stats.hp -= newDmg
	health_bar.set_health(stats.hp)
	damaged()
	GlobalhitMarker.show_hit_marker(newDmg, self, false)

func die():
	canWalk = false
	died = true
	give_shards()
	queue_free()

func give_shards(amount := 0.0):
	if !can_drop_shards:
		return
	GlobalPlayer.stats.add_shards(amount if amount != 0.0 else shard_amount)

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
