extends Spirit

func apply_passive():
	GlobalPlayer.stats.dashAmount *= 2.5

func remove_passive():
	GlobalPlayer.stats.dashAmount /= 2.5

func active_ability():
	if canAbility:
		ability_duration_timed_out.start(abilityDuration)
		weapo.projectileSpeedMod *= 5
		GlobalPlayer.visuals.show_blue()
		GlobalPlayer.specials.change_game_speed(0.5)
		GlobalPlayer.stats.dashAmount /= 2
		active_ability_timer.start(get_effective_cooldown())
		canAbility = false

func remove_ability():
	GlobalPlayer.specials.change_game_speed()
	weapo.projectileSpeedMod /= 5
	GlobalPlayer.stats.dashAmount *= 2
	GlobalPlayer.visuals.hide_blue()
