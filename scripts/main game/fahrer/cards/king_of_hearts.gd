extends FahrerCard

func apply() -> void:
	GlobalPlayer.stats.attackDamage *= 2.0

func remove() -> void:
	GlobalPlayer.stats.attackDamage /= 2.0
