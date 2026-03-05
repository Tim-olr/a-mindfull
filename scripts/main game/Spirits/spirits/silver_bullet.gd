extends Spirit

func attack():
	if canAttack:
		var bullet = set_projectile(projectile)
		if not bullet.get_parent():  
			GlobalWorld.projectiles.add_child(bullet)
		attack_cooldown_timer.start(attackCooldown)
		canAttack = false

func apply_passive():
	GlobalPlayer.manager.get_weapon().projectileSpeedMod *= 1.35

func remove_passive():
	GlobalPlayer.manager.get_weapon().projectileSpeedMod /= 1.35

func active_ability():
	if canAbility:
		ability_duration_timed_out.start(abilityDuration)
		GlobalPlayer.manager.get_weapon().projectileSpeedMod *= 1.50
		GlobalPlayer.manager.get_weapon().damageMod *= 1.25
		active_ability_timer.start(activeAbilityCooldown)
		canAbility = false

func remove_ability():
	GlobalPlayer.manager.get_weapon().projectileSpeedMod /= 1.50
	GlobalPlayer.manager.get_weapon().damageMod /= 1.25
