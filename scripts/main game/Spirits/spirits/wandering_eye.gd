extends Spirit

const BULLET_DEFLECTOR = preload("res://scenes/Physics objects/spirits/bullet_deflector.tscn")

var _deflector_instance: Node = null
var _original_player_scale: Vector2 = Vector2.ONE

func apply_passive() -> void:
	_original_player_scale = GlobalPlayer.player.scale
	GlobalPlayer.stats.speed   *= 1.30
	GlobalPlayer.specials.size_player(Vector2(0.65, 0.65))

func remove_passive() -> void:
	GlobalPlayer.stats.speed  /= 1.30
	GlobalPlayer.specials.size_player(_original_player_scale)

func active_ability() -> void:
	if not canAbility:
		return
	if is_instance_valid(_deflector_instance):
		_deflector_instance.queue_free()
	_deflector_instance = BULLET_DEFLECTOR.instantiate()
	# Attach to player so the deflection field follows the player
	GlobalPlayer.player.add_child(_deflector_instance)
	ability_duration_timed_out.start(abilityDuration)
	active_ability_timer.start(get_effective_cooldown())
	canAbility = false

func remove_ability() -> void:
	if is_instance_valid(_deflector_instance):
		_deflector_instance.queue_free()
	_deflector_instance = null
