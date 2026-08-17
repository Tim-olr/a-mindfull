extends Spirit

@onready var ring = preload("uid://sishtvgipl3e")

var ring_scene

func apply_passive():
	GlobalPlayer.stats.damage_reduction += 0.2

func remove_passive():
	GlobalPlayer.stats.damage_reduction -= 0.2

func _ready() -> void:
	super()
	ring_scene = ring.instantiate()
	ring_scene.attackable = false
	add_child(ring_scene)

func active_ability():
	if canAbility:
		ability_duration_timed_out.start(abilityDuration)
		ring_scene.shoot()
		active_ability_timer.start(get_effective_cooldown())
		canAbility = false
