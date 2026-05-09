extends Weapon

func _shoot_projectile() -> void:
	var total_bullets: int = shooter.stats.bulletAmount + bulletAmountMod
	var spread_angle_deg: float = GlobalPlayer.stats.rotationAddition + rotationAdditionMod
	var projectile_speed: float = shooter.stats.projectileSpeed + projectileSpeedMod
	var pierce: int = shooter.stats.pierce + pierceMod
	var attack_damage: float = shooter.stats.attackDamage + damageMod + rarity_damage
	var bullet_lifetime: float = shooter.stats.bulletLifeTime + bulletLifeTimeMod
	var spawn_pos: Vector2 = bullet_stars_pos.global_position if bullet_stars_pos else global_position
	var aim_pos: Vector2
	if shooter.is_in_group("player") or shooter.is_in_group("spirit"):
		aim_pos = get_global_mouse_position()
	elif shooter.is_in_group("enemy") and GlobalPlayer.player:
		aim_pos = GlobalPlayer.player.global_position
	else:
		aim_pos = spawn_pos + Vector2.RIGHT.rotated(rotation)
	var base_rot: float = (aim_pos - spawn_pos).angle()
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount)
	for i in range(total_bullets):
		var bullet = bulletScene.instantiate()
		if shooter.is_in_group("player"):
			bullet.shooter_group = "player"
		elif shooter.is_in_group("enemy"):
			bullet.shooter_group = "enemy"
		bullet.knockback_force = knockback_force
		bullet.hasInfPierce = hasInfPierce
		bullet.rot = base_rot + randf_range(-0.08, 0.08)
		bullet.rotation = bullet.rot
		bullet.projectileSpeed = projectile_speed
		bullet.pierce = pierce
		bullet.damage = attack_damage
		bullet.lifetime = bullet_lifetime
		bullet.collision_area.set_scale(custom_collision_sizes)
		bullet.global_position = spawn_pos
		bullet.shake = cameraShakeAmount * 0.3
		bullet.scale = Vector2(0.5, 0.5)
		if bullet.has_method("set_meta"):
			bullet.set_meta("nail_gun", true)
		if !GameManager.is_in_lobby:
			GlobalWorld.projectiles.add_child(bullet)
		else:
			GlobalPlayer.player.get_parent().add_child(bullet)
		if doConsecShooting:
			await get_tree().create_timer(consec_shooting_time_between).timeout
