extends Weapon

enum Spell { FIREBALL, ICE_SPIKE, CHAIN_LIGHTNING }
const SPELL_NAMES := ["Fireball", "Ice Spike", "Chain Lightning"]

func perform_attack() -> void:
	if !has_no_cooldown:
		shooter.stats.canAttack = false
		attack_cooldown.set_wait_time(shooter.stats.attackSpeed + shootCooldown)
		attack_cooldown.start()
	var spell: Spell = randi() % 3 as Spell
	match spell:
		Spell.FIREBALL:
			_cast_fireball()
		Spell.ICE_SPIKE:
			_cast_ice_spike()
		Spell.CHAIN_LIGHTNING:
			_cast_chain_lightning()
	_show_spell_name(SPELL_NAMES[spell])

func _cast_fireball() -> void:
	var spawn_pos: Vector2 = bullet_stars_pos.global_position if bullet_stars_pos else global_position
	var aim_pos: Vector2 = get_global_mouse_position() if shooter.is_in_group("player") else GlobalPlayer.player.global_position
	var base_rot: float = (aim_pos - spawn_pos).angle()
	var attack_damage: float = (shooter.stats.attackDamage + damageMod + rarity_damage) * 1.5
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount * 1.5)
	var bullet = bulletScene.instantiate()
	bullet.shooter_group = "player" if shooter.is_in_group("player") else "enemy"
	bullet.knockback_force = knockback_force * 1.5
	bullet.rot = base_rot
	bullet.rotation = base_rot
	bullet.projectileSpeed = (shooter.stats.projectileSpeed + projectileSpeedMod) * 0.7
	bullet.pierce = 3
	bullet.damage = attack_damage
	bullet.lifetime = shooter.stats.bulletLifeTime + bulletLifeTimeMod
	bullet.collision_area.set_scale(custom_collision_sizes * 1.5)
	bullet.global_position = spawn_pos
	bullet.shake = cameraShakeAmount * 1.5
	bullet.scale = Vector2(1.8, 1.8)
	bullet.modulate = Color(1.0, 0.4, 0.1)
	if !GameManager.is_in_lobby:
		GlobalWorld.projectiles.add_child(bullet)
	else:
		GlobalPlayer.player.get_parent().add_child(bullet)

func _cast_ice_spike() -> void:
	var spawn_pos: Vector2 = bullet_stars_pos.global_position if bullet_stars_pos else global_position
	var aim_pos: Vector2 = get_global_mouse_position() if shooter.is_in_group("player") else GlobalPlayer.player.global_position
	var base_rot: float = (aim_pos - spawn_pos).angle()
	var attack_damage: float = shooter.stats.attackDamage + damageMod + rarity_damage
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount)
	for i in range(5):
		var bullet = bulletScene.instantiate()
		bullet.shooter_group = "player" if shooter.is_in_group("player") else "enemy"
		bullet.knockback_force = knockback_force
		var offset := (float(i) - 2.0) * 0.12
		bullet.rot = base_rot + offset
		bullet.rotation = bullet.rot
		bullet.projectileSpeed = (shooter.stats.projectileSpeed + projectileSpeedMod) * 1.3
		bullet.pierce = 1
		bullet.damage = attack_damage * 0.6
		bullet.lifetime = (shooter.stats.bulletLifeTime + bulletLifeTimeMod) * 0.7
		bullet.collision_area.set_scale(custom_collision_sizes)
		bullet.global_position = spawn_pos + Vector2(i * 3.0, 0).rotated(base_rot + PI / 2.0)
		bullet.shake = cameraShakeAmount * 0.3
		bullet.scale = Vector2(0.8, 1.2)
		bullet.modulate = Color(0.5, 0.8, 1.0)
		if !GameManager.is_in_lobby:
			GlobalWorld.projectiles.add_child(bullet)
		else:
			GlobalPlayer.player.get_parent().add_child(bullet)

func _cast_chain_lightning() -> void:
	var spawn_pos: Vector2 = bullet_stars_pos.global_position if bullet_stars_pos else global_position
	var aim_pos: Vector2 = get_global_mouse_position() if shooter.is_in_group("player") else GlobalPlayer.player.global_position
	var base_rot: float = (aim_pos - spawn_pos).angle()
	var attack_damage: float = (shooter.stats.attackDamage + damageMod + rarity_damage) * 0.8
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount)
	var bullet = bulletScene.instantiate()
	bullet.shooter_group = "player" if shooter.is_in_group("player") else "enemy"
	bullet.knockback_force = knockback_force * 0.5
	bullet.rot = base_rot
	bullet.rotation = base_rot
	bullet.projectileSpeed = (shooter.stats.projectileSpeed + projectileSpeedMod) * 1.5
	bullet.hasInfPierce = true
	bullet.canKeepTicking = true
	bullet.tick_interval = 0.15
	bullet.pierce = 999
	bullet.damage = attack_damage
	bullet.lifetime = (shooter.stats.bulletLifeTime + bulletLifeTimeMod) * 0.5
	bullet.collision_area.set_scale(custom_collision_sizes * 2.0)
	bullet.global_position = spawn_pos
	bullet.shake = cameraShakeAmount
	bullet.modulate = Color(0.8, 0.8, 1.0)
	if !GameManager.is_in_lobby:
		GlobalWorld.projectiles.add_child(bullet)
	else:
		GlobalPlayer.player.get_parent().add_child(bullet)

func _show_spell_name(spell_name: String) -> void:
	if not is_instance_valid(GlobalPlayer.player):
		return
	var label := Label.new()
	label.text = spell_name
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_color_override("font_color", Color(0.7, 0.5, 1.0))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.z_index = 1000
	label.scale = Vector2(0.12, 0.12)
	label.position = GlobalPlayer.player.global_position + Vector2(-20, -35)
	if GlobalWorld.dmgNrs != null:
		GlobalWorld.dmgNrs.add_child(label)
	else:
		GlobalPlayer.player.get_parent().add_child(label)
	var tw := label.create_tween().set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 20, 0.8)
	tw.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tw.chain().tween_callback(label.queue_free)
	await get_tree().create_timer(0.5).timeout
	label.queue_free()
