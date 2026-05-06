extends Node

@export var biomes: Array[Biome]
@export var world_size: Vector2i = Vector2i(100, 100)
@export var tile_map: TileMapLayer
@export var world_seed: int = 0  # 0 = random each run

@export_group("Spawn Parents")
@export var objects_node: Node
@export var shops_node: Node
@export var spawners_node: Node
@export var extraction_node: Node
@export var buildings_node: Node

const WAVE_SPAWNER = preload("res://scenes/main game/Spawner/wave_spawner.tscn")

var _rng := RandomNumberGenerator.new()

func _ready():
	spawn_world()

func spawn_world():
	if biomes.is_empty():
		return
	var actual_seed: int = world_seed if world_seed != 0 else randi()
	world_seed = actual_seed
	_rng.seed = actual_seed
	for b in biomes:
		if b.noise != null and b.noise.noise is FastNoiseLite:
			(b.noise.noise as FastNoiseLite).seed = actual_seed
	for b in biomes:
		await _generate_biome(b)
	_fix_empty_cells()
	for b in biomes:
		_spawn_biome_scenes(b)
	_spawn_wave_spawner()

func _spawn_wave_spawner():
	if biomes.is_empty():
		return
	var b: Biome = biomes[0]
	if b.enemy_pool.is_empty():
		return
	var spawner = WAVE_SPAWNER.instantiate()
	get_parent().add_child.call_deferred(spawner)
	spawner.setup(b, world_seed)

func _generate_biome(b: Biome):
	if b.noise == null or b.tile_set == null:
		return
	tile_map.tile_set = b.tile_set
	var image: Image = b.noise.get_image()
	if image == null:
		await b.noise.changed
		image = b.noise.get_image()
	if image == null:
		return
	var half := world_size / 2
	var terrain_cells: Dictionary = {}
	for x in range(-half.x, half.x):
		for y in range(-half.y, half.y):
			var px := int((float(x + half.x) / world_size.x) * image.get_width())
			var py := int((float(y + half.y) / world_size.y) * image.get_height())
			var noise_val: float = image.get_pixel(px, py).r
			var terrain = _pick_terrain(b.terrain_infos, noise_val)
			if terrain == null:
				continue
			if not terrain_cells.has(terrain.terrain_id):
				terrain_cells[terrain.terrain_id] = []
			terrain_cells[terrain.terrain_id].append(Vector2i(x, y))
	for terrain_id in terrain_cells:
		tile_map.set_cells_terrain_connect(terrain_cells[terrain_id], 0, terrain_id)

func _pick_terrain(terrains: Array[TerrainInfo], value: float) -> TerrainInfo:
	if terrains.is_empty():
		return null
	var slice := 1.0 / terrains.size()
	var index := int(value / slice)
	index = clampi(index, 0, terrains.size() - 1)
	return terrains[index]

func _fix_empty_cells():
	if biomes.is_empty():
		return
	var fallback_biome: Biome = biomes[0]
	if fallback_biome.terrain_infos.is_empty():
		return
	var fallback_terrain: TerrainInfo = fallback_biome.terrain_infos[fallback_biome.terrain_infos.size() - 1]
	var half := world_size / 2
	var empty_cells: Array[Vector2i] = []
	for x in range(-half.x, half.x):
		for y in range(-half.y, half.y):
			var cell := Vector2i(x, y)
			if tile_map.get_cell_tile_data(cell) == null:
				empty_cells.append(cell)
	if empty_cells.is_empty():
		return
	tile_map.set_cells_terrain_connect(empty_cells, 0, fallback_terrain.terrain_id)

func _spawn_biome_scenes(b: Biome):
	var half := world_size / 2
	_spawn_batch(b.physics_objects, b.min_objects,   b.max_objects,   objects_node,    half)
	_spawn_batch(b.biome_shops,     b.min_shops,     b.max_shops,     shops_node,      half)
	_spawn_batch(b.extraction_points, b.min_points,  b.max_points,    extraction_node, half)
	_spawn_batch(b.buildings,       b.min_buildings, b.max_buildings, buildings_node,  half)

func _spawn_batch(scenes: Array[PackedScene], min_count: int, max_count: int, parent: Node, half: Vector2i):
	if scenes.is_empty() or parent == null:
		return
	var count := _rng.randi_range(min_count, max_count)
	for i in count:
		var scene: PackedScene = scenes[_rng.randi() % scenes.size()]
		if scene == null:
			continue
		var instance = scene.instantiate()
		parent.add_child(instance)
		var tile := Vector2i(
			_rng.randi_range(-half.x, half.x - 1),
			_rng.randi_range(-half.y, half.y - 1)
		)
		instance.position = tile_map.map_to_local(tile)
