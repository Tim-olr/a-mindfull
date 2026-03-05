extends Spirit

@export var follow_speed: float = 1000.0
@export var max_radius: float = 200.0
@onready var healing_checker: Area2D = $HealingChecker

func _physics_process(delta: float) -> void:
	if not host:
		return
	var target_position = get_global_mouse_position() - Vector2(0, 10)
	var direction_from_player = target_position - host.global_position
	if direction_from_player.length() > max_radius:
		direction_from_player = direction_from_player.normalized() * max_radius
		target_position = host.global_position + direction_from_player
	global_position = global_position.move_toward(target_position, follow_speed * delta)

func apply_passive():
	GlobalPlayer.stats.hps += 1
	GlobalPlayer.manager.canHps = true

func remove_passive():
	GlobalPlayer.stats.hps -= 1
	GlobalPlayer.manager.canHps = false

func active_ability():
	if canAbility:
		var overlappers = healing_checker.get_overlapping_bodies()
		var healAmount := 50.0
		var healingPerBody = healAmount / overlappers.size()
		for b in overlappers:
			if b.is_in_group("player"):
				b.manager.heal(healingPerBody)
			if b.is_in_group("physics_object"):
				b.heal(healingPerBody)
		active_ability_timer.start(activeAbilityCooldown)
		canAbility = false
