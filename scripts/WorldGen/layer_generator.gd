extends Node2D

@export var layers: int = 0
@export var world_size := Vector2i(0, 0)
@export var grass_layer := 0
@export var dirt_layers: Vector2i
@export var deep_rock_layer := 0
@export var build_height: int = 10
@export var mineable_blocks: Array[MineableBlockResource] = []

var all_layers: Array[TileMapLayer] = []
var build_layers: Dictionary = {}
var building_system: BuildingSystem = null
var mining_system: MiningSystem = null
var ui_canvas: CanvasLayer
var coord_label: Label
var current_layer_y: int = 5
var step_cooldown: float = 0.0

var _mineable_lookup: Dictionary = {}
var _step_up_sensor: ShapeCast2D = null
var _step_down_sensor: ShapeCast2D = null

@onready var my_tile_set: TileSet = preload("uid://b6lj4tdjvbmsg")
const TileMapCoords = preload("uid://crje5ylxrljml")

const LAYER_SPACING := -160
const TILE_PIXEL_SIZE := 32
const TILE_PIXEL_HEIGHT := 16
const TILE_SCALE := 10
const STEP_COOLDOWN_TIME := 0.3
const DEPTH_DARKEN_STEP := 0.12
const DEPTH_LIGHTEN_STEP := 0.06

const PHYSICS_LAYER_WALKABLE := 0
const PHYSICS_LAYER_STEP_UP := 1
const PHYSICS_LAYER_STEP_DOWN := 2
const PHYSICS_LAYER_WALL := 3

const COLLISION_BIT_WALKABLE := 1
const COLLISION_BIT_STEP_UP := 2
const COLLISION_BIT_STEP_DOWN := 4
const COLLISION_BIT_WALL := 8

func _ready() -> void:
	add_to_group("world_gen")
	_setup_building_system()
	_setup_mining_system()
	_build_mineable_lookup()
	_setup_tileset_physics_layers()
	generate()
	create_coord_display()
	await get_tree().process_frame
	await get_tree().process_frame
	spawn_player_on_layer(5)

func _setup_building_system() -> void:
	building_system = BuildingSystem.new()
	add_child(building_system)

func _setup_mining_system() -> void:
	mining_system = MiningSystem.new()
	add_child(mining_system)

func _build_mineable_lookup() -> void:
	_mineable_lookup.clear()
	for block in mineable_blocks:
		var key := _block_key(block.source_id, block.atlas_coord)
		_mineable_lookup[key] = block

func _block_key(source_id: int, atlas_coord: Vector2i) -> String:
	return "%d_%d_%d" % [source_id, atlas_coord.x, atlas_coord.y]

func get_mineable_block(source_id: int, atlas_coord: Vector2i) -> MineableBlockResource:
	var key := _block_key(source_id, atlas_coord)
	return _mineable_lookup.get(key, null)

