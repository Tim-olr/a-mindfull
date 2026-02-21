extends Node2D

@export var layers: int = 0
@export var world_size := Vector2i(0, 0)
@export var grass_layer := 0
@export var dirt_layers: Vector2i
@export var deep_rock_layer := 0

var all_layers: Array[TileMapLayer] = []
var ui_canvas: CanvasLayer
var coord_label: Label
var current_layer_y: int = 5
var step_cooldown: float = 0.0

@onready var my_tile_set = preload("uid://b6lj4tdjvbmsg")
const TileMapCoords = preload("uid://crje5ylxrljml")

const LAYER_SPACING := -120
const TILE_PIXEL_SIZE := 16
const TILE_SCALE := 10
const STEP_RANGE := 55.0
const STEP_COOLDOWN_TIME := 0.3

func _ready() -> void:
	generate()
	create_coord_display()
	await get_tree().process_frame
	await get_tree().process_frame
	spawn_player_on_layer(5)

func _process(delta: float) -> void:
	if step_cooldown > 0.0:
		step_cooldown -= delta
	else:
		check_layer_transition()
	update_coords_from_current_layer()
	update_coord_display()

func get_layer_by_y(y) -> TileMapLayer:
	for l in all_layers:
		if int(l.y_cord) == int(y):
			return l
	return null

func get_tile_world_y(layer: TileMapLayer, cell: Vector2i) -> float:
	return layer.to_global(layer.map_to_local(cell)).y

func spawn_player_on_layer(y_cord: int) -> void:
	if GlobalPlayer == null or GlobalPlayer.player == null:
		return
	var target_layer = get_layer_by_y(y_cord)
	if target_layer == null:
		return
	current_layer_y = y_cord
	var center_cell = Vector2i(world_size.x / 2, world_size.y / 2)
	var tile_world_y = get_tile_world_y(target_layer, center_cell)
	GlobalPlayer.player.global_position.y = tile_world_y
	GlobalPlayer.player.z_index = y_cord + 1
	GlobalPlayer.coordinates.y = y_cord

func check_layer_transition() -> void:
	if GlobalPlayer == null or GlobalPlayer.player == null:
		return
	var player_pos = GlobalPlayer.player.global_position
	try_step_up(current_layer_y + 1, player_pos)
	try_step_down(current_layer_y - 1, player_pos)

func try_step_up(target_y_cord: int, player_pos: Vector2) -> void:
	var target_layer = get_layer_by_y(target_y_cord)
	if target_layer == null:
		return
	var target_local = target_layer.to_local(player_pos)
	var target_cell = target_layer.local_to_map(target_local)
	if target_layer.get_cell_tile_data(target_cell) == null:
		return
	transition_to_layer(target_y_cord)

func try_step_down(target_y_cord: int, player_pos: Vector2) -> void:
	var target_layer = get_layer_by_y(target_y_cord)
	if target_layer == null:
		return
	var target_local = target_layer.to_local(player_pos)
	var target_cell = target_layer.local_to_map(target_local)
	if target_layer.get_cell_tile_data(target_cell) == null:
		return
	var current_layer = get_layer_by_y(current_layer_y)
	if current_layer != null:
		var current_local = current_layer.to_local(player_pos)
		var current_cell = current_layer.local_to_map(current_local)
		if current_layer.get_cell_tile_data(current_cell) != null:
			return
	var tile_world_y = get_tile_world_y(target_layer, target_cell)
	if abs(player_pos.y - tile_world_y) <= STEP_RANGE:
		transition_to_layer(target_y_cord)

func transition_to_layer(y_cord: int) -> void:
	var target_layer = get_layer_by_y(y_cord)
	if target_layer == null:
		return
	current_layer_y = y_cord
	GlobalPlayer.player.z_index = y_cord + 1
	GlobalPlayer.stats.playerSpiritScene.z_index = y_cord + 1
	GlobalWorld.projectiles.z_index = y_cord + 2
	step_cooldown = STEP_COOLDOWN_TIME

func update_coords_from_current_layer() -> void:
	if GlobalPlayer == null or GlobalPlayer.player == null:
		return
	var current_layer = get_layer_by_y(current_layer_y)
	if current_layer == null:
		return
	var local_pos = current_layer.to_local(GlobalPlayer.player.global_position)
	var cell = current_layer.local_to_map(local_pos)
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
	var c = GlobalPlayer.coordinates
	if c == null:
		coord_label.text = ""
		return
	coord_label.text = "X: %d  Y: %d  Z: %d" % [int(c.x), int(c.y), int(c.z)]

func generate() -> void:
	GlobalPlayer.player.z_index = layers + 1
	var index := 0
	for i in layers:
		index += 1
		var new_layer = TileMapLayer.new()
		new_layer.tile_set = my_tile_set
		new_layer.scale = Vector2(TILE_SCALE, TILE_SCALE)
		var new_renderer = TilemapGaeaRenderer.new()
		var new_noise_gen = NoiseGenerator.new()
		var new_noise_settings = NoiseGeneratorSettings.new()
		var gen_data = NoiseGeneratorData.new()
		var tile_info = TilemapTileInfo.new()
		if index == grass_layer:
			gen_data.title = "Grass"
			tile_info.atlas_coord = Vector2i(2, 0)
			gen_data.min = 0
			gen_data.max = 1.0
		if index <= dirt_layers.x:
			if index >= dirt_layers.y:
				gen_data.title = "Dirt"
				tile_info.atlas_coord = Vector2i.ZERO
				gen_data.min = -1.0
				gen_data.max = 1.0
		if index == deep_rock_layer:
			gen_data.title = "Deep Rock"
			tile_info.atlas_coord = Vector2i(15, 0)
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
