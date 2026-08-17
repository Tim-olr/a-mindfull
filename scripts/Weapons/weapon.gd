extends Node2D
class_name Weapon

@export_group("Base Stats")
@export var pierceMod: int = 0
@export var damageMod: float
@export var bulletLifeTimeMod: float
@export var bulletAmountMod: int
@export var rotationAdditionMod: float
@export var projectileSpeedMod: float
@export var shootCooldown: float
@export var gun: bool
@export var description: String
@export var Name: String
@export_enum("common", "uncommon", "rare", "epic", "legendary") var rarity: int = 0
@export var bulletScene: PackedScene
@export var doConsecShooting := false
@export var consec_shooting_time_between: float = 0.1
@export var cameraShakeAmount: float
@export var knockback_force: float = 250.0
@export var shoot_in_circle: bool = false
@export var custom_collision_sizes: Vector2 = Vector2(1.0, 1.0)

@export_category("other")
@export var do_more_damage_to_enemies_with_hp_percent: bool = false
@export var enemy_health_percentage_min: int = 100
@export var damage_mult_for_dmdtewhp: float = 0.0
@export var projectile_sprite_scene: PackedScene
@export var has_no_rot: bool = false

@export var hasInfPierce: bool = false
@export var canKeepTicking: bool = false
@export var tick_interval: float = 0.1

@export var doRandomRotAndPos: bool = false
@export var pos_scatter_radius: float = 0.0
@export var has_no_cooldown := false

@export_group("Projectile Speed Over Time")
@export_enum("Constant", "Accelerate", "Decelerate") var bullet_speed_mode: int = 0
@export var bullet_end_speed_multiplier: float = 1.0

@export_category("Laser Settings")
@export var is_laser: bool = false
@export var laserScene: PackedScene
@export var laser_max_length: float = 400.0
@export var laser_width: float = 4.0
@export var canPhaseThroughWall: bool = false
@export var laser_attach_to_shooter: bool = false
@export var laser_hold_while_held: bool = false

var shooter: Node2D
var isSelected: bool = false

var rarity_damage: float

@onready var attack_cooldown: Timer = $attack_cooldown
@onready var bullet_stars_pos = $BulletStarsPos

var attackable: bool = true
var resource: ItemResource


func _ready() -> void:
	shooter = get_parent()


func initialize(res: ItemResource) -> void:
	resource = res
	rarity = res.rarity
	rarity_damage += rarity_damage_buff()


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
		bullet_stars_pos = shooter.bullet_start_pos
		global_position = shooter.global_position
		bullet_stars_pos.look_at(get_global_mouse_position())
		if Input.is_action_pressed("spirit_attack") and shooter.out and shooter.stats.canAttack and attackable:
			perform_attack()
			if shooter.sprites != null:
				shooter.sprites.play("attack")
	elif shooter.is_in_group("enemy"):
		if GlobalPlayer.player:
			bullet_stars_pos.look_at(GlobalPlayer.player.global_position)
			if gun:
				var dist = global_position.distance_to(GlobalPlayer.player.global_position)
				if shooter.stats.canAttack and dist < 1000:
					perform_attack()


func perform_attack() -> void:
	if !has_no_cooldown:
		shooter.stats.canAttack = false
		attack_cooldown.set_wait_time(shooter.stats.attackSpeed + shootCooldown)
		attack_cooldown.start()
	if gun:
		shoot()


func _evenly_spaced_angle(base_rot: float, index: int, count: int, cone: float) -> float:
	if count <= 1:
		return base_rot
	var t = float(index) / float(count - 1)
	return base_rot + lerp(-cone * 0.5, cone * 0.5, t)


func rarity_damage_buff():
	match rarity:
		1: return 5.0
		2: return 10.0
		3: return 20.0
		4: return 35.0
	return 0


func shoot() -> void:
	if is_laser:
		_shoot_laser()
	else:
		_shoot_projectile()