func _setup_tileset_physics_layers() -> void:
	var ts := my_tile_set
	while ts.get_physics_layers_count() < 4:
		ts.add_physics_layer()

	ts.set_physics_layer_collision_layer(PHYSICS_LAYER_WALKABLE, COLLISION_BIT_WALKABLE)
	ts.set_physics_layer_collision_mask(PHYSICS_LAYER_WALKABLE, COLLISION_BIT_WALKABLE)

	ts.set_physics_layer_collision_layer(PHYSICS_LAYER_STEP_UP, COLLISION_BIT_STEP_UP)
	ts.set_physics_layer_collision_mask(PHYSICS_LAYER_STEP_UP, 0)

	ts.set_physics_layer_collision_layer(PHYSICS_LAYER_STEP_DOWN, COLLISION_BIT_STEP_DOWN)
	ts.set_physics_layer_collision_mask(PHYSICS_LAYER_STEP_DOWN, 0)

	ts.set_physics_layer_collision_layer(PHYSICS_LAYER_WALL, COLLISION_BIT_WALL)
	ts.set_physics_layer_collision_mask(PHYSICS_LAYER_WALL, 0)

	var top_face := PackedVector2Array([
		Vector2(16, 0), Vector2(32, 8), Vector2(16, 16), Vector2(0, 8)
	])
	var step_up_poly := PackedVector2Array([
		Vector2(16, 0), Vector2(32, 8), Vector2(16, 8), Vector2(0, 8)
	])
	var step_down_poly := PackedVector2Array([
		Vector2(0, 8), Vector2(16, 8), Vector2(32, 8), Vector2(16, 16)
	])
	var wall_poly := PackedVector2Array([
		Vector2(0, 8), Vector2(16, 16), Vector2(32, 8),
		Vector2(32, 24), Vector2(16, 32), Vector2(0, 24)
	])
	var step_up_bl := PackedVector2Array([
		Vector2(0, 8), Vector2(8, 12), Vector2(16, 16), Vector2(16, 8)
	])
	var step_up_br := PackedVector2Array([
		Vector2(16, 8), Vector2(16, 16), Vector2(24, 12), Vector2(32, 8)
	])

	var stepable_coords := [Vector2i(0, 0), Vector2i(1, 0)]
	var wall_coords := [Vector2i(2, 0)]

	for si in range(ts.get_source_count()):
		var src_id := ts.get_source_id(si)
		var src := ts.get_source(src_id) as TileSetAtlasSource
		if src == null:
			continue

		for tc in stepable_coords:
			if not src.has_tile(tc):
				continue
			var td := src.get_tile_data(tc, 0)
			if td == null:
				continue
			for li in range(4):
				while td.get_collision_polygons_count(li) > 0:
					td.remove_collision_polygon(li, 0)
			td.add_collision_polygon(PHYSICS_LAYER_WALKABLE)
			td.set_collision_polygon_points(PHYSICS_LAYER_WALKABLE, 0, top_face)
			td.add_collision_polygon(PHYSICS_LAYER_STEP_UP)
			td.set_collision_polygon_points(PHYSICS_LAYER_STEP_UP, 0, step_up_poly)
			td.add_collision_polygon(PHYSICS_LAYER_STEP_DOWN)
			td.set_collision_polygon_points(PHYSICS_LAYER_STEP_DOWN, 0, step_down_poly)
			td.add_collision_polygon(PHYSICS_LAYER_STEP_UP)
			td.set_collision_polygon_points(PHYSICS_LAYER_STEP_UP, 1, step_up_bl)
			td.add_collision_polygon(PHYSICS_LAYER_STEP_UP)
			td.set_collision_polygon_points(PHYSICS_LAYER_STEP_UP, 2, step_up_br)

		for tc in wall_coords:
			if not src.has_tile(tc):
				continue
			var td := src.get_tile_data(tc, 0)
			if td == null:
				continue
			for li in range(4):
				while td.get_collision_polygons_count(li) > 0:
					td.remove_collision_polygon(li, 0)
			td.add_collision_polygon(PHYSICS_LAYER_WALKABLE)
			td.set_collision_polygon_points(PHYSICS_LAYER_WALKABLE, 0, top_face)
			td.add_collision_polygon(PHYSICS_LAYER_WALL)
			td.set_collision_polygon_points(PHYSICS_LAYER_WALL, 0, wall_poly)

func _create_step_sensors() -> void:
	if GlobalPlayer == null or GlobalPlayer.player == null:
		return

	var sensor_radius_up := TILE_PIXEL_SIZE * TILE_SCALE * 0.25
	var sensor_radius_down := TILE_PIXEL_SIZE * TILE_SCALE * 0.25
	var cast_distance := TILE_PIXEL_HEIGHT * TILE_SCALE * 0.6

	if _step_up_sensor == null:
		_step_up_sensor = ShapeCast2D.new()
		_step_up_sensor.name = "StepUpSensor"
		var s := CircleShape2D.new()
		s.radius = sensor_radius_up
		_step_up_sensor.shape = s
		_step_up_sensor.collision_mask = COLLISION_BIT_STEP_UP
		_step_up_sensor.target_position = Vector2(0, -cast_distance)
		_step_up_sensor.collide_with_bodies = true
		_step_up_sensor.collide_with_areas = false
		_step_up_sensor.enabled = true
		GlobalPlayer.player.add_child(_step_up_sensor)

	if _step_down_sensor == null:
		_step_down_sensor = ShapeCast2D.new()
		_step_down_sensor.name = "StepDownSensor"
		var s2 := CircleShape2D.new()
		s2.radius = sensor_radius_down
		_step_down_sensor.shape = s2
		_step_down_sensor.collision_mask = COLLISION_BIT_STEP_DOWN
		_step_down_sensor.target_position = Vector2(0, cast_distance)
		_step_down_sensor.collide_with_bodies = true
		_step_down_sensor.collide_with_areas = false
		_step_down_sensor.enabled = true
		GlobalPlayer.player.add_child(_step_down_sensor)

