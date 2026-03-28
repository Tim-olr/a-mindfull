extends Node2D

@export var enemy_pool: Array[PackedScene]
@export var enemy_amount: int

func _ready() -> void:
	spawn_enemies()

func spawn_enemies():
	for m in enemy_amount:
		var enemy = enemy_pool.pick_random()
		var enemy_scene : Enemy = enemy.instantiate()
		enemy_scene.global_position = global_position
		GlobalPlayer.player.get_parent().add_child.call_deferred(enemy_scene)
		await get_tree().process_frame
		await get_tree().process_frame
