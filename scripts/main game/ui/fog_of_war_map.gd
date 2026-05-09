extends CanvasLayer

const TILE_PX := 4
const REVEAL_RADIUS := 8
const BG_COLOR := Color(0.05, 0.06, 0.08, 0.92)
const FOG_COLOR := Color(0.10, 0.11, 0.14)
const EXPLORED_COLOR := Color(0.18, 0.22, 0.16)
const PLAYER_COLOR := Color(0.90, 0.65, 0.20)
const BORDER_COLOR := Color(0.22, 0.24, 0.28)
const ACCENT := Color(0.90, 0.65, 0.20)

var _revealed: Dictionary = {}
var _map_open := false
var _map_panel: Control
var _map_image: Image
var _map_texture: ImageTexture
var _map_rect: TextureRect
var _title_label: Label
var _hint_label: Label
var _player_marker: ColorRect
var _tile_map: TileMapLayer

var _map_min := Vector2i(-50, -50)
var _map_max := Vector2i(50, 50)

func _ready() -> void:
	layer = 90
	_build_ui()
	visible = false

func setup(tile_map: TileMapLayer, world_size: Vector2i) -> void:
	_tile_map = tile_map
	var half := world_size / 2
	_map_min = -half
	_map_max = half
	var w := (_map_max.x - _map_min.x)
	var h := (_map_max.y - _map_min.y)
	_map_image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	_map_image.fill(FOG_COLOR)
	_map_texture = ImageTexture.create_from_image(_map_image)
	_map_rect.texture = _map_texture
	var map_w := w * TILE_PX
	var map_h := h * TILE_PX
	_map_rect.custom_minimum_size = Vector2(map_w, map_h)
	_map_rect.size = Vector2(map_w, map_h)

func _build_ui() -> void:
	var vp_size := Vector2(1920, 1080)

	_map_panel = Control.new()
	_map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_map_panel)

	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(bg)

	var stripe := ColorRect.new()
	stripe.color = ACCENT
	stripe.size = Vector2(vp_size.x, 4)
	stripe.position = Vector2.ZERO
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(stripe)

	_title_label = Label.new()
	_title_label.text = "MAP"
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", ACCENT)
	_title_label.position = Vector2(32, 16)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(_title_label)

	_hint_label = Label.new()
	_hint_label.text = "Press M to close"
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.add_theme_color_override("font_color", Color(0.55, 0.53, 0.50))
	_hint_label.position = Vector2(32, 50)
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(_hint_label)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(32, 80)
	scroll.size = Vector2(vp_size.x - 64, vp_size.y - 112)
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_panel.add_child(scroll)

	var border := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	sb.border_color = BORDER_COLOR
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	border.add_theme_stylebox_override("panel", sb)
	border.position = Vector2(30, 78)
	border.size = Vector2(vp_size.x - 60, vp_size.y - 108)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(border)

	_map_rect = TextureRect.new()
	_map_rect.stretch_mode = TextureRect.STRETCH_KEEP
	_map_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_map_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(_map_rect)

	_player_marker = ColorRect.new()
	_player_marker.color = PLAYER_COLOR
	_player_marker.size = Vector2(6, 6)
	_player_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_marker.z_index = 10
	_map_rect.add_child(_player_marker)

func _process(_delta: float) -> void:
	if not is_instance_valid(GlobalPlayer.player):
		return
	if _tile_map == null:
		return
	var player_tile := _tile_map.local_to_map(_tile_map.to_local(GlobalPlayer.player.global_position))
	_reveal_around(player_tile)
	if _map_open:
		_update_player_marker(player_tile)

func _reveal_around(center: Vector2i) -> void:
	var changed := false
	for dx in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
		for dy in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
			if dx * dx + dy * dy > REVEAL_RADIUS * REVEAL_RADIUS:
				continue
			var tile := Vector2i(center.x + dx, center.y + dy)
			if _revealed.has(tile):
				continue
			_revealed[tile] = true
			var px := tile.x - _map_min.x
			var py := tile.y - _map_min.y
			if px >= 0 and py >= 0 and _map_image != null and px < _map_image.get_width() and py < _map_image.get_height():
				var tile_data = _tile_map.get_cell_tile_data(tile)
				if tile_data != null:
					_map_image.set_pixel(px, py, EXPLORED_COLOR)
				else:
					_map_image.set_pixel(px, py, Color(0.06, 0.07, 0.09))
				changed = true
	if changed and _map_texture != null:
		_map_texture.update(_map_image)

func _update_player_marker(player_tile: Vector2i) -> void:
	if _player_marker == null:
		return
	var px := float(player_tile.x - _map_min.x) * TILE_PX - 3
	var py := float(player_tile.y - _map_min.y) * TILE_PX - 3
	_player_marker.position = Vector2(px, py)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_map"):
		_toggle_map()

func _toggle_map() -> void:
	_map_open = !_map_open
	visible = _map_open
	if _map_open and _map_texture != null:
		_map_texture.update(_map_image)
		if is_instance_valid(GlobalPlayer.player) and _tile_map != null:
			var player_tile := _tile_map.local_to_map(_tile_map.to_local(GlobalPlayer.player.global_position))
			_update_player_marker(player_tile)
