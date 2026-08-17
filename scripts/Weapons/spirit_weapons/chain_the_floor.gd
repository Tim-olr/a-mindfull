extends Weapon

# Fires 3 short-lived stationary hitboxes at increasing distances.
# The tip (furthest from the spirit) deals the most damage.
func perform_attack() -> void:
	if not has_no_cooldown:
		shooter.stats.canAttack = false
		attack_cooldown.set_wait_time(shooter.stats.attackSpeed + shootCooldown)
		attack_cooldown.start()
	_shoot_chain()

func _shoot_chain() -> void:
	if not is_instance_valid(bulletScene):
		return
	var base_damage: float = shooter.stats.attackDamage + damageMod + rarity_damage
	var pierce: int        = shooter.stats.pierce + pierceMod
	var spawn_pos: Vector2 = bullet_stars_pos.global_position if bullet_stars_pos else global_position
	var aim_pos: Vector2   = get_global_mouse_position()
	var base_rot: float    = (aim_pos - spawn_pos).angle()
	var dir: Vector2       = Vector2.from_angle(base_rot)

	# [distance_from_spirit, damage_multiplier]
	var segments := [
		[18.0,  0.35],   # handle — weakest
		[62.0,  0.85],   # mid chain
		[115.0, 1.80],   # tip — strongest
	]

	for seg in segments:
		var bullet = bulletScene.instantiate()
		bullet.shooter_group = "spirit"
		bullet.knockback_force  = knockback_force
		bullet.hasInfPierce     = true
		bullet.canKeepTicking   = false
		bullet.do_more_damage_to_enemies_with_hp_percent = GlobalPlayer.stats.do_more_damage_to_enemies_with_hp_percent
		bullet.enemy_health_percentage_min               = GlobalPlayer.stats.enemy_health_percentage_min
		bullet.damage_mult_for_dmdtewhp                  = GlobalPlayer.stats.damage_mult_for_dmdtewhp
		bullet.damage           = base_damage * seg[1]
		bullet.lifetime         = 0.13
		bullet.projectileSpeed  = 0.0
		bullet.speed_mode       = 0
		bullet.end_speed_multiplier = 1.0
		bullet.pierce           = pierce
		bullet.rot              = base_rot
		bullet.rotation         = base_rot
		bullet.shake            = cameraShakeAmount
		bullet.global_position  = spawn_pos + dir * seg[0]
		bullet.collision_area.set_scale(Vector2(2.5, 2.5))
		if not GameManager.is_in_lobby:
			GlobalWorld.projectiles.add_child(bullet)
		else:
			GlobalPlayer.player.get_parent().add_child(bullet)
