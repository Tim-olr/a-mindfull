extends Spirit

func apply_passive():
	GlobalPlayer.stats.damage_reduction += 0.2

func remove_passive():
	GlobalPlayer.stats.damage_reduction -= 0.2
