extends ArtifactResource

# Tracks what this artifact has contributed so it can be cleanly reversed.
var _kb_added: float = 0.0
var _speed_mult: float = 1.0

func on_stack_added() -> void:
	var kb  := 0.3 if stacks == 1 else 0.1
	var spd := 0.9 if stacks == 1 else 0.95
	_kb_added += kb
	_speed_mult *= spd
	GlobalPlayer.manager.knockback_resistance += kb
	GlobalPlayer.stats.speed *= spd

func on_stack_removed() -> void:
	# Always removes a subsequent-stack increment (+10% KB, -5% speed).
	_kb_added -= 0.1
	_speed_mult /= 0.95
	GlobalPlayer.manager.knockback_resistance -= 0.1
	GlobalPlayer.stats.speed /= 0.95

func on_all_removed() -> void:
	GlobalPlayer.manager.knockback_resistance -= _kb_added
	GlobalPlayer.stats.speed /= _speed_mult
	reset_tracking()

func reset_tracking() -> void:
	_kb_added = 0.0
	_speed_mult = 1.0
