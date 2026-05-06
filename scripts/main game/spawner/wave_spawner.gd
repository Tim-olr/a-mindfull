extends Node2D
class_name WaveSpawner1

@export var biome: Biome
@onready var wave_timer: Timer = $WaveTimer

var _rng := RandomNumberGenerator.new()

func setup(b: Biome, seed_val: int = 0) -> void:
	biome = b
	if seed_val != 0:
		_rng.seed = seed_val

func _ready() -> void:
	if biome == null or biome.enemy_pool.is_empty():
		return
	_schedule_next_wave()

func _schedule_next_wave() -> void:
	var wait := _rng.randf_range(biome.wave_interval_min, biome.wave_interval_max)
	wave_timer.start(wait)

func _spawn_wave() -> void:
	var player = GlobalPlayer.player
	if player == null:
		return
	if biome == null or biome.enemy_pool.is_empty():
		return
	var count_mult: float = FahrerDeck.enemy_count_mult()
	if count_mult <= 0.0:
		return  # Queen of Spades — no enemies this run
	var count := int(round(_rng.randi_range(biome.enemies_per_wave_min, biome.enemies_per_wave_max) * count_mult))
	if count <= 0:
		return
	var parent: Node = GlobalWorld.theWorld
	if parent == null:
		parent = get_parent()
	for i in count:
		var scene: PackedScene = biome.enemy_pool[_rng.randi() % biome.enemy_pool.size()]
		if scene == null:
			continue
		var enemy = scene.instantiate()
		var angle := _rng.randf() * TAU
		var pos = player.global_position + Vector2(cos(angle), sin(angle)) * biome.spawn_radius
		enemy.global_position = pos
		parent.add_child.call_deferred(enemy)
		await get_tree().process_frame

func _on_wave_timer_timeout() -> void:
	_spawn_wave()
	_schedule_next_wave()
