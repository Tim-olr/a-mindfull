extends FahrerCard

func apply() -> void:
	GlobalPlayer.stats.attackDamage *= 0.5

func remove() -> void:
	GlobalPlayer.stats.attackDamage /= 0.5
