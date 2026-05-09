extends Weapon

var _ring_active := false
var _ring_bullets: Array = []
const RING_RADIUS := 50.0
const RING_BULLET_COUNT := 12
const RING_SPIN_SPEED := 3.0
const RING_DURATION := 3.0
var _ring_elapsed := 0.0

func perform_attack() -> void:
	if _ring_active:
		return
	if !has_no_cooldown:
		shooter.stats.canAttack = false
		attack_cooldown.set_wait_time(shooter.stats.attackSpeed + shootCooldown + RING_DURATION)
		attack_cooldown.start()
	_spawn_ring()

func _spawn_ring() -> void:
	_ring_active = true
	_ring_elapsed = 0.0
	_ring_bullets.clear()
	var attack_damage: float = shooter.stats.attackDamage + damageMod + rarity_damage
	for i in range(RING_BULLET_COUNT):
		var bullet = bulletScene.instantiate()
		if shooter.is_in_group("player"):
			bullet.shooter_group = "player"
		elif shooter.is_in_group("enemy"):
			bullet.shooter_group = "enemy"
		bullet.knockback_force = knockback_force
		bullet.hasInfPierce = true
		bullet.canKeepTicking = true
		bullet.tick_interval = 0.3
		bullet.rot = 0
		bullet.rotation = 0
		bullet.projectileSpeed = 0
		bullet.pierce = 999
		bullet.damage = attack_damage * 0.3
		bullet.lifetime = RING_DURATION + 1.0
		bullet.collision_area.set_scale(custom_collision_sizes)
		bullet.global_position = shooter.global_position
		bullet.shake = 0
		bullet.scale = Vector2(0.7, 0.7)
		if !GameManager.is_in_lobby:
			GlobalWorld.projectiles.add_child(bullet)
		else:
			GlobalPlayer.player.get_parent().add_child(bullet)
		_ring_bullets.append(bullet)
	if shooter.is_in_group("player"):
		GlobalPlayer.camera.apply_shake(cameraShakeAmount)

func _process(delta: float) -> void:
	super._process(delta)
	if not _ring_active:
		return
	_ring_elapsed += delta
	if _ring_elapsed >= RING_DURATION:
		_ring_active = false
		for b in _ring_bullets:
			if is_instance_valid(b):
				b.queue_free()
		_ring_bullets.clear()
		return
	for i in range(_ring_bullets.size()):
		var b = _ring_bullets[i]
		if not is_instance_valid(b):
			continue
		var angle := (float(i) / RING_BULLET_COUNT) * TAU + _ring_elapsed * RING_SPIN_SPEED
		b.global_position = shooter.global_position + Vector2(cos(angle), sin(angle)) * RING_RADIUS
		b.rotation = angle + PI / 2.0
		b.velocity = Vector2.ZERO
