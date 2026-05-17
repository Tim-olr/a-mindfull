extends Weapon
class_name PickaxeWeapon

@export var tool_damage: float = 10.0
@export var swing_range: float = 80.0

func _ready() -> void:
	super._ready()
	gun = false
	shootCooldown = 0.8

func perform_attack() -> void:
	if not isSelected:
		return
	shooter.stats.canAttack = false
	attack_cooldown.set_wait_time(shooter.stats.attackSpeed + shootCooldown)
	attack_cooldown.start()
	_swing()

func _swing() -> void:
	var swing_pos: Vector2
	if shooter != null and shooter.is_in_group("player"):
		swing_pos = GlobalPlayer.manager.weapon_marker.global_position
		GlobalPlayer.camera.apply_shake(5.0)
	else:
		swing_pos = global_position

	for node in get_tree().get_nodes_in_group("physics_object"):
		if node is PhysicsObject and is_instance_valid(node):
			if node.global_position.distance_to(swing_pos) <= swing_range:
				node.damage(tool_damage, 1)
