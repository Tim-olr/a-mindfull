extends Node2D

@export var world_width: int = 128
@export var world_height: int = 64
@export var tile_size: Vector2i = Vector2i(64, 32)
@export var world_seed: int = 0
@export var elevation_scale: float = 0.04
@export var moisture_scale: float = 0.03
@export var water_level: float = 0.35
@export var max_elevation_layers: int = 5
@export var biomes: Array[BiomeResource] = []
@export var fallback_block: BlockResource
@export var water_block: BlockResource
@export var water_atlas_source: int = 0
@export var water_atlas_coords: Vector2i = Vector2i(0, 0)

@export var shadow_atlas_source: int = 0
@export var shadow_atlas_coords_soft: Vector2i = Vector2i(0, 2)
@export var shadow_atlas_coords_hard: Vector2i = Vector2i(1, 2)

@export var elev_layers: Array[NodePath] = []
var _elev_layers: Array[TileMapLayer] = []

@export var all_layers: Array[TileMapLayer] = []

@onready var layer_ground: TileMapLayer   = $TileMapLayer_Ground
@onready var layer_surface: TileMapLayer  = $TileMapLayer_Surface_0
@onready var layer_water: TileMapLayer    = $TileMapLayer_Water
@onready var layer_overlay: TileMapLayer  = $TileMapLayer_Overlay
@onready var blocks_node: Node2D          = $Blocks
@onready var decorations_node: Node2D     = $Decorations

var block_map: Dictionary = {}
var elevation_map: Dictionary = {}

var _elevation_noise: FastNoiseLite
var _moisture_noise: FastNoiseLite
var _rng: RandomNumberGenerator

signal block_broken(coord: Vector2i, block: BlockResource)


func _ready() -> void:
	for path in elev_layers:
		_elev_layers.append(get_node(path))
	generate()


func generate() -> void:
	_clear_world()
	_setup_noise()
	_generate_terrain()
	_generate_shadows()
	_generate_decorations()
	for l in all_layers:
		l.gen_collisions()
	print("[WorldGen] World generated. Seed: ", _rng.seed)


func _clear_world() -> void:
	layer_ground.clear()
	layer_surface.clear()
	layer_water.clear()
	layer_overlay.clear()
	for l in _elev_layers:
		l.clear()
	block_map.clear()
	elevation_map.clear()
	for child in blocks_node.get_children():
		child.queue_free()
	for child in decorations_node.get_children():
		child.queue_free()


func _setup_noise() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = world_seed if world_seed != 0 else randi()
	_elevation_noise = FastNoiseLite.new()
	_elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_elevation_noise.seed = _rng.randi()
	_elevation_noise.frequency = elevation_scale

	_moisture_noise = FastNoiseLite.new()
	_moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_moisture_noise.seed = _rng.randi()
	_moisture_noise.frequency = moisture_scale