func _tile_is_step_able(layer: TileMapLayer, cell: Vector2i) -> bool:
	var source_id := layer.get_cell_source_id(cell)
	if source_id == -1:
		return false
	var atlas_coord := layer.get_cell_atlas_coords(cell)
	var alt_id := layer.get_cell_alternative_tile(cell)
	var src := my_tile_set.get_source(source_id) as TileSetAtlasSource
	if src == null:
		return false
	var td := src.get_tile_data(atlas_coord, alt_id)
	if td == null:
		return false
	return td.get_collision_polygons_count(PHYSICS_LAYER_STEP_UP) > 0

func _process(delta: float) -> void:
	if step_cooldown > 0.0:
		step_cooldown -= delta
	else:
		check_layer_transition()
	update_coords_from_current_layer()
	update_coord_display()

func _update_layer_depth_shading() -> void:
	for layer in all_layers:
		var diff := int(layer.y_cord) - current_layer_y
		var brightness: float
		if diff == 0:
			brightness = 1.0
		elif diff > 0:
			brightness = clamp(1.0 + diff * DEPTH_LIGHTEN_STEP, 1.0, 1.5)
		else:
			brightness = clamp(1.0 + diff * DEPTH_DARKEN_STEP, 0.1, 1.0)
		layer.modulate = Color(brightness, brightness, brightness, 1.0)

func get_layer_by_y(y) -> TileMapLayer:
	for l in all_layers:
		if int(l.y_cord) == int(y):
			return l
	return null

func get_highest_layer_y() -> int:
	var highest := 0
	for l in all_layers:
		if int(l.y_cord) > highest:
			highest = int(l.y_cord)
	for y in build_layers:
		if int(y) > highest:
			highest = int(y)
	return highest

func get_or_create_build_layer(y_cord: int) -> TileMapLayer:
	var existing := get_layer_by_y(y_cord)
	if existing != null:
		return existing
	var highest := get_highest_layer_y()
	if y_cord > highest + build_height:
		return null
	var new_layer := TileMapLayer.new()
	new_layer.tile_set = my_tile_set
	new_layer.scale = Vector2(TILE_SCALE, TILE_SCALE)
	new_layer.y_sort_enabled = true
	new_layer.position.y = y_cord * LAYER_SPACING
	new_layer.z_index = y_cord
	new_layer.set_script(TileMapCoords)
	new_layer.y_cord = y_cord
	add_child(new_layer)
	all_layers.append(new_layer)
	build_layers[y_cord] = new_layer
	return new_layer

func get_tile_world_y(layer: TileMapLayer, cell: Vector2i) -> float:
	return layer.to_global(layer.map_to_local(cell)).y

func spawn_player_on_layer(y_cord: int) -> void:
	if GlobalPlayer == null or GlobalPlayer.player == null:
		return
	var target_layer := get_layer_by_y(y_cord)
	if target_layer == null:
		return
	current_layer_y = y_cord
	var center_cell := Vector2i(world_size.x / 2, world_size.y / 2)
	var tile_world_y := get_tile_world_y(target_layer, center_cell)
	GlobalPlayer.player.global_position.y = tile_world_y
	GlobalPlayer.player.z_index = y_cord + 1
	GlobalPlayer.coordinates.y = y_cord
	_create_step_sensors()
	_update_layer_depth_shading()

func check_layer_transition() -> void:
	if GlobalPlayer == null or GlobalPlayer.player == null:
		return
	var player_pos := GlobalPlayer.player.global_position
	var target_y := _find_target_layer_y(player_pos)
	if target_y == -1 or target_y == current_layer_y:
		return
	transition_to_layer(target_y)

func _find_target_layer_y(player_pos: Vector2) -> int:
	var current_layer := get_layer_by_y(current_layer_y)
	if current_layer == null:
		return -1

	var layer_above := get_layer_by_y(current_layer_y + 1)
	if layer_above != null:
		var cell_above := layer_above.local_to_map(layer_above.to_local(player_pos))
		if layer_above.get_cell_tile_data(cell_above) != null:
			if not _tile_is_step_able(layer_above, cell_above):
				return current_layer_y
			if _step_up_sensor != null and _step_up_sensor.is_inside_tree():
				_step_up_sensor.force_shapecast_update()
				if _step_up_sensor.is_colliding():
					return current_layer_y + 1
			return current_layer_y

	var cell_current := current_layer.local_to_map(current_layer.to_local(player_pos))
	if current_layer.get_cell_tile_data(cell_current) != null:
		return current_layer_y

	if _step_down_sensor != null and _step_down_sensor.is_inside_tree():
		_step_down_sensor.force_shapecast_update()
		if _step_down_sensor.is_colliding():
			var check_y := current_layer_y - 1
			var layer_below := get_layer_by_y(check_y)
			if layer_below != null:
				var cell_below := layer_below.local_to_map(layer_below.to_local(player_pos))
				if layer_below.get_cell_tile_data(cell_below) != null:
					return check_y

	for diff in range(1, current_layer_y + 1):
		var check_y := current_layer_y - diff
		var layer_below := get_layer_by_y(check_y)
		if layer_below == null:
			continue
		var cell_below := layer_below.local_to_map(layer_below.to_local(player_pos))
		if layer_below.get_cell_tile_data(cell_below) != null:
			return check_y

	return -1

