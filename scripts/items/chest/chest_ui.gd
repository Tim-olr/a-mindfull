extends Control
class_name ChestUI

const C_ACCENT     := Color(0.90, 0.65, 0.20)
const C_TEXT       := Color(0.92, 0.90, 0.85)
const C_TEXT_DIM   := Color(0.55, 0.53, 0.50)
const C_SLOT_NORMAL := Color(0.13, 0.14, 0.17)
const C_SLOT_HOVER  := Color(0.20, 0.22, 0.27)
const C_BG         := Color(0.09, 0.10, 0.12)
const C_BORDER     := Color(0.22, 0.24, 0.28)
const C_RED        := Color(0.90, 0.35, 0.30)

const RADIUS    := 9
const SLOT_SIZE := 64
const SLOT_GAP  := 6
const GRID_COLS := 5

var _chest_interactable
var _items: Array = []

@onready var _main_panel:     Control = $MainPanel
@onready var _grid_container: Control = $MainPanel/Background/GridContainer
@onready var _subtitle_label: Label   = $MainPanel/Background/SubtitleLabel
@onready var _empty_label:    Label   = $MainPanel/Background/GridContainer/EmptyLabel
@onready var _take_all_btn:   Button  = $MainPanel/Background/TakeAllBtn


func _ready() -> void:
	if not get_parent() is CanvasLayer:
		var cl        := CanvasLayer.new()
		cl.layer       = 9
		cl.name        = "ChestUiLayer"
		get_tree().root.call_deferred("add_child", cl)
		await get_tree().process_frame
		get_parent().remove_child(self)
		cl.add_child(self)

	_center_panel()
	hide()


func _center_panel() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_main_panel.position = Vector2(
		(viewport_size.x - 500.0) / 2.0,
		(viewport_size.y - 400.0) / 2.0
	)


func open(items: Array, chest) -> void:
	_chest_interactable = chest
	_items = items.duplicate()
	_rebuild_slots()
	show()
	_animate_in()


func close() -> void:
	_chest_interactable = null
	hide()


func refresh(items: Array) -> void:
	_items = items.duplicate()
	_rebuild_slots()


func _rebuild_slots() -> void:
	for child in _grid_container.get_children():
		if child != _empty_label:
			child.queue_free()

	if _items.is_empty():
		_empty_label.visible = true
		_subtitle_label.text = "Empty"
		if _take_all_btn != null:
			_take_all_btn.disabled = true
		return

	_empty_label.visible = false
	var n := _items.size()
	_subtitle_label.text = "%d item%s inside" % [n, "s" if n != 1 else ""]
	if _take_all_btn != null:
		_take_all_btn.disabled = false

	for i in n:
		var entry = _items[i]
		var item: ItemResource = entry["item"]
		var count: int         = entry["count"]
		var col := i % GRID_COLS
		var row := i / GRID_COLS
		var slot := _make_item_slot(item, count, i)
		slot.position = Vector2(col * (SLOT_SIZE + SLOT_GAP), row * (SLOT_SIZE + SLOT_GAP))
		_grid_container.add_child(slot)


func _make_item_slot(item: ItemResource, count: int, index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	btn.size                = Vector2(SLOT_SIZE, SLOT_SIZE)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var mk := func(col: Color, border: Color = C_BORDER) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color     = col
		s.border_color = border
		s.set_border_width_all(1)
		s.set_corner_radius_all(7)
		return s
	btn.add_theme_stylebox_override("normal",  mk.call(C_SLOT_NORMAL))
	btn.add_theme_stylebox_override("hover",   mk.call(C_SLOT_HOVER, C_ACCENT))
	btn.add_theme_stylebox_override("pressed", mk.call(C_SLOT_HOVER, C_ACCENT))

	if item != null and item.txtr != null:
		var icon            := TextureRect.new()
		icon.texture         = item.txtr
		icon.layout_mode     = 1
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left     = 8
		icon.offset_top      = 8
		icon.offset_right    = -8
		icon.offset_bottom   = -8
		icon.expand_mode     = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode    = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter    = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon)

	if count > 1:
		var lbl              := Label.new()
		lbl.text              = "x%d" % count
		lbl.layout_mode       = 1
		lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		lbl.anchor_left       = 0.4
		lbl.anchor_top        = 0.4
		lbl.anchor_right      = 1.0
		lbl.anchor_bottom     = 1.0
		lbl.offset_right      = -4
		lbl.offset_bottom     = -3
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", C_TEXT)
		lbl.mouse_filter      = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lbl)

	if item != null and item.Name != "":
		btn.tooltip_text = item.Name

	btn.pressed.connect(_on_slot_take.bind(index))
	return btn


func _on_slot_take(index: int) -> void:
	if not is_instance_valid(_chest_interactable):
		return
	_chest_interactable.take_item(index)


func _on_take_all() -> void:
	if not is_instance_valid(_chest_interactable):
		return
	_chest_interactable.take_all()


func _on_close_pressed() -> void:
	if is_instance_valid(_chest_interactable):
		_chest_interactable.close_interaction()
	else:
		hide()


func _animate_in() -> void:
	modulate     = Color(1, 1, 1, 0)
	scale        = Vector2(0.92, 0.92)
	pivot_offset = get_viewport().get_visible_rect().size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate", Color.WHITE, 0.18)
	tw.tween_property(self, "scale",    Vector2.ONE,  0.18).set_trans(Tween.TRANS_BACK)
