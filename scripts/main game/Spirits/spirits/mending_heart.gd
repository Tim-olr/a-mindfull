extends Spirit

@export var follow_speed: float = 1000.0
@export var max_radius: float = 200.0

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

func remove_passive():
	GlobalPlayer.stats.hps -= 1
