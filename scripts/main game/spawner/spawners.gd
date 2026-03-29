extends Node

@export var enemy_spawners: Array[PackedScene]
@export var world_size: Vector2
@export var enemy_pool_amount: int = 10

func _ready() -> void:
	spawn()

func spawn():
	for i in enemy_pool_amount:
		var spawner = enemy_spawners[randi() % enemy_spawners.size()].instantiate()
		spawner.position = Vector2(
			randf_range(-world_size.x, world_size.x),
			randf_range(-world_size.y, world_size.y)
		)
		GlobalPlayer.player.get_parent().add_child.call_deferred(spawner)
		print("lolo: ", spawner.global_position)
		await get_tree().process_frame
		await get_tree().process_frame
