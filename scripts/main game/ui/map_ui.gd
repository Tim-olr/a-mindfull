extends Control

var fog_of_war = null

const PANEL_W := 820.0
const PANEL_H := 660.0
const MAP_PAD_L := 20.0
const MAP_PAD_T := 52.0
const MAP_PAD_R := 20.0
const MAP_PAD_B := 32.0

const BASE_CELL := 4.0
const ZOOM_MIN := 0.5
const ZOOM_MAX := 12.0

const C_BG        := Color(0.06, 0.07, 0.10, 0.97)
const C_PANEL     := Color(0.09, 0.11, 0.16)
const C_BORDER    := Color(0.22, 0.30, 0.45)
const C_ACCENT    := Color(0.45, 0.72, 1.00)
const C_TEXT_DIM  := Color(0.40, 0.48, 0.60)
const C_PLAYER    := Color(1.00, 0.92, 0.20)
const C_BEACON    := Color(0.20, 1.00, 0.45)
const C_UNVISITED := Color(0.06, 0.07, 0.09)

var _zoom: float = 2.0
var _center: Vector2 = Vector2.ZERO
var _drag_offset: Vector2 = Vector2.ZERO
var _dragging := false
var _drag_start_mouse := Vector2.ZERO
var _drag_start_offset := Vector2.ZERO

var _panel: Control
var _draw_ctrl: Control
var _map_area: Control

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()

func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size
	var px := (vp.x - PANEL_W) * 0.5
	var py := (vp.y - PANEL_H) * 0.5

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.50)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_panel = Control.new()
	_panel.position = Vector2(px, py)
	_panel.size = Vector2(PANEL_W, PANEL_H)
	_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_panel)

	var sb := StyleBoxFlat.new()
	sb.bg_color = C_PANEL
	sb.border_color = C_BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	var bg := Panel.new()
	bg.size = Vector2(PANEL_W, PANEL_H)
	bg.add_theme_stylebox_override("panel", sb)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(bg)

	var accent := ColorRect.new()
	accent.color = C_ACCENT
	accent.size = Vector2(PANEL_W, 3)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(accent)

	var title := Label.new()
	title.text = "MAP"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", C_ACCENT)
	title.position = Vector2(18, 10)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(title)

	var hint := Label.new()
	hint.text = "Scroll: zoom   Drag: pan   [M] close"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", C_TEXT_DIM)
	hint.position = Vector2(18, PANEL_H - 26)
	hint.size = Vector2(PANEL_W - 36, 20)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hint)

	var map_w := PANEL_W - MAP_PAD_L - MAP_PAD_R
	var map_h := PANEL_H - MAP_PAD_T - MAP_PAD_B

	_map_area = Control.new()
	_map_area.position = Vector2(MAP_PAD_L, MAP_PAD_T)
	_map_area.size = Vector2(map_w, map_h)
	_map_area.clip_contents = true
	_map_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(_map_area)

	var map_bg := ColorRect.new()
	map_bg.color = C_UNVISITED
	map_bg.size = Vector2(map_w, map_h)
	map_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_area.add_child(map_bg)

	_draw_ctrl = Control.new()
	_draw_ctrl.size = Vector2(map_w, map_h)
	_draw_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_area.add_child(_draw_ctrl)
	_draw_ctrl.draw.connect(_on_draw_map)

	_map_area.gui_input.connect(_on_map_input)

func _process(_delta: float) -> void:
	if visible:
		_draw_ctrl.queue_redraw()

func queue_map_redraw() -> void:
	if visible and _draw_ctrl != null:
		_draw_ctrl.queue_redraw()

func open_map() -> void:
	if fog_of_war != null:
		_center = Vector2(fog_of_war.get_player_tile())
		_drag_offset = Vector2.ZERO
	show()
	_draw_ctrl.queue_redraw()

func close_map() -> void:
	hide()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("open_map"):
		close_map()
		get_viewport().set_input_as_handled()

func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_dragging = true
					_drag_start_mouse = event.position
					_drag_start_offset = _drag_offset
				else:
					_dragging = false
			MOUSE_BUTTON_WHEEL_UP:
				var old_z := _zoom
				_zoom = clampf(_zoom * 1.15, ZOOM_MIN, ZOOM_MAX)
				_adjust_center_for_zoom(event.position, old_z)
				_draw_ctrl.queue_redraw()
			MOUSE_BUTTON_WHEEL_DOWN:
				var old_z := _zoom
				_zoom = clampf(_zoom / 1.15, ZOOM_MIN, ZOOM_MAX)
				_adjust_center_for_zoom(event.position, old_z)
				_draw_ctrl.queue_redraw()
	elif event is InputEventMouseMotion and _dragging:
		_drag_offset = _drag_start_offset + (event.position - _drag_start_mouse)
		_draw_ctrl.queue_redraw()

func _adjust_center_for_zoom(mouse_pos: Vector2, old_zoom: float) -> void:
	var map_size := _draw_ctrl.size
	var map_center := map_size * 0.5
	var old_cp := BASE_CELL * old_zoom
	var new_cp := BASE_CELL * _zoom
	var old_world := _center + (mouse_pos - map_center - _drag_offset) / old_cp
	var new_world := _center + (mouse_pos - map_center - _drag_offset) / new_cp
	_drag_offset += (new_world - old_world) * new_cp

func _on_draw_map() -> void:
	if fog_of_war == null:
		return
	var map_size := _draw_ctrl.size
	var center := map_size * 0.5
	var cp := BASE_CELL * _zoom
	var min_x := center.x + _drag_offset.x - _center.x * cp
	var min_y := center.y + _drag_offset.y - _center.y * cp

	for cell: Vector2i in fog_of_war.visited:
		var sx := min_x + cell.x * cp
		var sy := min_y + cell.y * cp
		if sx + cp < 0.0 or sx > map_size.x:
			continue
		if sy + cp < 0.0 or sy > map_size.y:
			continue
		_draw_ctrl.draw_rect(Rect2(sx, sy, cp - 0.5, cp - 0.5), fog_of_war.visited[cell])

	# Draw beacon (extraction point) if The Beacon station is unlocked
	if WiseTree.is_unlocked("station_beacon") and fog_of_war.has_extraction_point:
		var ep := fog_of_war.extraction_point_tile
		var ex := min_x + ep.x * cp + cp * 0.5
		var ey := min_y + ep.y * cp + cp * 0.5
		var er := maxf(cp * 0.9, 5.0)
		_draw_ctrl.draw_circle(Vector2(ex, ey), er + 2.5, Color(0.05, 0.05, 0.05, 0.8))
		_draw_ctrl.draw_circle(Vector2(ex, ey), er, C_BEACON)
		# Inner cross to distinguish from player dot
		var arm := er * 0.5
		_draw_ctrl.draw_line(Vector2(ex - arm, ey), Vector2(ex + arm, ey), Color(0.05, 0.2, 0.1), 1.5)
		_draw_ctrl.draw_line(Vector2(ex, ey - arm), Vector2(ex, ey + arm), Color(0.05, 0.2, 0.1), 1.5)

	# Draw player marker
	if fog_of_war._tilemap != null and is_instance_valid(fog_of_war._tilemap):
		var pt = fog_of_war.get_player_tile()
		var px = min_x + pt.x * cp + cp * 0.5
		var py = min_y + pt.y * cp + cp * 0.5
		var r := maxf(cp * 0.7, 3.5)
		_draw_ctrl.draw_circle(Vector2(px, py), r + 1.5, Color(0.1, 0.1, 0.1, 0.7))
		_draw_ctrl.draw_circle(Vector2(px, py), r, C_PLAYER)
