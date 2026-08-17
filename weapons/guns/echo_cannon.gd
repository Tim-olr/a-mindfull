extends Weapon

const SPLIT_DELAY := 0.3
const SPLIT_COUNT := 3
const SPLIT_SPREAD := 0.5

func _shoot_projectile() -> void:
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
	var projectile_speed: float = shooter.stats.projectileSpeed + projectileSpeedMod
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount)
	var bullet = bulletScene.instantiate()
	var group := "player" if shooter.is_in_group("player") else "enemy"
	bullet.shooter_group = group
	bullet.knockback_force = knockback_force
	bullet.hasInfPierce = false
	bullet.rot = base_rot
	bullet.rotation = base_rot
	bullet.projectileSpeed = projectile_speed
	bullet.pierce = pierce
	bullet.damage = attack_damage
	bullet.lifetime = bullet_lifetime
	bullet.collision_area.set_scale(custom_collision_sizes)
	bullet.global_position = spawn_pos
	bullet.shake = cameraShakeAmount
	bullet.scale = Vector2(1.3, 1.3)
	if !GameManager.is_in_lobby:
		GlobalWorld.projectiles.add_child(bullet)
	else:
		GlobalPlayer.player.get_parent().add_child(bullet)
	_schedule_split(bullet, attack_damage * 0.5, projectile_speed * 0.8, bullet_lifetime * 0.6, group)

func _schedule_split(bullet: Node, damage: float, speed: float, lifetime: float, group: String) -> void:
	await get_tree().create_timer(SPLIT_DELAY).timeout
	if not is_instance_valid(bullet):
		return
	var pos = bullet.global_position
	var base_rot: float = bullet.rot if bullet.rot != null else bullet.rotation
	bullet.queue_free()
	for i in range(SPLIT_COUNT):
		var angle_offset := (float(i) - float(SPLIT_COUNT - 1) / 2.0) * SPLIT_SPREAD
		var sub = bulletScene.instantiate()
		sub.shooter_group = group
		sub.knockback_force = knockback_force * 0.5
		sub.hasInfPierce = false
		sub.rot = base_rot + angle_offset
		sub.rotation = sub.rot
		sub.projectileSpeed = speed
		sub.pierce = 1
		sub.damage = damage
		sub.lifetime = lifetime
		sub.collision_area.set_scale(custom_collision_sizes * 0.7)
		sub.global_position = pos
		sub.shake = cameraShakeAmount * 0.3
		sub.scale = Vector2(0.7, 0.7)
		var parent: Node
		if !GameManager.is_in_lobby and GlobalWorld.projectiles != null:
			parent = GlobalWorld.projectiles
		else:
			parent = GlobalPlayer.player.get_parent()
		parent.add_child(sub)
