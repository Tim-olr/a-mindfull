extends Weapon

var _orbitals: Array = []
const ORBIT_RADIUS_MIN := 30.0
const ORBIT_RADIUS_MAX := 60.0
const ORBIT_SPEED := 4.0
const ORBIT_LIFETIME := 50.0

func perform_attack() -> void:
	if !has_no_cooldown:
		shooter.stats.canAttack = false
		attack_cooldown.set_wait_time(shooter.stats.attackSpeed + shootCooldown)
		attack_cooldown.start()
	if gun:
		_spawn_orbital()

func _spawn_orbital() -> void:
	var attack_damage: float = shooter.stats.attackDamage + damageMod + rarity_damage
	var bullet = bulletScene.instantiate()
	if shooter.is_in_group("player"):
		bullet.shooter_group = "player"
	elif shooter.is_in_group("enemy"):
		bullet.shooter_group = "enemy"
	bullet.knockback_force = knockback_force
	bullet.hasInfPierce = false
	bullet.rot = 0
	bullet.rotation = 0
	bullet.projectileSpeed = 0
	bullet.pierce = 1
	bullet.damage = attack_damage
	bullet.lifetime = ORBIT_LIFETIME
	bullet.collision_area.set_scale(custom_collision_sizes)
	bullet.global_position = shooter.global_position
	bullet.shake = cameraShakeAmount
	if !GameManager.is_in_lobby:
		GlobalWorld.projectiles.add_child(bullet)
	else:
		GlobalPlayer.player.get_parent().add_child(bullet)
	var data := {
		"bullet": bullet,
		"angle": randf() * TAU,
		"radius": randf_range(ORBIT_RADIUS_MIN, ORBIT_RADIUS_MAX),
		"speed": ORBIT_SPEED * randf_range(0.8, 1.2),
		"elapsed": 0.0,
	}
	_orbitals.append(data)
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount * 0.5)

func _process(delta: float) -> void:
	super._process(delta)
	var to_remove: Array = []
	for orb in _orbitals:
		if not is_instance_valid(orb["bullet"]):
			to_remove.append(orb)
			continue
		orb["elapsed"] += delta
		orb["angle"] += orb["speed"] * delta
		var b = orb["bullet"]
		b.global_position = shooter.global_position + Vector2(cos(orb["angle"]), sin(orb["angle"])) * orb["radius"]
		b.rotation = orb["angle"]
		b.velocity = Vector2.ZERO
	for r in to_remove:
		_orbitals.erase(r)
