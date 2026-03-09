extends Spirit

func apply_passive():
	weapo.do_more_damage_to_enemies_with_hp_percent = true
	weapo.enemy_health_percentage_min = 90
	weapo.damage_mult_for_dmdtewhp = 1.3

func remove_passive():
	weapo.do_more_damage_to_enemies_with_hp_percent = false
	weapo.enemy_health_percentage_min = 100
	weapo.damage_mult_for_dmdtewhp = 0.0
