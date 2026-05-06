extends Spirit

const DAYTIME_DAMAGE_BONUS: float = 1.30
const STUN_DURATION: float = 5.0
const STUN_RANGE: float = 800.0
const FRONT_OFFSET: float = 50.0

var _daytime_bonus_active: bool = false
var _stun_target: Node = null
var _stun_remaining: float = 0.0

# Attack is handled by the spirit weapon (LookAtYouWeapon, laser).

func apply_passive() -> void:
	_refresh_daytime_bonus()

func remove_passive() -> void:
	if _daytime_bonus_active:
		_set_weapon_damage_mod(1.0 / DAYTIME_DAMAGE_BONUS)
		_daytime_bonus_active = false

func _process(delta: float) -> void:
	super(delta)
	if out:
		_refresh_daytime_bonus()
	if _stun_target != null and is_instance_valid(_stun_target):
		_stun_remaining -= delta
		if _stun_remaining <= 0.0:
			_release_stun()

func _physics_process(delta: float) -> void:
	if out and _stun_target != null and is_instance_valid(_stun_target) and host != null:
		var to_player = (host.global_position - _stun_target.global_position).normalized()
		var target_pos: Vector2 = _stun_target.global_position + to_player * FRONT_OFFSET
		global_position = global_position.lerp(target_pos, smooth_speed * delta)
		return
	super(delta)

func _refresh_daytime_bonus() -> void:
	var is_day := DayNightCycle.is_daytime()
	if is_day and not _daytime_bonus_active:
		_set_weapon_damage_mod(DAYTIME_DAMAGE_BONUS)
		_daytime_bonus_active = true
	elif not is_day and _daytime_bonus_active:
		_set_weapon_damage_mod(1.0 / DAYTIME_DAMAGE_BONUS)
		_daytime_bonus_active = false

func _set_weapon_damage_mod(mult: float) -> void:
	# Modify our own spirit weapon's damageMod, not the player's weapon.
	if weapo != null and is_instance_valid(weapo):
		weapo.damageMod *= mult

func active_ability() -> void:
	if not canAbility:
		return
	var enemy := _find_closest_enemy()
	if enemy == null:
		return
	_stun_target = enemy
	_stun_remaining = STUN_DURATION
	if enemy.has_method("get") and enemy.get("canWalk") != null:
		enemy.canWalk = false
	if enemy.has_method("get") and enemy.get("attacking") != null:
		enemy.attacking = true
	ability_duration_timed_out.start(STUN_DURATION)
	active_ability_timer.start(activeAbilityCooldown)
	canAbility = false

func remove_ability() -> void:
	_release_stun()

func _release_stun() -> void:
	if _stun_target != null and is_instance_valid(_stun_target):
		if _stun_target.has_method("get") and _stun_target.get("canWalk") != null:
			_stun_target.canWalk = true
		if _stun_target.has_method("get") and _stun_target.get("attacking") != null:
			_stun_target.attacking = false
	_stun_target = null
	_stun_remaining = 0.0

func _find_closest_enemy() -> Node:
	var best: Node = null
	var best_d: float = STUN_RANGE * STUN_RANGE
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best
