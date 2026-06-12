extends Spirit

const CHAIN_TRAP = preload("res://scenes/Physics objects/spirits/chain_trap.tscn")

var _trap_instance: Node = null

func apply_passive() -> void:
	GlobalPlayer.stats.speed        *= 1.30
	GlobalPlayer.stats.attackDamage *= 1.20

func remove_passive() -> void:
	GlobalPlayer.stats.speed        /= 1.30
	GlobalPlayer.stats.attackDamage /= 1.20

func active_ability() -> void:
	if not canAbility:
		return
	# Remove any existing trap first
	if is_instance_valid(_trap_instance):
		_trap_instance.deactivate()
	_trap_instance = CHAIN_TRAP.instantiate()
	_trap_instance.global_position = global_position
	GlobalPlayer.player.get_parent().add_child(_trap_instance)
	# Extra movement and damage bonuses while the trap is active
	GlobalPlayer.stats.speed        *= 1.15
	GlobalPlayer.stats.attackDamage *= 1.30
	ability_duration_timed_out.start(abilityDuration)
	active_ability_timer.start(get_effective_cooldown())
	canAbility = false

func remove_ability() -> void:
	GlobalPlayer.stats.speed        /= 1.15
	GlobalPlayer.stats.attackDamage /= 1.30
	if is_instance_valid(_trap_instance):
		_trap_instance.deactivate()
	_trap_instance = null
