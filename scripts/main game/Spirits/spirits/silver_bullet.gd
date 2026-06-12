extends Spirit

func apply_passive():
	if is_instance_valid(GlobalPlayer.manager.get_weapon()):
		GlobalPlayer.manager.get_weapon().projectileSpeedMod *= 1.35

func remove_passive():
	if is_instance_valid(GlobalPlayer.manager.get_weapon()):
		GlobalPlayer.manager.get_weapon().projectileSpeedMod /= 1.35

func active_ability():
	if canAbility:
		if is_instance_valid(GlobalPlayer.manager.get_weapon()):
			ability_duration_timed_out.start(abilityDuration)
			GlobalPlayer.manager.get_weapon().projectileSpeedMod *= 1.50
			GlobalPlayer.manager.get_weapon().damageMod *= 1.25
			active_ability_timer.start(get_effective_cooldown())
			canAbility = false

func remove_ability():
	if is_instance_valid(GlobalPlayer.manager.get_weapon()):
		GlobalPlayer.manager.get_weapon().projectileSpeedMod /= 1.50
		GlobalPlayer.manager.get_weapon().damageMod /= 1.25
