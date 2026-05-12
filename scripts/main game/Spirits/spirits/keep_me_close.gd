extends Spirit

func apply_passive():
	GlobalPlayer.stats.dashAmount *= 2.5

func remove_passive():
	GlobalPlayer.stats.dashAmount /= 2.5

func active_ability():
	if !GlobalPlayer.specials.is_paused:
		if canAbility:
			sprites.play("active")
			ability_duration_timed_out.start(abilityDuration)
			GlobalPlayer.specials.pause_wo_player()
			GlobalPlayer.visuals.show_gray()
			active_ability_timer.start(activeAbilityCooldown)
			canAbility = false

func remove_ability():
	if GlobalPlayer.specials.is_paused:
		GlobalPlayer.specials.unpause_wo_player()
		GlobalPlayer.visuals.hide_gray()
