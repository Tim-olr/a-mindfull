extends Node2D
class_name Weapon

@export_group("Base Stats")
@export var pierceMod: int = 0
@export var damageMod: float
@export var bulletLifeTimeMod: float
@export var bulletAmountMod: int
@export var rotationAdditionMod: float
@export var projectileSpeedMod: float
@export var bulletSizeMod: Vector2
@export var shootCooldown: float
@export var gun: bool
@export var melee: bool
@export var description: String
@export var Name: String
@export var rarity: String
@export var bulletScene: PackedScene
@export var doConsecShooting := false
@export var cameraShakeAmount: float
@export var knockback_force: float = 500.0

@export_category("other")
@export var do_more_damage_to_enemies_with_hp_percent: bool = false
@export var enemy_health_percentage_min: int = 100
@export var damage_mult_for_dmdtewhp: float = 0.0

@export var hasInfPierce: bool = false
@export var canKeepTicking: bool = false
@export var tick_interval: float = 0.1

@export var doRandomRotAndPos: bool = false
@export var pos_scatter_radius: float = 0.0

@export_group("Projectile Speed Over Time")
@export_enum("Constant", "Accelerate", "Decelerate") var bullet_speed_mode: int = 0
@export var bullet_end_speed_multiplier: float = 1.0

@export_category("Laser Settings")
@export var is_laser: bool = false
@export var laser_max_length: float = 400.0
@export var laser_width: float = 4.0
@export var canPhaseThroughWall: bool = false
@export var laser_attach_to_shooter: bool = false
@export var laser_hold_while_held: bool = false

@export_group("Melee Settings")
@export var is_swing: bool = false
@export var is_stab: bool = false
@export var swing_arc: float = 90.0
@export var stab_distance: float = 20.0
@export var attack_duration: float = 0.2

var shooter: Node2D
var targets_hit: Array[Node] = []
var melee_active: bool = false
var detection_area: Area2D
var isSelected: bool = false

@onready var attack_cooldown: Timer = $attack_cooldown
@onready var bullet_stars_pos = $BulletStarsPos
@onready var melee_hitbox: Area2D = $BulletStarsPos/MeleeHitbox

var original_bullet_pos: Vector2
var original_bullet_rot: float

var resource

func _ready():
	shooter = get_parent()
	melee_hitbox.body_entered.connect(_on_melee_hitbox_entered)
	melee_hitbox.area_entered.connect(_on_melee_hitbox_entered)
	original_bullet_pos = bullet_stars_pos.position
	original_bullet_rot = bullet_stars_pos.rotation
	if shooter.is_in_group("enemy") and melee:
		detection_area = shooter.get_node_or_null("playerMeleeDetectionArea")

func _process(_delta: float) -> void:
	if isSelected:
		if shooter.is_in_group("player"):
			if !is_laser:
				global_position = shooter.global_position
				bullet_stars_pos = GlobalPlayer.manager.weapon_marker
				bullet_stars_pos.look_at(get_global_mouse_position())
			else:
				global_position = shooter.global_position
				bullet_stars_pos.look_at(-get_global_mouse_position())
			if Input.is_action_pressed("attack") and shooter.stats.canAttack:
				perform_attack()
	elif shooter.is_in_group("spirit"):
		if melee:
			global_position = shooter.global_position
			bullet_stars_pos.look_at(get_global_mouse_position())
		else:
			bullet_stars_pos = shooter.bullet_start_pos
			global_position = shooter.global_position
			bullet_stars_pos.look_at(get_global_mouse_position())
		if Input.is_action_pressed("spirit_attack") and shooter.out and shooter.canAttack:
			perform_attack()
	elif shooter.is_in_group("enemy"):
		if GlobalPlayer.player:
			bullet_stars_pos.look_at(GlobalPlayer.player.global_position)
			if gun:
				var dist = global_position.distance_to(GlobalPlayer.player.global_position)
				if shooter.stats.canAttack and dist < 1000:
					perform_attack()
			elif melee and detection_area:
				if shooter.stats.canAttack:
					for body in detection_area.get_overlapping_bodies():
						if body.is_in_group("player"):
							perform_attack()
							break

func _get_shooter_attack_speed() -> float:
	var val = shooter.get("attackSpeed")
	if typeof(val) == TYPE_FLOAT or typeof(val) == TYPE_INT:
		return float(val)
	var stats = shooter.get("stats")
	if stats != null:
		var s_val = stats.get("attackSpeed")
		if typeof(s_val) == TYPE_FLOAT or typeof(s_val) == TYPE_INT:
			return float(s_val)
	return 0.5

func perform_attack():
	if shooter.is_in_group("spirit"):
		shooter.canAttack = false
		attack_cooldown.set_wait_time(_get_shooter_attack_speed() + shootCooldown)
		attack_cooldown.start()
	else:
		shooter.stats.canAttack = false
		attack_cooldown.set_wait_time(shooter.stats.attackSpeed + shootCooldown)
		attack_cooldown.start()
	if gun:
		shoot()
	elif melee:
		var total_attacks
		if shooter.is_in_group("spirit"):
			total_attacks = shooter.bulletAmountMod + bulletAmountMod
		else:
			total_attacks = shooter.stats.bulletAmount + bulletAmountMod
		for i in range(total_attacks):
			await do_melee_animation()
			if i < total_attacks - 1:
				var wait_time = 0.1 if doConsecShooting else attack_duration
				await get_tree().create_timer(wait_time).timeout

