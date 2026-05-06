extends Control
class_name SafeUI

const C_BG         := Color(0.09, 0.10, 0.12)
const C_PANEL      := Color(0.13, 0.14, 0.17)
const C_PANEL_DARK := Color(0.08, 0.09, 0.11)
const C_BORDER     := Color(0.22, 0.24, 0.28)
const C_ACCENT     := Color(0.90, 0.65, 0.20)
const C_ACCENT_DIM := Color(0.60, 0.42, 0.10)
const C_TEXT       := Color(0.92, 0.90, 0.85)
const C_TEXT_DIM   := Color(0.55, 0.53, 0.50)
const C_GREEN      := Color(0.35, 0.80, 0.45)
const C_RED        := Color(0.90, 0.35, 0.30)

const W       := 720
const H       := 540
const PAD     := 18
const RADIUS  := 9

const GRID_COLS := 4
const SLOT_SIZE := 64
const SLOT_GAP  := 6

@export var slotAmount: int = 24

var slots: Array = []
var slots_with_items: Array = []
var occupiedSlots: int = 0

const slot_scene = preload("res://scenes/Player/inventory/InventorySlot.tscn")

var _grid_container: Control
var _capacity_label: Label
var _shard_stored_label: Label
var _shard_amount_input: LineEdit
var _shard_minus_btn: Button
var _shard_plus_btn: Button
var _shard_withdraw_btn: Button


func _ready() -> void:
	# Re-parent to a CanvasLayer so the panel renders in screen space,
	# not transformed by world camera. Same trick the scrap broker uses.
	if not get_parent() is CanvasLayer:
		var cl        := CanvasLayer.new()
		cl.layer       = 8
		cl.name        = "SafeUiLayer"
		get_tree().root.call_deferred("add_child", cl)
		await get_tree().process_frame
		get_parent().remove_child(self)
		cl.add_child(self)
	_build_ui()
	hide()


func open() -> void:
	_rebuild_inv_slots()
	for item in GlobalSafe.safe:
		add_item(item, item.amount)
	_update_capacity_label()
	_update_shard_label()
	show()
	_animate_in()


