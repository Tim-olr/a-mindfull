extends Node

var visited: Dictionary = {}  # Vector2i -> Color
var _tilemap: TileMapLayer = null
var _map_ui = null
var _reveal_radius: int = 8
var _last_tile: Vector2i = Vector2i(-99999, -99999)

func register_tilemap(tm: TileMapLayer) -> void:
	_tilemap = tm
	visited.clear()
	_last_tile = Vector2i(-99999, -99999)

func get_player_tile() -> Vector2i:
	if _tilemap == null or not is_instance_valid(_tilemap):
		return Vector2i.ZERO
	if not is_instance_valid(GlobalPlayer.player):
		return Vector2i.ZERO
	var local_pos = _tilemap.to_local(GlobalPlayer.player.global_position)
	return _tilemap.local_to_map(local_pos)

func _process(_delta: float) -> void:
	if _tilemap == null or not is_instance_valid(_tilemap):
		return
	if not is_instance_valid(GlobalPlayer.player):
		return
	var pt = get_player_tile()
	if pt == _last_tile:
		return
	_last_tile = pt
	_reveal_around(pt)

func _reveal_around(center: Vector2i) -> void:
	var r := _reveal_radius
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			if dx * dx + dy * dy > r * r:
				continue
			var cell := center + Vector2i(dx, dy)
			if not visited.has(cell):
				visited[cell] = _get_tile_color(cell)

func _get_tile_color(cell: Vector2i) -> Color:
	if _tilemap == null:
		return Color(0.30, 0.30, 0.30)
	var source_id := _tilemap.get_cell_source_id(cell)
	if source_id == -1:
		return Color(0.10, 0.10, 0.12)
	var atlas := _tilemap.get_cell_atlas_coords(cell)
	# Rough terrain heuristic: atlas rows 0-3 tend to be grass, 4+ tend to be dirt
	if atlas.y <= 3:
		return Color(0.28, 0.55, 0.22)
	return Color(0.50, 0.36, 0.20)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_map"):
		_toggle_map()

func _toggle_map() -> void:
	if _tilemap == null or not is_instance_valid(_tilemap):
		return
	if _map_ui == null or not is_instance_valid(_map_ui):
		_create_map_ui()
	elif _map_ui.visible:
		_map_ui.close_map()
	else:
		_map_ui.open_map()

func _create_map_ui() -> void:
	var script = load("res://scripts/main game/ui/map_ui.gd")
	if script == null:
		return
	var cl := CanvasLayer.new()
	cl.layer = 20
	cl.name = "FogMapLayer"
	get_tree().root.add_child(cl)
	var ui = script.new()
	ui.fog_of_war = self
	cl.add_child(ui)
	_map_ui = ui
	ui.open_map()