func transition_to_layer(y_cord: int) -> void:
	var target_layer := get_layer_by_y(y_cord)
	if target_layer == null:
		return
	current_layer_y = y_cord
	GlobalPlayer.player.z_index = y_cord + 1
	GlobalPlayer.stats.playerSpiritScene.z_index = y_cord + 1
	GlobalWorld.projectiles.z_index = y_cord + 2
	step_cooldown = STEP_COOLDOWN_TIME
	_update_layer_depth_shading()

func update_coords_from_current_layer() -> void:
	if GlobalPlayer == null or GlobalPlayer.player == null:
		return
	var current_layer := get_layer_by_y(current_layer_y)
	if current_layer == null:
		return
	var local_pos := current_layer.to_local(GlobalPlayer.player.global_position)
	var cell := current_layer.local_to_map(local_pos)
	GlobalPlayer.coordinates.x = int(cell.x)
	GlobalPlayer.coordinates.y = current_layer_y
	GlobalPlayer.coordinates.z = int(cell.y)

func create_coord_display() -> void:
	ui_canvas = CanvasLayer.new()
	ui_canvas.layer = 100
	add_child(ui_canvas)
	coord_label = Label.new()
	coord_label.position = Vector2(8, 8)
	coord_label.anchor_left = 0.0
	coord_label.anchor_top = 0.0
	coord_label.add_theme_font_size_override("font_size", 20)
	ui_canvas.add_child(coord_label)

func update_coord_display() -> void:
	if coord_label == null or GlobalPlayer == null:
		return
	var c := GlobalPlayer.coordinates
	if c == null:
		coord_label.text = ""
		return
	coord_label.text = "X: %d  Y: %d  Z: %d" % [int(c.x), int(c.y), int(c.z)]

func generate() -> void:
	if GlobalPlayer != null and GlobalPlayer.player != null:
		GlobalPlayer.player.z_index = layers + 1
	var index := 0
	for i in range(layers):
		index += 1
		var new_layer := TileMapLayer.new()
		new_layer.tile_set = my_tile_set
		new_layer.scale = Vector2(TILE_SCALE, TILE_SCALE)
		new_layer.y_sort_enabled = true
		var new_renderer := TilemapGaeaRenderer.new()
		var new_noise_gen := NoiseGenerator.new()
		var new_noise_settings := NoiseGeneratorSettings.new()
		var gen_data := NoiseGeneratorData.new()
		var tile_info := TilemapTileInfo.new()
		if index == grass_layer:
			gen_data.title = "Grass"
			tile_info.atlas_coord = Vector2i(0, 0)
			gen_data.min = 0
			gen_data.max = 1.0
		if index <= dirt_layers.x:
			if index >= dirt_layers.y:
				gen_data.title = "Dirt"
				tile_info.atlas_coord = Vector2i(1, 0)
				gen_data.min = -1.0
				gen_data.max = 1.0
		if index == deep_rock_layer:
			gen_data.title = "Deep Rock"
			tile_info.atlas_coord = Vector2i(2, 0)
			gen_data.min = -1.0
			gen_data.max = 1.0
		new_layer.position.y = i * LAYER_SPACING
		new_layer.z_index = i
		new_layer.set_script(TileMapCoords)
		new_layer.y_cord = i
		new_noise_settings.world_size = world_size
		gen_data.tile = tile_info
		new_noise_settings.tiles.append(gen_data)
		new_noise_gen.settings = new_noise_settings
		new_renderer.tile_map_layers.append(new_layer)
		new_renderer.generator = new_noise_gen
		add_child(new_renderer)
		add_child(new_noise_gen)
		add_child(new_layer)
		all_layers.append(new_layer)
