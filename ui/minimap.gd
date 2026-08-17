extends Control

const MARGIN := 56.0
const COMPACT_SIZE := 160.0
const COMPACT_CELL := 12.0
const COMPACT_GAP := 4.0

const EXPANDED_SIZE := 640.0
const EXPANDED_CELL := 34.0
const EXPANDED_GAP := 10.0

const COLOR_BG := Color(0.05, 0.05, 0.07, 0.85)
const COLOR_NORMAL := Color(0.6, 0.6, 0.65)
const COLOR_UNEXPLORED := Color(0.32, 0.32, 0.35)
const COLOR_BOSS := Color(0.85, 0.2, 0.2)
const COLOR_ITEM := Color(0.95, 0.85, 0.2)
const COLOR_SHOP := Color(0.25, 0.8, 0.35)
const COLOR_CURRENT := Color(1, 1, 1)
const COLOR_LINE := Color(0.5, 0.5, 0.55, 0.8)

var expanded := false

func _ready() -> void:
	_apply_layout()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_minimap"):
		expanded = not expanded
		_apply_layout()

func _apply_layout() -> void:
	if expanded:
		anchor_left = 0.5
		anchor_top = 0.5
		anchor_right = 0.5
		anchor_bottom = 0.5
		offset_left = -EXPANDED_SIZE / 2.0
		offset_top = -EXPANDED_SIZE / 2.0
		offset_right = EXPANDED_SIZE / 2.0
		offset_bottom = EXPANDED_SIZE / 2.0
	else:
		anchor_left = 1.0
		anchor_top = 0.0
		anchor_right = 1.0
		anchor_bottom = 0.0
		offset_left = -(COMPACT_SIZE + MARGIN)
		offset_top = MARGIN
		offset_right = -MARGIN
		offset_bottom = MARGIN + COMPACT_SIZE
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _room_color(room: DungeonRoom) -> Color:
	match room.room_id:
		&"boss":
			return COLOR_BOSS
		&"item":
			return COLOR_ITEM
		&"shop":
			return COLOR_SHOP
		_:
			return COLOR_NORMAL

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG)

	var generator := GlobalWorld.dungeon_generator
	if generator == null or not is_instance_valid(generator):
		return
	var current: DungeonRoom = GlobalWorld.current_room
	var cell_size: float = EXPANDED_CELL if expanded else COMPACT_CELL
	var step: float = cell_size + (EXPANDED_GAP if expanded else COMPACT_GAP)
	var origin := size / 2.0
	if current:
		origin -= Vector2(current.grid_position) * step

	# Neighbors of visited rooms that haven't been entered yet: shown as a
	# plain gray square, one room deep only, so nothing further is spoiled.
	var frontier: Dictionary = {}
	for cell in generator.connections.keys():
		var room: DungeonRoom = generator.rooms.get(cell)
		if room == null or not room.visited:
			continue
		for neighbor in generator.connections[cell]:
			var neighbor_room: DungeonRoom = generator.rooms.get(neighbor)
			if neighbor_room != null and not neighbor_room.visited:
				frontier[neighbor] = true

	# Connections between two visited rooms, drawn under the room squares.
	for cell in generator.connections.keys():
		var room: DungeonRoom = generator.rooms.get(cell)
		if room == null or not room.visited:
			continue
		for neighbor in generator.connections[cell]:
			var neighbor_room: DungeonRoom = generator.rooms.get(neighbor)
			if neighbor_room == null or not neighbor_room.visited:
				continue
			var from := origin + Vector2(cell) * step
			var to := origin + Vector2(neighbor) * step
			draw_line(from, to, COLOR_LINE, 2.0)

	for cell in frontier.keys():
		var pos: Vector2 = origin + Vector2(cell) * step - Vector2(cell_size, cell_size) / 2.0
		draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), COLOR_UNEXPLORED)

	for cell in generator.rooms.keys():
		var room: DungeonRoom = generator.rooms[cell]
		if not room.visited:
			continue
		var pos: Vector2 = origin + Vector2(cell) * step - Vector2(cell_size, cell_size) / 2.0
		var color := _room_color(room)
		if room == current:
			color = COLOR_CURRENT
		draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), color)
		if expanded and room.room_id != &"normal":
			var label := String(room.room_id).substr(0, 1).to_upper()
			var font := get_theme_default_font()
			var font_size := 16
			var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			draw_string(font, pos + Vector2(cell_size, cell_size + text_size.y) / 2.0 - Vector2(text_size.x / 2.0, 0.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.85))