func do_melee_animation():
	targets_hit.clear()
	melee_active = true
	if melee_hitbox:
		for body in melee_hitbox.get_overlapping_bodies():
			_on_melee_hitbox_entered(body)
		for area in melee_hitbox.get_overlapping_areas():
			_on_melee_hitbox_entered(area)
	var tween = create_tween()
	var current_rot = 0
	var current_pos = Vector2.ZERO
	if bullet_stars_pos:
		current_rot = bullet_stars_pos.rotation
		current_pos = bullet_stars_pos.position
	if is_swing and bullet_stars_pos:
		tween.tween_property(bullet_stars_pos, "rotation", current_rot + deg_to_rad(swing_arc/2), attack_duration/2)
		tween.tween_property(bullet_stars_pos, "rotation", current_rot - deg_to_rad(swing_arc/2), attack_duration/2)
		tween.tween_property(bullet_stars_pos, "rotation", original_bullet_rot, 0.05)
	elif is_stab and bullet_stars_pos:
		tween.tween_property(bullet_stars_pos, "position", current_pos + Vector2(stab_distance, 0).rotated(current_rot), attack_duration/2)
		tween.tween_property(bullet_stars_pos, "position", original_bullet_pos, attack_duration/2)
	await tween.finished
	if shooter.is_in_group("spirit"):
		shooter.canAttack = true
	else:
		shooter.stats.canAttack = true
	if bullet_stars_pos:
		bullet_stars_pos.position = original_bullet_pos
		bullet_stars_pos.rotation = original_bullet_rot
	melee_active = false

func _on_melee_hitbox_entered(body: Node):
	if !melee_active:
		return
	var target = _find_entity_root(body)
	if targets_hit.has(target) or target == shooter:
		return
	if shooter.is_in_group("player") or shooter.is_in_group("spirit"):
		if target.is_in_group("enemy"):
			hit(target)
	elif shooter.is_in_group("enemy"):
		if target.is_in_group("player") or target.is_in_group("spirit"):
			hit(target)

func hit(hitBody):
	do_damage(hitBody)
	apply_knockback_to_target(hitBody)

func do_damage(hitBody):
	var target = _find_entity_root(hitBody)
	var total_damage
	if shooter.is_in_group("spirit"):
		total_damage = shooter.attackDamage + damageMod
	else:
		total_damage = shooter.stats.attackDamage + damageMod
	if target.is_in_group("enemy"):
		if target.has_method("damage"):
			target.damage(total_damage)
		elif target.get_parent() and target.get_parent().has_method("damage"):
			target.get_parent().damage(total_damage)
		targets_hit.append(target)
	elif target.is_in_group("player"):
		var mgr = target.get("manager")
		if mgr and mgr.has_method("damage"):
			mgr.damage(total_damage, get_parent(), cameraShakeAmount)
		elif target.get_parent():
			var pmgr = target.get_parent().get("manager")
			if pmgr and pmgr.has_method("damage"):
				pmgr.damage(total_damage, get_parent(), cameraShakeAmount)
		targets_hit.append(target)
	elif target.is_in_group("spirit"):
		if target.has_method("damage"):
			target.damage(total_damage, get_parent(), cameraShakeAmount)
		targets_hit.append(target)

func apply_knockback_to_target(hitBody):
	var target = _find_entity_root(hitBody)
	if knockback_force <= 0:
		return
	var knockback_direction = (target.global_position - shooter.global_position).normalized()
	if target.is_in_group("enemy"):
		if target.has_method("apply_knockback"):
			target.apply_knockback(knockback_direction, knockback_force)
		elif target.get_parent() and target.get_parent().has_method("apply_knockback"):
			target.get_parent().apply_knockback(knockback_direction, knockback_force)
	elif target.is_in_group("player"):
		var mgr = target.get("manager")
		if mgr and mgr.has_method("apply_knockback"):
			mgr.apply_knockback(knockback_direction, knockback_force)
		elif target.get_parent():
			var pmgr = target.get_parent().get("manager")
			if pmgr and pmgr.has_method("apply_knockback"):
				pmgr.apply_knockback(knockback_direction, knockback_force)

func _evenly_spaced_angle(base_rot: float, index: int, count: int, cone: float) -> float:
	if count <= 1:
		return base_rot
	var t = float(index) / float(count - 1)
	return base_rot + lerp(-cone * 0.5, cone * 0.5, t)

