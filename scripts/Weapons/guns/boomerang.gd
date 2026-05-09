extends Weapon

func perform_attack() -> void:
	if !has_no_cooldown:
		shooter.stats.canAttack = false
		attack_cooldown.set_wait_time(shooter.stats.attackSpeed + shootCooldown)
		attack_cooldown.start()
	if gun:
		_throw_boomerang()

func _throw_boomerang() -> void:
	var spawn_pos: Vector2 = bullet_stars_pos.global_position if bullet_stars_pos else global_position
	var aim_pos: Vector2
	if shooter.is_in_group("player") or shooter.is_in_group("spirit"):
		aim_pos = get_global_mouse_position()
	elif shooter.is_in_group("enemy") and GlobalPlayer.player:
		aim_pos = GlobalPlayer.player.global_position
	else:
		aim_pos = spawn_pos + Vector2.RIGHT.rotated(rotation)
	var base_rot: float = (aim_pos - spawn_pos).angle()
	var attack_damage: float = shooter.stats.attackDamage + damageMod + rarity_damage
	var projectile_speed: float = shooter.stats.projectileSpeed + projectileSpeedMod
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount)
	var bullet = bulletScene.instantiate()
	if shooter.is_in_group("player"):
		bullet.shooter_group = "player"
	elif shooter.is_in_group("enemy"):
		bullet.shooter_group = "enemy"
	bullet.knockback_force = knockback_force
	bullet.hasInfPierce = true
	bullet.canKeepTicking = true
	bullet.tick_interval = 0.25
	bullet.rot = base_rot
	bullet.rotation = base_rot
	bullet.projectileSpeed = projectile_speed
	bullet.speed_mode = 2
	bullet.end_speed_multiplier = -1.0
	bullet.pierce = 999
	bullet.damage = attack_damage
	bullet.lifetime = shooter.stats.bulletLifeTime + bulletLifeTimeMod
	bullet.collision_area.set_scale(custom_collision_sizes)
	bullet.global_position = spawn_pos
	bullet.shake = cameraShakeAmount
	if !GameManager.is_in_lobby:
		GlobalWorld.projectiles.add_child(bullet)
	else:
		GlobalPlayer.player.get_parent().add_child(bullet)
