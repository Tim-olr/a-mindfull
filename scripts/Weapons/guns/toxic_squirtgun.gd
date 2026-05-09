extends Weapon

func perform_attack() -> void:
	if !has_no_cooldown:
		shooter.stats.canAttack = false
		attack_cooldown.set_wait_time(shooter.stats.attackSpeed + shootCooldown)
		attack_cooldown.start()
	if gun:
		_shoot_burst()

func _shoot_burst() -> void:
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
	var bullet_lifetime: float = shooter.stats.bulletLifeTime + bulletLifeTimeMod
	var pierce: int = shooter.stats.pierce + pierceMod
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount)
	for i in range(12):
		var bullet = bulletScene.instantiate()
		if shooter.is_in_group("player"):
			bullet.shooter_group = "player"
		elif shooter.is_in_group("enemy"):
			bullet.shooter_group = "enemy"
		bullet.knockback_force = knockback_force
		bullet.hasInfPierce = hasInfPierce
		var spread := randf_range(-0.25, 0.25)
		bullet.rot = base_rot + spread
		bullet.rotation = bullet.rot
		bullet.projectileSpeed = (shooter.stats.projectileSpeed + projectileSpeedMod) * randf_range(0.8, 1.2)
		bullet.pierce = pierce
		bullet.damage = attack_damage
		bullet.lifetime = bullet_lifetime * randf_range(0.6, 1.0)
		bullet.collision_area.set_scale(custom_collision_sizes)
		bullet.global_position = spawn_pos + Vector2(randf_range(-4, 4), randf_range(-4, 4))
		bullet.shake = cameraShakeAmount * 0.2
		bullet.scale = Vector2(0.6, 0.6)
		if !GameManager.is_in_lobby:
			GlobalWorld.projectiles.add_child(bullet)
		else:
			GlobalPlayer.player.get_parent().add_child(bullet)
		await get_tree().create_timer(0.02).timeout
