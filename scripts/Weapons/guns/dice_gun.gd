extends Weapon

func perform_attack() -> void:
	if !has_no_cooldown:
		shooter.stats.canAttack = false
		attack_cooldown.set_wait_time(shooter.stats.attackSpeed + shootCooldown)
		attack_cooldown.start()
	if gun:
		_shoot_d20()

func _shoot_d20() -> void:
	var spawn_pos: Vector2 = bullet_stars_pos.global_position if bullet_stars_pos else global_position
	var aim_pos: Vector2
	if shooter.is_in_group("player") or shooter.is_in_group("spirit"):
		aim_pos = get_global_mouse_position()
	elif shooter.is_in_group("enemy") and GlobalPlayer.player:
		aim_pos = GlobalPlayer.player.global_position
	else:
		aim_pos = spawn_pos + Vector2.RIGHT.rotated(rotation)
	var base_rot: float = (aim_pos - spawn_pos).angle()
	var roll: int = randi_range(1, 20)
	var base_damage: float = shooter.stats.attackDamage + damageMod + rarity_damage
	var damage_mult: float = float(roll) / 10.0
	var final_damage: float = base_damage * damage_mult
	var bullet_lifetime: float = shooter.stats.bulletLifeTime + bulletLifeTimeMod
	var pierce: int = shooter.stats.pierce + pierceMod
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount * damage_mult)
	var bullet = bulletScene.instantiate()
	if shooter.is_in_group("player"):
		bullet.shooter_group = "player"
	elif shooter.is_in_group("enemy"):
		bullet.shooter_group = "enemy"
	bullet.knockback_force = knockback_force * damage_mult
	bullet.hasInfPierce = hasInfPierce
	bullet.rot = base_rot
	bullet.rotation = base_rot
	bullet.projectileSpeed = shooter.stats.projectileSpeed + projectileSpeedMod
	bullet.pierce = pierce
	bullet.damage = final_damage
	bullet.lifetime = bullet_lifetime
	bullet.collision_area.set_scale(custom_collision_sizes)
	bullet.global_position = spawn_pos
	bullet.shake = cameraShakeAmount
	bullet.projectile_sprite_scene = projectile_sprite_scene
	var bullet_scale := 0.8 + float(roll) / 20.0 * 0.8
	bullet.scale = Vector2(bullet_scale, bullet_scale)
	if !GameManager.is_in_lobby:
		GlobalWorld.projectiles.add_child(bullet)
	else:
		GlobalPlayer.player.get_parent().add_child(bullet)
	_show_roll_popup(roll, final_damage)

func _show_roll_popup(roll: int, damage: float) -> void:
	if not is_instance_valid(GlobalPlayer.player):
		return
	var col: Color
	if roll == 20:
		col = Color.GOLD
	elif roll >= 15:
		col = Color.GREEN
	elif roll >= 10:
		col = Color.WHITE
	elif roll >= 5:
		col = Color.ORANGE
	else:
		col = Color.RED
	var label := Label.new()
	label.text = "D20: %d! (%.1f dmg)" % [roll, damage]
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_constant_override("outline_size", 12)
	label.add_theme_color_override("font_color", col)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.z_index = 1000
	label.scale = Vector2(0.15, 0.15)
	label.position = GlobalPlayer.player.global_position + Vector2(-30, -40)
	if GlobalWorld.dmgNrs != null:
		GlobalWorld.dmgNrs.add_child(label)
	else:
		GlobalPlayer.player.get_parent().add_child(label)
	var tw := label.create_tween().set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 30, 1.2)
	tw.tween_property(label, "modulate:a", 0.0, 1.2).set_delay(0.3)
	tw.chain().tween_callback(label.queue_free)
	await get_tree().create_timer(0.5).timeout
	label.queue_free()