func shoot():
	var total_bullets
	var spread_angle_deg
	var projectile_speed
	var pierce
	var attack_damage
	var bullet_lifetime
	var bullet_size
	if shooter.is_in_group("spirit"):
		total_bullets = shooter.bulletAmountMod + bulletAmountMod
		spread_angle_deg = shooter.rotationAdditionMod + rotationAdditionMod
		projectile_speed = shooter.projectileSpeed + projectileSpeedMod
		pierce = shooter.pierce + pierceMod
		attack_damage = shooter.attackDamage + damageMod
		bullet_lifetime = shooter.lifetime + bulletLifeTimeMod
		bullet_size = shooter.bulletSize + bulletSizeMod
	else:
		total_bullets = shooter.stats.bulletAmount + bulletAmountMod
		spread_angle_deg = GlobalPlayer.stats.rotationAddition + rotationAdditionMod
		projectile_speed = shooter.stats.projectileSpeed + projectileSpeedMod
		pierce = shooter.stats.pierce + pierceMod
		attack_damage = shooter.stats.attackDamage + damageMod
		bullet_lifetime = shooter.stats.bulletLifeTime + bulletLifeTimeMod
		bullet_size = shooter.stats.bulletSize + bulletSizeMod
	var spawn_pos: Vector2 = bullet_stars_pos.global_position if bullet_stars_pos else global_position
	var aim_pos: Vector2
	if shooter.is_in_group("player") or shooter.is_in_group("spirit"):
		aim_pos = get_global_mouse_position()
	elif shooter.is_in_group("enemy") and GlobalPlayer.player:
		aim_pos = GlobalPlayer.player.global_position
	else:
		aim_pos = spawn_pos + Vector2(1, 0).rotated(bullet_stars_pos.rotation if bullet_stars_pos else rotation)
	var base_rot: float = (aim_pos - spawn_pos).angle()
	var spread_angle = deg_to_rad(spread_angle_deg)
	if spread_angle < 0.0:
		spread_angle = abs(spread_angle)
	if spread_angle > PI:
		spread_angle = PI
	for i in range(total_bullets):
		var bullet = bulletScene.instantiate()
		if shooter.is_in_group("player"):
			bullet.shooter_group = "player"
		elif shooter.is_in_group("enemy"):
			bullet.shooter_group = "enemy"
		elif shooter.is_in_group("spirit"):
			bullet.shooter_group = "spirit"
		bullet.knockback_force = knockback_force
		bullet.hasInfPierce = hasInfPierce
		bullet.canKeepTicking = canKeepTicking
		bullet.tick_interval = tick_interval
		bullet.do_more_damage_to_enemies_with_hp_percent = do_more_damage_to_enemies_with_hp_percent
		bullet.enemy_health_percentage_min = enemy_health_percentage_min
		bullet.damage_mult_for_dmdtewhp = damage_mult_for_dmdtewhp
		if shooter.is_in_group("player"):
			GlobalPlayer.camera.apply_shake(cameraShakeAmount)
		var current_rot: float = base_rot
		if total_bullets > 1 and !doConsecShooting:
			if doRandomRotAndPos:
				current_rot = base_rot + randf_range(-spread_angle * 0.5, spread_angle * 0.5)
			else:
				current_rot = _evenly_spaced_angle(base_rot, i, total_bullets, spread_angle)
		else:
			current_rot = base_rot

		bullet.rot = current_rot
		bullet.rotation = current_rot
		bullet.projectileSpeed = projectile_speed
		bullet.speed_mode = bullet_speed_mode
		bullet.end_speed_multiplier = bullet_end_speed_multiplier
		bullet.pierce = pierce
		bullet.damage = attack_damage
		bullet.lifetime = bullet_lifetime
		bullet.set_scale(bullet_size)

		var final_pos = bullet_stars_pos.global_position if bullet_stars_pos else spawn_pos
		if pos_scatter_radius > 0.0:
			var forward_dist = randf() * pos_scatter_radius
			var forward_offset = Vector2(forward_dist, 0).rotated(base_rot)
			final_pos += forward_offset
		bullet.global_position = final_pos

		bullet.shake = cameraShakeAmount
		bullet.is_laser = is_laser
		bullet.laser_max_length = laser_max_length
		bullet.laser_width = laser_width
		bullet.projectile_sprite_size = Vector2(laser_max_length, laser_width)
		bullet.canPhaseThroughWall = canPhaseThroughWall
		bullet.is_attached_to_shooter = laser_attach_to_shooter
		bullet.attached_shooter = shooter if laser_attach_to_shooter else null
		GlobalWorld.projectiles.add_child(bullet)

		if bullet.is_laser and bullet.is_attached_to_shooter and shooter.is_in_group("player") and laser_hold_while_held:
			while Input.is_action_pressed("attack"):
				if is_instance_valid(get_tree()):
					await get_tree().process_frame

		if doConsecShooting:
			await get_tree().create_timer(0.1).timeout

func _on_attack_cooldown_timeout() -> void:
	if shooter and shooter.is_in_group("spirit"):
		shooter.canAttack = true
	elif shooter and (shooter.is_in_group("player") or shooter.is_in_group("enemy")):
		shooter.stats.canAttack = true

func _find_entity_root(n: Node) -> Node:
	var cur = n
	while cur:
		if cur.is_in_group("player") or cur.is_in_group("enemy") or cur.is_in_group("spirit"):
			return cur
		if cur.get_parent() == null:
			break
		cur = cur.get_parent()
	return n
