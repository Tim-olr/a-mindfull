extends Spirit

const ACTIVE_DAMAGE_OPTIONS: Array[float] = [0.0, 20.0, 50.0]

var _rng := RandomNumberGenerator.new()
var _active_fixed_damage: float = -1.0  # -1 = not in active mode

# Attack is handled by the spirit weapon (FollowTheWheelWeapon).
# Damage per shot is randomised in that weapon's perform_attack().

func modify_incoming_damage(amount: float, hit_on_spirit: bool) -> float:
	if not out:
		return amount
	if _active_fixed_damage >= 0.0:
		return _active_fixed_damage
	if hit_on_spirit:
		return amount * 2.0
	return amount * _rng.randf_range(0.2, 1.5)

func active_ability() -> void:
	if canAbility:
		_active_fixed_damage = ACTIVE_DAMAGE_OPTIONS[_rng.randi() % ACTIVE_DAMAGE_OPTIONS.size()]
		ability_duration_timed_out.start(abilityDuration)
		active_ability_timer.start(activeAbilityCooldown)
		canAbility = false

func remove_ability() -> void:
	_active_fixed_damage = -1.0
