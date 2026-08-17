extends ArtifactResource

const FACTOR := 1.15

var _total_mult: float = 1.0

func on_stack_added() -> void:
	_total_mult *= FACTOR
	var bonus := GlobalPlayer.stats.maxHp * (FACTOR - 1.0)
	GlobalPlayer.stats.maxHp += bonus
	GlobalPlayer.stats.hp += bonus
	GlobalPlayer.stats.hp_changed()

func on_stack_removed() -> void:
	var old_max := GlobalPlayer.stats.maxHp
	var new_max := old_max / FACTOR
	var ratio := GlobalPlayer.stats.hp / old_max
	GlobalPlayer.stats.maxHp = new_max
	GlobalPlayer.stats.hp = minf(ratio * new_max, new_max)
	_total_mult /= FACTOR
	GlobalPlayer.stats.hp_changed()

func on_all_removed() -> void:
	var old_max := GlobalPlayer.stats.maxHp
	var new_max := old_max / _total_mult
	var ratio := GlobalPlayer.stats.hp / old_max
	GlobalPlayer.stats.maxHp = new_max
	GlobalPlayer.stats.hp = minf(ratio * new_max, new_max)
	GlobalPlayer.stats.hp_changed()
	reset_tracking()

func reset_tracking() -> void:
	_total_mult = 1.0
