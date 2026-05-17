extends Control
class_name ChestUI

const C_BG         := Color(0.09, 0.10, 0.12)
const C_PANEL      := Color(0.13, 0.14, 0.17)
const C_PANEL_DARK := Color(0.08, 0.09, 0.11)
const C_BORDER     := Color(0.22, 0.24, 0.28)
const C_ACCENT     := Color(0.90, 0.65, 0.20)
const C_RED        := Color(0.90, 0.35, 0.30)
const C_TEXT       := Color(0.92, 0.90, 0.85)
const C_TEXT_DIM   := Color(0.55, 0.53, 0.50)
const C_SLOT_NORMAL := Color(0.13, 0.14, 0.17)
const C_SLOT_HOVER  := Color(0.20, 0.22, 0.27)

const W         := 500
const H         := 400
const PAD       := 18
const RADIUS    := 9
const SLOT_SIZE := 64
const SLOT_GAP  := 6
const GRID_COLS := 5

var _chest_interactable  # ChestInteractable
var _items: Array = []

var _grid_container:  Control
var _subtitle_label:  Label
var _empty_label:     Label
var _take_all_btn:    Button
var _built:           bool = false


func _ready() -> void:
	if not get_parent() is CanvasLayer:
		var cl        := CanvasLayer.new()
		cl.layer       = 9
		cl.name        = "ChestUiLayer"
		get_tree().root.call_deferred("add_child", cl)
		await get_tree().process_frame
		get_parent().remove_child(self)
		cl.add_child(self)
	_build_ui()
	hide()


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


func _build_ui() -> void:
	if _built:
		return
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var overlay       := ColorRect.new()
	overlay.color      = Color(0, 0, 0, 0.45)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var viewport_size := get_viewport().get_visible_rect().size
	var main_panel    := Control.new()
	main_panel.position   = Vector2((viewport_size.x - W) / 2.0, (viewport_size.y - H) / 2.0)
	main_panel.size       = Vector2(W, H)
	main_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_panel)

	var shadow := _make_box(Vector2(W + 16, H + 16), Vector2(-8, -8), Color(0, 0, 0, 0.55))
	main_panel.add_child(shadow)

	var bg := _make_box(Vector2(W, H), Vector2.ZERO, C_BG, C_BORDER)
	main_panel.add_child(bg)

	var stripe      := ColorRect.new()
	stripe.color     = C_ACCENT
	stripe.size      = Vector2(W, 5)
	stripe.position  = Vector2.ZERO
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(stripe)

	var title := _lbl("CHEST", 26, C_ACCENT)
	title.position              = Vector2(0, 14)
	title.size                  = Vector2(W, 38)
	title.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(title)

	_subtitle_label                     = _lbl("", 15, C_TEXT_DIM)
	_subtitle_label.position            = Vector2(0, 50)
	_subtitle_label.size                = Vector2(W, 20)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(_subtitle_label)

	var sep      := ColorRect.new()
	sep.color     = C_BORDER
	sep.size      = Vector2(W - PAD * 2, 2)
	sep.position  = Vector2(PAD, 78)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(sep)

	_grid_container              = Control.new()
	_grid_container.position     = Vector2(PAD, 90)
	_grid_container.size         = Vector2(W - PAD * 2, H - 90 - 66)
	_grid_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(_grid_container)

	_empty_label                     = _lbl("This chest is empty.", 18, C_TEXT_DIM)
	_empty_label.position            = Vector2(0, (_grid_container.size.y / 2.0) - 12)
	_empty_label.size                = Vector2(W - PAD * 2, 28)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.visible             = false
	_grid_container.add_child(_empty_label)

	var btn_y     := H - PAD - 40
	var half_w    := (W - PAD * 2 - 8) / 2.0
	_take_all_btn  = _action_btn("Take All", Vector2(PAD, btn_y), Vector2(half_w, 36))
	_take_all_btn.pressed.connect(_on_take_all)
	bg.add_child(_take_all_btn)

	var close_btn := _flat_btn("Close", Vector2(PAD + half_w + 8, btn_y), Vector2(half_w, 36))
	close_btn.pressed.connect(_on_close_pressed)
	bg.add_child(close_btn)

	var x_btn := Button.new()
	x_btn.text     = "✕"
	x_btn.flat     = true
	x_btn.position = Vector2(W - 42, 10)
	x_btn.size     = Vector2(32, 32)
	x_btn.add_theme_font_size_override("font_size", 20)
	x_btn.add_theme_color_override("font_color",       C_TEXT_DIM)
	x_btn.add_theme_color_override("font_hover_color", C_RED)
	x_btn.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
	x_btn.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
	x_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	x_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	x_btn.pressed.connect(_on_close_pressed)
	bg.add_child(x_btn)


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


func _make_box(sz: Vector2, pos: Vector2, bg_col: Color,
			   border_col: Color = Color.TRANSPARENT) -> Control:
	var c     := Control.new()
	c.size     = sz
	c.position = pos
	var sb     := StyleBoxFlat.new()
	sb.bg_color = bg_col
	if border_col != Color.TRANSPARENT:
		sb.border_color = border_col
		sb.set_border_width_all(1)
	sb.set_corner_radius_all(RADIUS)
	var panel         := Panel.new()
	panel.size         = sz
	panel.position     = Vector2.ZERO
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", sb)
	c.add_child(panel)
	return c


func _lbl(txt: String, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _action_btn(txt: String, pos: Vector2, sz: Vector2) -> Button:
	var btn     := Button.new()
	btn.text     = txt
	btn.position = pos
	btn.size     = sz
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var mk := func(col: Color) -> StyleBoxFlat:
		var s               := StyleBoxFlat.new()
		s.bg_color           = col
		s.set_corner_radius_all(RADIUS)
		s.content_margin_top    = 6
		s.content_margin_bottom = 6
		return s
	btn.add_theme_stylebox_override("normal",  mk.call(C_ACCENT))
	btn.add_theme_stylebox_override("hover",   mk.call(Color(1.00, 0.75, 0.25)))
	btn.add_theme_stylebox_override("pressed", mk.call(Color(0.65, 0.45, 0.10)))
	btn.add_theme_color_override("font_color",         C_BG)
	btn.add_theme_color_override("font_hover_color",   C_BG)
	btn.add_theme_color_override("font_pressed_color", C_BG)
	return btn


func _flat_btn(txt: String, pos: Vector2, sz: Vector2) -> Button:
	var btn     := Button.new()
	btn.text     = txt
	btn.position = pos
	btn.size     = sz
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var mk := func(col: Color) -> StyleBoxFlat:
		var s               := StyleBoxFlat.new()
		s.bg_color           = col
		s.set_corner_radius_all(RADIUS)
		s.content_margin_top    = 6
		s.content_margin_bottom = 6
		return s
	btn.add_theme_stylebox_override("normal",  mk.call(C_PANEL))
	btn.add_theme_stylebox_override("hover",   mk.call(C_SLOT_HOVER))
	btn.add_theme_stylebox_override("pressed", mk.call(C_PANEL_DARK))
	btn.add_theme_color_override("font_color",         C_TEXT)
	btn.add_theme_color_override("font_hover_color",   C_TEXT)
	btn.add_theme_color_override("font_pressed_color", C_TEXT)
	return btn
