extends Control
class_name SafeUI

@export var slotAmount:  int = 24
@export var slot_size:   int = 68
@export var panel_width: int = 420

var done

var slots:           Array = []
var slots_with_items := []
var occupiedSlots:   int   = 0

const slot_scene = preload("res://scenes/Player/inventory/InventorySlot.tscn")

const C_BG         := Color(0.09, 0.10, 0.12)
const C_PANEL      := Color(0.13, 0.14, 0.17)
const C_PANEL_DARK := Color(0.08, 0.09, 0.11)
const C_BORDER     := Color(0.22, 0.24, 0.28)
const C_ACCENT     := Color(0.90, 0.65, 0.20)
const C_ACCENT_DIM := Color(0.60, 0.42, 0.10)
const C_TEXT       := Color(0.92, 0.90, 0.85)
const C_TEXT_DIM   := Color(0.55, 0.53, 0.50)
const C_RED        := Color(0.90, 0.35, 0.30)
const RADIUS       := 9
const PAD          := 16
const SLOT_GAP     := 6
const GRID_COLS    := 4

var _safe_panel: Control
var _safe_bg: Control
var _grid_container: Control
var _title_label: Label
var _capacity_label: Label
var _close_btn: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	_populate_slots()
	_safe_panel.visible = false


func _build_ui() -> void:
	var grid_rows    := ceili(float(slotAmount) / float(GRID_COLS))
	var grid_w       := GRID_COLS * slot_size + (GRID_COLS - 1) * SLOT_GAP
	var total_w      := grid_w + PAD * 2
	var grid_h       := grid_rows * slot_size + (grid_rows - 1) * SLOT_GAP
	var header_h     := 42
	var total_h      := header_h + grid_h + PAD * 2 + 28

	_safe_panel              = Control.new()
	_safe_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe_panel)

	var viewport_size := get_viewport().get_visible_rect().size

	_safe_panel.position = Vector2(
		viewport_size.x - total_w - 20,
		(viewport_size.y - total_h) / 2.0
	)

	var shadow := _make_box(Vector2(total_w + 12, total_h + 12), Vector2(-6, -6), Color(0, 0, 0, 0.45))
	_safe_panel.add_child(shadow)

	_safe_bg            = _make_box(Vector2(total_w, total_h), Vector2.ZERO, C_BG, C_BORDER)
	_safe_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe_panel.add_child(_safe_bg)

	var stripe      := ColorRect.new()
	stripe.color     = C_ACCENT
	stripe.size      = Vector2(total_w, 3)
	stripe.position  = Vector2.ZERO
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe_bg.add_child(stripe)

	_title_label                      = Label.new()
	_title_label.text                  = "SAFE"
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", C_ACCENT)
	_title_label.position              = Vector2(PAD, 8)
	_title_label.size                  = Vector2(total_w - PAD * 2, 26)
	_title_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_LEFT
	_title_label.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	_safe_bg.add_child(_title_label)

	_capacity_label                      = Label.new()
	_capacity_label.add_theme_font_size_override("font_size", 13)
	_capacity_label.add_theme_color_override("font_color", C_TEXT_DIM)
	_capacity_label.position              = Vector2(PAD, 8)
	_capacity_label.size                  = Vector2(total_w - PAD * 2 - 30, 26)
	_capacity_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	_capacity_label.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	_safe_bg.add_child(_capacity_label)

	_close_btn          = Button.new()
	_close_btn.text     = "✕"
	_close_btn.flat     = true
	_close_btn.position = Vector2(total_w - 36, 6)
	_close_btn.size     = Vector2(28, 28)
	_close_btn.add_theme_font_size_override("font_size", 16)
	_close_btn.add_theme_color_override("font_color",       C_TEXT_DIM)
	_close_btn.add_theme_color_override("font_hover_color", C_RED)
	_close_btn.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
	_close_btn.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
	_close_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_close_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	_close_btn.pressed.connect(_on_close_pressed)
	_safe_bg.add_child(_close_btn)

	var sep      := ColorRect.new()
	sep.color     = C_BORDER
	sep.size      = Vector2(total_w - PAD * 2, 1)
	sep.position  = Vector2(PAD, 34)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe_bg.add_child(sep)

	_grid_container              = Control.new()
	_grid_container.position     = Vector2(PAD, header_h)
	_grid_container.size         = Vector2(grid_w, grid_h)
	_grid_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe_bg.add_child(_grid_container)

	_update_capacity_label()


func _populate_slots() -> void:
	slots.clear()
	_clear_children(_grid_container)

	for i in range(slotAmount):
		var slot = slot_scene.instantiate()
		slot.slot_index          = i
		slot.is_safe_slot        = true
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		slot.size                = Vector2(slot_size, slot_size)
		slot.connect("item_changed", Callable(self, "_on_slot_item_changed"))

		var col := i % GRID_COLS
		var row := i / GRID_COLS
		slot.position = Vector2(col * (slot_size + SLOT_GAP), row * (slot_size + SLOT_GAP))

		_grid_container.add_child(slot)
		slots.append(slot)


func _clear_children(node: Control) -> void:
	for child in node.get_children():
		child.queue_free()


func open() -> void:
	for slot in slots:
		slot.set_item(null)
	slots_with_items.clear()
	occupiedSlots = 0
	for item in GlobalSafe.safe:
		add_item(item, item.amount)
	_update_capacity_label()
	_safe_panel.visible = true
	_animate_in()


func close() -> void:
	_save_and_close()


func _animate_in() -> void:
	_safe_panel.modulate     = Color(1, 1, 1, 0)
	_safe_panel.scale        = Vector2(0.95, 0.95)
	_safe_panel.pivot_offset = _safe_bg.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_safe_panel, "modulate", Color.WHITE, 0.15)
	tw.tween_property(_safe_panel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)


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
	_safe_panel.visible = false


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
