extends Node

@onready var pools: Node = $Pools
@onready var spawners: Node = $Spawners
@export var biomes: Array[Biome]
@export var world_size: Vector2i = Vector2i(100, 100)

func _ready():
	spawn_world()

func spawn_world():
	if biomes.is_empty():
		return
	for b in biomes:
		_generate_biome(b)

func _generate_biome(b: Biome):
	if b.noise == null or b.tile_set == null:
		return

	var tile_map := TileMapLayer.new()
	tile_map.tile_set = b.tile_set
	tile_map.scale = Vector2(9, 9)
	add_child(tile_map)

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
