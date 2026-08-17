extends Projectile
class_name SwapProjectile

func _check_overlaps() -> void:
	var overlapping := collision_area.get_overlapping_bodies()
	for body in overlapping:
		if body == null:
			continue
		if shooter_group != "" and body.is_in_group(shooter_group):
			continue
		if shooter_group == "player" and body.is_in_group("spirit"):
			continue
		if shooter_group == "spirit" and body.is_in_group("player"):
			continue
		if body.is_in_group("physics_object"):
			_do_swap(body)
			go_away()
			return
		if body.is_in_group("wall"):
			go_away()
			return

func _do_swap(physics_obj: Node2D) -> void:
	var player := GlobalPlayer.player
	if not is_instance_valid(player):
		return
	var player_pos := player.global_position
	var obj_pos := physics_obj.global_position
	player.global_position = obj_pos
	physics_obj.global_position = player_pos
	if physics_obj is RigidBody2D:
		physics_obj.linear_velocity = Vector2.ZERO
		physics_obj.angular_velocity = 0.0
