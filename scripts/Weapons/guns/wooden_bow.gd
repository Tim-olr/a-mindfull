extends Weapon

var _charging := false
var _charge_time := 0.0
const MAX_CHARGE := 1.5
const MIN_CHARGE := 0.3

@onready var charge_bar: Node2D = $CanvasLayer/BowChargeBar

func _process(delta: float) -> void:
	super._process(delta)
	if not isSelected or not shooter.is_in_group("player"):
		charge_bar.hide_bar()
		return
	if _charging:
		charge_bar.show_bar(_charge_time / MAX_CHARGE)
	else:
		charge_bar.hide_bar()
	if Input.is_action_pressed("attack") and shooter.stats.canAttack:
		if not _charging:
			_charging = true
			_charge_time = 0.0
		_charge_time = minf(_charge_time + delta, MAX_CHARGE)
	elif _charging:
		if _charge_time >= MIN_CHARGE:
			_fire_charged_arrow()
		_charging = false
		_charge_time = 0.0

func perform_attack() -> void:
	pass

func _fire_charged_arrow() -> void:
	var charge_ratio := clampf(_charge_time / MAX_CHARGE, 0.0, 1.0)
	var spawn_pos: Vector2 = bullet_stars_pos.global_position if bullet_stars_pos else global_position
	var aim_pos: Vector2 = get_global_mouse_position()
	var base_rot: float = (aim_pos - spawn_pos).angle()
	var bullet = bulletScene.instantiate()
	if shooter.is_in_group("player"):
		bullet.shooter_group = "player"
	bullet.knockback_force = knockback_force * (0.5 + charge_ratio * 0.5)
	bullet.hasInfPierce = hasInfPierce
	bullet.rot = base_rot
	bullet.rotation = base_rot
	bullet.projectileSpeed = (projectileSpeedMod + shooter.stats.projectileSpeed) * (0.4 + charge_ratio * 0.6)
	bullet.pierce = shooter.stats.pierce + pierceMod + int(charge_ratio * 2.0)
	bullet.damage = (shooter.stats.attackDamage + damageMod + rarity_damage) * (0.3 + charge_ratio * 0.7)
	bullet.lifetime = (shooter.stats.bulletLifeTime + bulletLifeTimeMod) * (0.5 + charge_ratio * 0.5)
	bullet.collision_area.set_scale(custom_collision_sizes)
	bullet.global_position = spawn_pos
	bullet.shake = cameraShakeAmount * charge_ratio
	bullet.projectile_sprite_scene = projectile_sprite_scene
	bullet.scale = Vector2(0.8 + charge_ratio * 0.6, 0.8 + charge_ratio * 0.6)
	if !GameManager.is_in_lobby:
		GlobalWorld.projectiles.add_child(bullet)
	else:
		GlobalPlayer.player.get_parent().add_child(bullet)
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount * charge_ratio)
	shooter.stats.canAttack = false
	var cd = shootCooldown + shooter.stats.attackSpeed
	attack_cooldown.set_wait_time(cd * (1.0 - charge_ratio * 0.3))
	attack_cooldown.start()