func _shoot_projectile() -> void:
	var total_bullets: int      = shooter.stats.bulletAmount + bulletAmountMod
	var spread_angle_deg: float = GlobalPlayer.stats.rotationAddition + rotationAdditionMod
	var projectile_speed: float = shooter.stats.projectileSpeed + projectileSpeedMod
	var pierce: int             = shooter.stats.pierce + pierceMod
	var attack_damage: float    = shooter.stats.attackDamage + damageMod + rarity_damage
	var bullet_lifetime: float  = shooter.stats.bulletLifeTime + bulletLifeTimeMod
	var spawn_pos: Vector2      = bullet_stars_pos.global_position if bullet_stars_pos else global_position
	var aim_pos: Vector2
	if shooter.is_in_group("player") or shooter.is_in_group("spirit"):
		aim_pos = get_global_mouse_position()
	elif shooter.is_in_group("enemy") and GlobalPlayer.player:
		aim_pos = GlobalPlayer.player.global_position
	else:
		aim_pos = spawn_pos + Vector2(1.0, 0.0).rotated(bullet_stars_pos.rotation if bullet_stars_pos else rotation)
	var base_rot: float     = (aim_pos - spawn_pos).angle()
	var spread_angle: float = deg_to_rad(spread_angle_deg)
	if spread_angle < 0.0:
		spread_angle = abs(spread_angle)
	if spread_angle > PI:
		spread_angle = PI
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount)
	for i in range(total_bullets):
		var bullet = bulletScene.instantiate()
		if shooter.is_in_group("player"):
			bullet.shooter_group = "player"
		elif shooter.is_in_group("enemy"):
			bullet.shooter_group = "enemy"
		elif shooter.is_in_group("spirit"):
			bullet.shooter_group = "spirit"
		bullet.knockback_force  = knockback_force
		bullet.hasInfPierce     = hasInfPierce
		bullet.canKeepTicking   = canKeepTicking
		bullet.tick_interval    = tick_interval
		bullet.do_more_damage_to_enemies_with_hp_percent = GlobalPlayer.stats.do_more_damage_to_enemies_with_hp_percent
		bullet.enemy_health_percentage_min               = GlobalPlayer.stats.enemy_health_percentage_min
		bullet.damage_mult_for_dmdtewhp                  = GlobalPlayer.stats.damage_mult_for_dmdtewhp
		bullet.projectile_sprite_scene                   = projectile_sprite_scene
		bullet.has_no_rot                                = has_no_rot
		var current_rot: float = base_rot
		if shoot_in_circle:
			current_rot = i * deg_to_rad(spread_angle_deg) * 2.0
		elif total_bullets > 1 and !doConsecShooting:
			if doRandomRotAndPos:
				current_rot = base_rot + randf_range(-spread_angle * 0.5, spread_angle * 0.5)
			else:
				current_rot = _evenly_spaced_angle(base_rot, i, total_bullets, spread_angle)
		else:
			current_rot = base_rot
		bullet.rot                  = current_rot
		bullet.rotation             = current_rot
		bullet.projectileSpeed      = projectile_speed
		bullet.speed_mode           = bullet_speed_mode
		bullet.end_speed_multiplier = bullet_end_speed_multiplier
		bullet.pierce               = pierce
		bullet.damage = attack_damage
		bullet.lifetime             = bullet_lifetime
		bullet.collision_area.set_scale(custom_collision_sizes)
		var final_pos: Vector2 = bullet_stars_pos.global_position if bullet_stars_pos else spawn_pos
		if pos_scatter_radius > 0.0:
			final_pos += Vector2(randf() * pos_scatter_radius, 0.0).rotated(base_rot)
		bullet.global_position = final_pos
		bullet.shake           = cameraShakeAmount
		if !GameManager.is_in_lobby:
			GlobalWorld.projectiles.add_child(bullet)
		else:
			GlobalPlayer.player.get_parent().add_child(bullet)
		if doConsecShooting:
			await get_tree().create_timer(consec_shooting_time_between).timeout


func _shoot_laser() -> void:
	var spawn_pos: Vector2 = bullet_stars_pos.global_position if bullet_stars_pos else global_position
	var aim_pos: Vector2
	if shooter.is_in_group("player") or shooter.is_in_group("spirit"):
		aim_pos = get_global_mouse_position()
	elif shooter.is_in_group("enemy") and GlobalPlayer.player:
		aim_pos = GlobalPlayer.player.global_position
	else:
		aim_pos = spawn_pos + Vector2(1.0, 0.0).rotated(bullet_stars_pos.rotation if bullet_stars_pos else rotation)
	var base_rot: float        = (aim_pos - spawn_pos).angle()
	var attack_damage: float   = shooter.stats.attackDamage + damageMod + rarity_damage
	var bullet_lifetime: float = shooter.stats.bulletLifeTime + bulletLifeTimeMod
	var pierce: int            = shooter.stats.pierce + pierceMod
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount)
	var laser = laserScene.instantiate()
	if shooter.is_in_group("player"):
		laser.shooter_group = "player"
	elif shooter.is_in_group("enemy"):
		laser.shooter_group = "enemy"
	elif shooter.is_in_group("spirit"):
		laser.shooter_group = "spirit"
	laser.rot                    = base_rot
	laser.rotation               = base_rot
	laser.damage = attack_damage
	laser.lifetime               = bullet_lifetime
	laser.pierce                 = pierce
	laser.knockback_force        = knockback_force
	laser.hasInfPierce           = hasInfPierce
	laser.canKeepTicking         = canKeepTicking
	laser.tick_interval          = tick_interval
	laser.laser_max_length       = laser_max_length
	laser.laser_width            = laser_width
	laser.canPhaseThroughWall    = canPhaseThroughWall
	laser.is_attached_to_shooter = laser_attach_to_shooter
	laser.laser_hold_while_held  = laser_hold_while_held
	laser.attached_shooter       = shooter if laser_attach_to_shooter else null
	laser.projectile_sprite_scene = projectile_sprite_scene
	laser.shake                  = cameraShakeAmount
	laser.do_more_damage_to_enemies_with_hp_percent = GlobalPlayer.stats.do_more_damage_to_enemies_with_hp_percent
	laser.enemy_health_percentage_min               = GlobalPlayer.stats.enemy_health_percentage_min
	laser.damage_mult_for_dmdtewhp                  = GlobalPlayer.stats.damage_mult_for_dmdtewhp
	laser.global_position = spawn_pos
	if !GameManager.is_in_lobby:
		GlobalWorld.projectiles.add_child(laser)
	else:
		GlobalPlayer.player.get_parent().add_child(laser)


func _on_attack_cooldown_timeout() -> void:
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


func change_rarity(r: int):
	rarity = r
	resource.rarity = r
	resource.calculate_rarity_outline()
	rarity_damage = rarity_damage_buff()
