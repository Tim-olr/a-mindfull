extends Weapon

const MAX_BOUNCES := 3
const BOUNCE_RANGE := 300.0

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
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount)
	var bullet = bulletScene.instantiate()
	if shooter.is_in_group("player"):
		bullet.shooter_group = "player"
	elif shooter.is_in_group("enemy"):
		bullet.shooter_group = "enemy"
	bullet.knockback_force = knockback_force
	bullet.hasInfPierce = false
	bullet.rot = base_rot
	bullet.rotation = base_rot
	bullet.projectileSpeed = shooter.stats.projectileSpeed + projectileSpeedMod
	bullet.pierce = 1
	bullet.damage = attack_damage
	bullet.lifetime = bullet_lifetime
	bullet.collision_area.set_scale(custom_collision_sizes)
	bullet.global_position = spawn_pos
	bullet.shake = cameraShakeAmount
	bullet.set_meta("bounces_left", MAX_BOUNCES)
	bullet.set_meta("ricochet_damage", attack_damage)
	bullet.set_meta("ricochet_speed", shooter.stats.projectileSpeed + projectileSpeedMod)
	bullet.set_meta("ricochet_lifetime", bullet_lifetime)
	bullet.set_meta("ricochet_shooter_group", bullet.shooter_group)
	if !GameManager.is_in_lobby:
		GlobalWorld.projectiles.add_child(bullet)
	else:
		GlobalPlayer.player.get_parent().add_child(bullet)
	bullet.tree_exiting.connect(_on_bullet_exit.bind(bullet))

func _on_bullet_exit(bullet: Node) -> void:
	if not bullet.has_meta("bounces_left"):
		return
	var bounces: int = bullet.get_meta("bounces_left")
	if bounces <= 0:
		return
	var pos := bullet.global_position
	var old_rot: float = bullet.rot if bullet.rot != null else bullet.rotation
	var new_rot: float = old_rot + randf_range(PI * 0.3, PI * 0.7) * (1 if randf() > 0.5 else -1)
	var new_bullet = bulletScene.instantiate()
	new_bullet.shooter_group = bullet.get_meta("ricochet_shooter_group")
	new_bullet.knockback_force = knockback_force * 0.8
	new_bullet.hasInfPierce = false
	new_bullet.rot = new_rot
	new_bullet.rotation = new_rot
	new_bullet.projectileSpeed = bullet.get_meta("ricochet_speed")
	new_bullet.pierce = 1
	new_bullet.damage = bullet.get_meta("ricochet_damage") * 0.8
	new_bullet.lifetime = bullet.get_meta("ricochet_lifetime") * 0.7
	new_bullet.collision_area.set_scale(custom_collision_sizes)
	new_bullet.global_position = pos
	new_bullet.shake = cameraShakeAmount * 0.3
	new_bullet.set_meta("bounces_left", bounces - 1)
	new_bullet.set_meta("ricochet_damage", new_bullet.damage)
	new_bullet.set_meta("ricochet_speed", new_bullet.projectileSpeed)
	new_bullet.set_meta("ricochet_lifetime", new_bullet.lifetime)
	new_bullet.set_meta("ricochet_shooter_group", new_bullet.shooter_group)
	var parent: Node
	if !GameManager.is_in_lobby and GlobalWorld.projectiles != null:
		parent = GlobalWorld.projectiles
	else:
		parent = GlobalPlayer.player.get_parent()
	parent.call_deferred("add_child", new_bullet)
	new_bullet.tree_exiting.connect(_on_bullet_exit.bind(new_bullet))
