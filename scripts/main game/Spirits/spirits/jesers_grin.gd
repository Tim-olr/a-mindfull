extends Spirit

const JESTERS_GRIN_BOMB = preload("uid://bhlmdcdtc0aiy")

func apply_passive():
	GlobalPlayer.stats.do_more_damage_to_enemies_with_hp_percent = true
	GlobalPlayer.stats.enemy_health_percentage_min = 90
	GlobalPlayer.stats.damage_mult_for_dmdtewhp = 1.3

func remove_passive():
	GlobalPlayer.stats.do_more_damage_to_enemies_with_hp_percent = false
	GlobalPlayer.stats.enemy_health_percentage_min = 100
	GlobalPlayer.stats.damage_mult_for_dmdtewhp = 0.0

func active_ability():
	if canAbility:
		var bomb = JESTERS_GRIN_BOMB.instantiate()
		bomb.global_position = self.global_position
		GlobalWorld.theWorld.add_child(bomb)
		ability_duration_timed_out.start(abilityDuration)
		active_ability_timer.start(activeAbilityCooldown)
		canAbility = false