func _generate_terrain() -> void:
	for x in range(world_width):
		for y in range(world_height):
			var coord := Vector2i(x, y)
			var elev_raw: float = (_elevation_noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			var moisture: float = (_moisture_noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			elevation_map[coord] = int(elev_raw * max_elevation_layers)
			if elev_raw < water_level:
				_place_water(coord)
			else:
				var normalized_elev: float = (elev_raw - water_level) / (1.0 - water_level)
				var biome: BiomeResource = _get_biome(normalized_elev, moisture)
				_place_land(coord, biome, normalized_elev, elev_raw)


func _generate_shadows() -> void:
	for coord in elevation_map:
		var my_elev: int = elevation_map[coord]
		var left_elev: int = elevation_map.get(coord + Vector2i(-1, 0), my_elev)
		var top_elev: int  = elevation_map.get(coord + Vector2i(0, -1), my_elev)
		var diff: int = max(left_elev, top_elev) - my_elev
		if diff >= 2:
			layer_overlay.set_cell(coord, shadow_atlas_source, shadow_atlas_coords_hard)
		elif diff == 1:
			layer_overlay.set_cell(coord, shadow_atlas_source, shadow_atlas_coords_soft)


func _place_water(coord: Vector2i) -> void:
	if water_block == null:
		return
	layer_water.set_cell(coord, water_atlas_source, water_atlas_coords)
	block_map[coord] = _make_block_data(coord, water_block)


func _place_land(coord: Vector2i, biome: BiomeResource, norm_elev: float, raw_elev: float) -> void:
	if biome == null:
		return

	var surface_block: BlockResource = biome.surface_block if biome.surface_block else fallback_block
	if surface_block == null:
		return

	var elev_int: int = elevation_map[coord]

	if not _elev_layers.is_empty():
		var target: TileMapLayer = _elev_layers[clamp(elev_int, 0, _elev_layers.size() - 1)]
		target.set_cell(coord, surface_block.atlas_source_id, surface_block.atlas_coords)
	else:
		var prev_coord := Vector2i(coord.x, coord.y + 1)
		var prev_elev: int = elevation_map.get(prev_coord, elev_int)
		if elev_int > prev_elev:
			layer_surface.set_cell(coord, surface_block.atlas_source_id,
				Vector2i(surface_block.atlas_coords.x + 1, surface_block.atlas_coords.y))
		else:
			layer_surface.set_cell(coord, surface_block.atlas_source_id, surface_block.atlas_coords)

	block_map[coord] = _make_block_data(coord, surface_block)


func _pick_subsurface(biome: BiomeResource, norm_elev: float) -> BlockResource:
	if biome.subsurface_blocks.is_empty():
		return biome.deep_block
	var idx: int = clamp(int(norm_elev * biome.subsurface_blocks.size()), 0, biome.subsurface_blocks.size() - 1)
	return biome.subsurface_blocks[idx]


func _get_biome(norm_elev: float, moisture: float) -> BiomeResource:
	var candidates: Array[BiomeResource] = []
	for biome in biomes:
		if (norm_elev >= biome.elevation_min and norm_elev <= biome.elevation_max
				and moisture >= biome.moisture_min and moisture <= biome.moisture_max):
			candidates.append(biome)
	if candidates.is_empty():
		return biomes[0] if not biomes.is_empty() else null
	return candidates[_rng.randi() % candidates.size()]


func _generate_decorations() -> void:
	for x in range(world_width):
		for y in range(world_height):
			var coord := Vector2i(x, y)
			if not block_map.has(coord):
				continue
			var bd: BlockData = block_map[coord]
			if bd.block.is_liquid:
				continue

			var elev_raw: float = (_elevation_noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			if elev_raw < water_level:
				continue

			var norm_elev: float = (elev_raw - water_level) / (1.0 - water_level)
			var moisture: float = (_moisture_noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			var biome: BiomeResource = _get_biome(norm_elev, moisture)

			if biome == null or biome.decoration_scenes.is_empty():
				continue
			if _rng.randf() < biome.decoration_chance:
				var scene: PackedScene = biome.decoration_scenes[_rng.randi() % biome.decoration_scenes.size()]
				var deco = scene.instantiate()
				deco.position = layer_surface.map_to_local(coord)
				decorations_node.add_child(deco)


func _make_block_data(coord: Vector2i, block: BlockResource) -> BlockData:
	var bd := BlockData.new()
	bd.coord = coord
	bd.block = block
	bd.hp = block.mine_time
	return bd


func mine_block(coord: Vector2i, delta: float, tool: String = "") -> float:
	if not block_map.has(coord):
		return -1.0
	var bd: BlockData = block_map[coord]
	if bd.block.required_tool != "" and tool != bd.block.required_tool:
		return 0.0
	bd.hp -= delta
	var progress: float = 1.0 - clamp(bd.hp / bd.block.mine_time, 0.0, 1.0)
	if bd.hp <= 0.0:
		_break_block(coord, bd)
		return 1.0
	return progress


func break_block(coord: Vector2i) -> void:
	if block_map.has(coord):
		_break_block(coord, block_map[coord])


func place_block(coord: Vector2i, block: BlockResource) -> void:
	layer_surface.set_cell(coord, block.atlas_source_id, block.atlas_coords)
	block_map[coord] = _make_block_data(coord, block)


func get_block(coord: Vector2i) -> BlockData:
	return block_map.get(coord, null)


func world_to_tile(world_pos: Vector2) -> Vector2i:
	return layer_surface.local_to_map(to_local(world_pos))


func _break_block(coord: Vector2i, bd: BlockData) -> void:
	block_map.erase(coord)
	layer_surface.erase_cell(coord)
	layer_water.erase_cell(coord)
	layer_overlay.erase_cell(coord)
	for l in _elev_layers:
		l.erase_cell(coord)
	emit_signal("block_broken", coord, bd.block)