func close() -> void:
	_save_and_close()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var viewport_size := get_viewport().get_visible_rect().size
	var center_x      := (viewport_size.x - W) / 2.0
	var center_y      := (viewport_size.y - H) / 2.0

	var main_panel       := Control.new()
	main_panel.position   = Vector2(center_x, center_y)
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
	bg.add_child(stripe)

	var title                      := _lbl("SAFE", 26, C_ACCENT, true)
	title.position                  = Vector2(0, 14)
	title.size                      = Vector2(W, 38)
	title.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(title)

	var sub                      := _lbl("Stored items and shards.", 14, C_TEXT_DIM)
	sub.position                  = Vector2(0, 50)
	sub.size                      = Vector2(W, 22)
	sub.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(sub)

	var sep      := ColorRect.new()
	sep.color     = C_BORDER
	sep.size      = Vector2(W - PAD * 2, 2)
	sep.position  = Vector2(PAD, 80)
	bg.add_child(sep)

	# Left column: items grid
	var grid_x := PAD
	var grid_y := 100
	var grid_w := GRID_COLS * SLOT_SIZE + (GRID_COLS - 1) * SLOT_GAP
	var grid_rows := ceili(float(slotAmount) / float(GRID_COLS))
	var grid_h := grid_rows * SLOT_SIZE + (grid_rows - 1) * SLOT_GAP

	var items_label                      := _lbl("ITEMS", 13, C_ACCENT, true)
	items_label.position                  = Vector2(grid_x, grid_y - 24)
	items_label.size                      = Vector2(grid_w, 20)
	bg.add_child(items_label)

	_capacity_label                      = _lbl("", 12, C_TEXT_DIM)
	_capacity_label.position              = Vector2(grid_x, grid_y - 24)
	_capacity_label.size                  = Vector2(grid_w, 20)
	_capacity_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	bg.add_child(_capacity_label)

	_grid_container              = Control.new()
	_grid_container.position     = Vector2(grid_x, grid_y)
	_grid_container.size         = Vector2(grid_w, grid_h)
	_grid_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(_grid_container)

	# Right column: shards section
	var col_gap := 28
	var right_x := grid_x + grid_w + col_gap
	var right_w := W - right_x - PAD

	var shards_label                      := _lbl("SHARDS", 13, C_ACCENT, true)
	shards_label.position                  = Vector2(right_x, grid_y - 24)
	shards_label.size                      = Vector2(right_w, 20)
	bg.add_child(shards_label)

	var shard_box := _make_box(Vector2(right_w, 200), Vector2(right_x, grid_y), C_PANEL_DARK, C_BORDER)
	bg.add_child(shard_box)

	_shard_stored_label                      = _lbl("0", 28, C_ACCENT, true)
	_shard_stored_label.position              = Vector2(0, 16)
	_shard_stored_label.size                  = Vector2(right_w, 36)
	_shard_stored_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	shard_box.add_child(_shard_stored_label)

	var stored_sub                      := _lbl("stored in safe", 11, C_TEXT_DIM)
	stored_sub.position                  = Vector2(0, 56)
	stored_sub.size                      = Vector2(right_w, 18)
	stored_sub.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
	shard_box.add_child(stored_sub)

	var inner_sep      := ColorRect.new()
	inner_sep.color     = C_BORDER
	inner_sep.size      = Vector2(right_w - 24, 1)
	inner_sep.position  = Vector2(12, 86)
	shard_box.add_child(inner_sep)

	var amount_lbl                      := _lbl("WITHDRAW AMOUNT", 11, C_TEXT_DIM, true)
	amount_lbl.position                  = Vector2(0, 96)
	amount_lbl.size                      = Vector2(right_w, 18)
	amount_lbl.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
	shard_box.add_child(amount_lbl)

	var btn_y := 120
	_shard_minus_btn = Button.new()
	_shard_minus_btn.text = "−"
	_shard_minus_btn.position = Vector2(12, btn_y)
	_shard_minus_btn.size = Vector2(32, 32)
	_shard_minus_btn.add_theme_font_size_override("font_size", 18)
	_shard_minus_btn.pressed.connect(_on_shard_minus)
	shard_box.add_child(_shard_minus_btn)

	_shard_amount_input = LineEdit.new()
	_shard_amount_input.text = "0"
	_shard_amount_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shard_amount_input.position = Vector2(48, btn_y)
	_shard_amount_input.size = Vector2(right_w - 96, 32)
	shard_box.add_child(_shard_amount_input)

	_shard_plus_btn = Button.new()
	_shard_plus_btn.text = "+"
	_shard_plus_btn.position = Vector2(right_w - 44, btn_y)
	_shard_plus_btn.size = Vector2(32, 32)
	_shard_plus_btn.add_theme_font_size_override("font_size", 18)
	_shard_plus_btn.pressed.connect(_on_shard_plus)
	shard_box.add_child(_shard_plus_btn)

	_shard_withdraw_btn = _action_btn("◈  Withdraw", Vector2(12, 160), Vector2(right_w - 24, 32))
	_shard_withdraw_btn.pressed.connect(_on_shard_withdraw)
	shard_box.add_child(_shard_withdraw_btn)

	# Close button
	var close_btn := Button.new()
	close_btn.text  = "✕"
	close_btn.flat  = true
	close_btn.position = Vector2(W - 42, 10)
	close_btn.size     = Vector2(32, 32)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color",       C_TEXT_DIM)
	close_btn.add_theme_color_override("font_hover_color", C_RED)
	close_btn.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
	close_btn.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
	close_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	close_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	close_btn.pressed.connect(_on_close_pressed)
	bg.add_child(close_btn)

	_rebuild_inv_slots()
	_update_capacity_label()
	_update_shard_label()


