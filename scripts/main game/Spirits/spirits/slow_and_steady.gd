extends Spirit

func apply_passive():
	GlobalPlayer.stats.dashAmount *= 2.5

func remove_passive():
	GlobalPlayer.stats.dashAmount /= 2.5

func active_ability():
	if canAbility:
		ability_duration_timed_out.start(abilityDuration)
		weapo.projectileSpeedMod *= 3
		GlobalPlayer.visuals.show_blue()
		GlobalPlayer.specials.change_game_speed(0.5)
		active_ability_timer.start(activeAbilityCooldown)
		canAbility = false

func remove_ability():
	GlobalPlayer.specials.change_game_speed()
	weapo.projectileSpeedMod /= 3
	GlobalPlayer.visuals.hide_blue()
