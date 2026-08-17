extends Spirit

func apply_passive():
	GlobalPlayer.manager.canGetDamaged = false

func remove_passive():
	GlobalPlayer.manager.canGetDamaged = true

func active_ability():
	GlobalPlayer.manager.heal(GlobalPlayer.stats.maxHp / 2)