func _rebuild_inv_slots() -> void:
	slots.clear()
	slots_with_items.clear()
	occupiedSlots = 0
	for child in _grid_container.get_children():
		child.queue_free()

	for i in range(slotAmount):
		var slot = slot_scene.instantiate()
		slot.slot_index          = i
		slot.is_safe_slot        = true
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.size                = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.connect("item_changed", Callable(self, "_on_slot_item_changed"))

		var col := i % GRID_COLS
		var row := i / GRID_COLS
		slot.position = Vector2(col * (SLOT_SIZE + SLOT_GAP), row * (SLOT_SIZE + SLOT_GAP))

		_grid_container.add_child(slot)
		slots.append(slot)


func _animate_in() -> void:
	modulate     = Color(1, 1, 1, 0)
	scale        = Vector2(0.92, 0.92)
	pivot_offset = get_viewport().get_visible_rect().size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate", Color.WHITE, 0.18)
	tw.tween_property(self, "scale",    Vector2.ONE,  0.18).set_trans(Tween.TRANS_BACK)


func _save_and_close() -> void:
	GlobalSafe.safe.clear()
	for slot in slots_with_items:
		if slot.item != null:
			GlobalSafe.safe.append(slot.item)
	if is_instance_valid(InventorySlot.held_item):
		GlobalSafe.safe.append(InventorySlot.held_item)
		InventorySlot.held_item  = null
		InventorySlot.held_count = 0
		if is_instance_valid(InventorySlot.cursor_icon):
			InventorySlot.cursor_icon.texture = null
			InventorySlot.cursor_icon.visible = false
	hide()


func _on_close_pressed() -> void:
	_save_and_close()
	_notify_interactable_closed()


func _on_slot_item_changed(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
	var slot = slots[index]
	if slot.item != null:
		if not slots_with_items.has(slot):
			slots_with_items.append(slot)
			occupiedSlots += 1
	else:
		if slots_with_items.has(slot):
			slots_with_items.erase(slot)
			occupiedSlots -= 1
	_update_capacity_label()


func add_item(item, count: int = 1) -> bool:
	if item == null:
		return false
	if item.isStackable:
		for s in slots:
			if s.item != null and s.item.Name == item.Name:
				s.set_item(s.item, s.item_count + count)
				return true
	if occupiedSlots >= slotAmount:
		return false
	for s in slots:
		if s.item == null:
			s.set_item(item, count)
			return true
	return false


func _notify_interactable_closed() -> void:
	if is_instance_valid(GlobalPlayer.manager):
		for area in GlobalPlayer.manager.interact_area.get_overlapping_areas():
			if area is Interactable and area._is_active:
				area.close_interaction()
				return


func _update_capacity_label() -> void:
	if _capacity_label != null:
		_capacity_label.text = "%d / %d" % [occupiedSlots, slotAmount]


# --- shard withdraw helpers ---

func _shard_input_value() -> float:
	if _shard_amount_input == null:
		return 0.0
	var t := _shard_amount_input.text.strip_edges()
	if t.is_empty():
		return 0.0
	return maxf(0.0, t.to_float())


func _set_shard_input(v: float) -> void:
	if _shard_amount_input != null:
		_shard_amount_input.text = str(maxf(0.0, v))


func _on_shard_minus() -> void:
	_set_shard_input(_shard_input_value() - 1.0)


func _on_shard_plus() -> void:
	_set_shard_input(minf(GlobalSafe.shards, _shard_input_value() + 1.0))


func _on_shard_withdraw() -> void:
	var amount: float = _shard_input_value()
	if amount <= 0.0:
		return
	if amount > GlobalSafe.shards:
		amount = GlobalSafe.shards
	if amount <= 0.0:
		return
	GlobalSafe.shards -= amount
	GlobalPlayer.stats.add_shards(amount)
	_set_shard_input(0.0)
	_update_shard_label()


func _update_shard_label() -> void:
	if _shard_stored_label != null:
		_shard_stored_label.text = "◈  %s" % str(GlobalSafe.shards)


# --- styling helpers (mirror scrap broker) ---

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


func _lbl(txt: String, sz: int, col: Color, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l


func _action_btn(txt: String, pos: Vector2, sz: Vector2) -> Button:
	var btn     := Button.new()
	btn.text     = txt
	btn.position = pos
	btn.size     = sz
	btn.add_theme_font_size_override("font_size", 16)
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
