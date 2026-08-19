extends Control
class_name SpiritSelectUI

const GRID_COLS := 5
const SLOT_SIZE := Vector2(150, 90)
const SLOT_GAP := 10.0
const PANEL_SIZE := Vector2(820, 430)

const C_BORDER   := Color(0.30, 0.40, 0.55, 1)
const C_ACCENT   := Color(0.45, 0.72, 1.0, 1)
const C_SELECTED := Color(0.90, 0.65, 0.20, 1)

const FALLBACK_ICON := preload("res://icon.svg")

var _spirit_paths: Array[String] = [
	"res://spirits/a_peaceful_world/a_peaceful_world.tres",
	"res://spirits/chain_the_floor/chain_the_floor.tres",
	"res://spirits/follow_the_wheel/follow_the_wheel.tres",
	"res://spirits/furniture_city/furniture_city.tres",
	"res://spirits/jesters_grin/jesters_grin.tres",
	"res://spirits/keep_me_close/keep_me_close.tres",
	"res://spirits/look_at_you/look_at_you.tres",
	"res://spirits/shift_the_sand/shift_the_sand.tres",
	"res://spirits/silver_bullet/silver_bullet.tres",
	"res://spirits/slow_and_steady/slow_and_steady.tres",
	"res://spirits/spread_like_fire/spread_like_fire.tres",
	"res://spirits/start_your_engine/start_your_engine.tres",
	"res://spirits/wandering_eye/wandering_eye.tres",
]

@onready var _main_panel: Control = $MainPanel
@onready var _grid_container: Control = $MainPanel/Background/GridContainer

var _slot_buttons: Dictionary = {} # SpiritResource -> Button
var _normal_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _pressed_style: StyleBoxFlat
var _selected_style: StyleBoxFlat


func _ready() -> void:
	if not get_parent() is CanvasLayer:
		var cl := CanvasLayer.new()
		cl.layer = 9
		cl.name = "SpiritSelectUiLayer"
		get_tree().root.call_deferred("add_child", cl)
		await get_tree().process_frame
		get_parent().remove_child(self)
		cl.add_child(self)

	_build_styles()
	_center_panel()
	_build_slots()
	hide()


func _build_styles() -> void:
	_normal_style = _make_style(Color(0.13, 0.16, 0.22, 1), C_BORDER)
	_hover_style = _make_style(Color(0.19, 0.24, 0.33, 1), C_ACCENT)
	_pressed_style = _make_style(Color(0.08, 0.10, 0.14, 1), C_ACCENT)
	_selected_style = _make_style(Color(0.20, 0.17, 0.08, 1), C_SELECTED, 2)


func _make_style(bg: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = border_width
	s.border_width_top = border_width
	s.border_width_right = border_width
	s.border_width_bottom = border_width
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_right = 8
	s.corner_radius_bottom_left = 8
	return s


func _center_panel() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_main_panel.position = Vector2(
		(viewport_size.x - PANEL_SIZE.x) / 2.0,
		(viewport_size.y - PANEL_SIZE.y) / 2.0
	)


func _build_slots() -> void:
	for child in _grid_container.get_children():
		child.queue_free()
	_slot_buttons.clear()

	for i in range(_spirit_paths.size()):
		var resource := load(_spirit_paths[i]) as SpiritResource
		if resource == null:
			continue
		var slot := _make_slot(resource)
		var col := i % GRID_COLS
		var row := i / GRID_COLS
		slot.position = Vector2(col * (SLOT_SIZE.x + SLOT_GAP), row * (SLOT_SIZE.y + SLOT_GAP))
		_grid_container.add_child(slot)
		_slot_buttons[resource] = slot

	_refresh_selection()


func _make_slot(resource: SpiritResource) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = SLOT_SIZE
	btn.size = SLOT_SIZE
	btn.clip_text = true
	btn.add_theme_stylebox_override("normal", _normal_style)
	btn.add_theme_stylebox_override("hover", _hover_style)
	btn.add_theme_stylebox_override("pressed", _pressed_style)
	btn.add_theme_stylebox_override("focus", _normal_style)
	btn.pressed.connect(_on_slot_pressed.bind(resource))

	var icon_rect := TextureRect.new()
	icon_rect.texture = (resource.icon as Texture2D) if resource.icon != null else FALLBACK_ICON
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.size = Vector2(48, 48)
	icon_rect.position = Vector2((SLOT_SIZE.x - 48) / 2.0, 6)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon_rect)

	var name_label := Label.new()
	name_label.text = resource.Name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(4, 58)
	name_label.size = Vector2(SLOT_SIZE.x - 8, 28)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_label)

	return btn


func _on_slot_pressed(resource: SpiritResource) -> void:
	_select_spirit(resource)


func _select_spirit(resource: SpiritResource) -> void:
	if resource == null or resource == GlobalPlayer.stats.playerSpirit:
		return
	GlobalPlayer.stats.playerSpirit = resource
	GameManager.playerSpirit = resource
	var old_spirit = GlobalPlayer.stats.playerSpiritScene
	var new_spirit = resource.scene.instantiate()
	new_spirit.host = GlobalPlayer.player
	GlobalPlayer.stats.playerSpiritScene = new_spirit
	GlobalPlayer.player.add_child(new_spirit)
	if is_instance_valid(old_spirit):
		old_spirit.queue_free()
	_refresh_selection()


func _refresh_selection() -> void:
	for resource in _slot_buttons.keys():
		var btn: Button = _slot_buttons[resource]
		var is_selected: bool = resource == GlobalPlayer.stats.playerSpirit
		btn.add_theme_stylebox_override("normal", _selected_style if is_selected else _normal_style)


func open() -> void:
	_refresh_selection()
	show()
	_animate_in()


func close() -> void:
	hide()


func _animate_in() -> void:
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.92, 0.92)
	pivot_offset = get_viewport().get_visible_rect().size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate", Color.WHITE, 0.18)
	tw.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _on_close_pressed() -> void:
	close()
	_notify_interactable_closed()


func _notify_interactable_closed() -> void:
	if is_instance_valid(GlobalPlayer.manager):
		for area in GlobalPlayer.manager.interact_area.get_overlapping_areas():
			if area is Interactable and area._is_active:
				area.close_interaction()
				return
