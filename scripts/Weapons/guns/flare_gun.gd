extends Weapon

const EXPLOSION_RADIUS := 60.0
const LIGHT_RADIUS := 300.0
const LIGHT_DURATION := 8.0

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
	bullet.scale = Vector2(1.2, 1.2)
	if !GameManager.is_in_lobby:
		GlobalWorld.projectiles.add_child(bullet)
	else:
		GlobalPlayer.player.get_parent().add_child(bullet)
	bullet.tree_exiting.connect(_on_flare_hit.bind(bullet))

func _on_flare_hit(bullet: Node) -> void:
	var pos := bullet.global_position
	var attack_damage: float = shooter.stats.attackDamage + damageMod + rarity_damage
	_do_explosion(pos, attack_damage * 1.5)
	_spawn_light(pos)

func _do_explosion(pos: Vector2, damage: float) -> void:
	var parent: Node2D
	if !GameManager.is_in_lobby and GlobalWorld.projectiles != null:
		parent = GlobalWorld.projectiles
	else:
		parent = GlobalPlayer.player.get_parent()
	var area := Area2D.new()
	area.global_position = pos
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = EXPLOSION_RADIUS
	shape.shape = circle
	area.add_child(shape)
	parent.add_child(area)
	area.monitoring = true
	await area.get_tree().physics_frame
	await area.get_tree().physics_frame
	for body in area.get_overlapping_bodies():
		if body == null:
			continue
		if body.is_in_group("player") and shooter.is_in_group("player"):
			continue
		if body.is_in_group("enemy"):
			if body.has_method("damage"):
				body.damage(damage, shooter, cameraShakeAmount)
	area.queue_free()
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount * 2.0)

func _spawn_light(pos: Vector2) -> void:
	var light := PointLight2D.new()
	light.global_position = pos
	light.texture = _make_light_texture()
	light.texture_scale = LIGHT_RADIUS / 64.0
	light.color = Color(1.0, 0.7, 0.3)
	light.energy = 1.5
	light.z_index = 5
	var parent: Node2D
	if !GameManager.is_in_lobby and GlobalWorld.theWorld != null:
		parent = GlobalWorld.theWorld
	else:
		parent = GlobalPlayer.player.get_parent()
	parent.add_child(light)
	var tw := light.create_tween()
	tw.tween_property(light, "energy", 0.0, LIGHT_DURATION).set_delay(LIGHT_DURATION * 0.6)
	tw.tween_callback(light.queue_free)

func _make_light_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.add_point(1.0, Color.TRANSPARENT)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 128
	t.height = 128
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	return t
