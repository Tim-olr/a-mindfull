extends Node2D
class_name EnemySpawner

const ARDY = preload("uid://vmce3i1bf5v1")
const BARTHOLOMEW = preload("uid://dg08cdh3iur8r")
const BONKUS = preload("uid://cioco2pfro1aw")

@export var enemy_pool: Array[PackedScene]
@export var enemy_amount: int
@export var enemy_amount_range: Vector2
@export var do_en_amount_range: bool = true

func _ready() -> void:
	if enemy_pool.is_empty():
		put_enemies()
	check_zero()
	random_enemy_amount()
	spawn_enemies()

func put_enemies():
	enemy_pool.append(BONKUS)
	enemy_pool.append(ARDY)
	enemy_pool.append(BARTHOLOMEW)

func check_zero():
	if enemy_amount_range == Vector2.ZERO or enemy_amount_range.y == 0:
		enemy_amount_range.x = randi_range(1, 3)
		enemy_amount_range.y = randi_range(3, 6)
	if enemy_amount == 0:
		random_enemy_amount()

func set_random_values():
	enemy_amount_range.x = randi_range(1, 10)
	enemy_amount_range.y = randi_range(10, 20)
	do_en_amount_range = randi_range(0, 1)

func random_enemy_amount():
	if do_en_amount_range:
		enemy_amount = randi_range(enemy_amount_range.x, enemy_amount_range.y)

func spawn_enemies():
	for m in enemy_amount:
		var enemy = enemy_pool.pick_random()
		var enemy_scene : Enemy = enemy.instantiate()
		enemy_scene.global_position = global_position
		GlobalPlayer.player.get_parent().add_child.call_deferred(enemy_scene)
		await get_tree().process_frame
		await get_tree().process_frame
