extends Control
class_name ActualInv

signal hotbar_selected(item_resource, slot_index: int)

@export var slotAmount: int = 24
var occupiedSlots: int = 0
var slots_with_items := []
const MIN_HOTBAR_SLOTS = 6

const PAD          := 16
const SLOT_SIZE    := 68
const SLOT_GAP     := 6
const HOTBAR_COLS  := 6
const GRID_COLS    := 6

var slot_scene = preload("res://scenes/Player/inventory/InventorySlot.tscn")

var base_slot_amount: int    = 0
var slots: Array             = []
var selected_slot_index: int = -1
var _grid_visible: bool      = false

@onready var _hotbar_bg:        NinePatchRect = $HotbarBg
@onready var _hotbar_container: Control       = $HotbarBg/HotbarContainer
@onready var _grid_panel:       Control       = $GridPanel
@onready var _grid_bg:          NinePatchRect = $GridPanel/GridBg
@onready var _grid_container:   Control       = $GridPanel/GridBg/GridContainer
@onready var _title_label:      Label         = $GridPanel/GridBg/TitleLabel
@onready var _capacity_label:   Label         = $GridPanel/GridBg/CapacityLabel


func _ready() -> void:
	base_slot_amount = slotAmount
	_setup_layout()
	_populate_slots()
	_set_grid_visible(false)


func _setup_layout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hotbar_total_w := HOTBAR_COLS * SLOT_SIZE + (HOTBAR_COLS - 1) * SLOT_GAP + PAD * 2
	var hotbar_h       := SLOT_SIZE + PAD * 2 + 28

	_hotbar_bg.size = Vector2(hotbar_total_w, hotbar_h)

	var stripe: ColorRect = _hotbar_bg.get_node("HotbarStripe")
	stripe.size = Vector2(hotbar_total_w, 3)

	_hotbar_container.position = Vector2(PAD, 28)
	_hotbar_container.size     = Vector2(hotbar_total_w - PAD * 2, SLOT_SIZE)

	var viewport_size := get_viewport().get_visible_rect().size
	_hotbar_bg.position = Vector2(
		(viewport_size.x - hotbar_total_w) / 2.0,
		viewport_size.y - hotbar_h - 12
	)

	var grid_rows    := ceili(float(slotAmount - MIN_HOTBAR_SLOTS) / float(GRID_COLS))
	var grid_total_w := GRID_COLS * SLOT_SIZE + (GRID_COLS - 1) * SLOT_GAP + PAD * 2
	var grid_total_h := grid_rows * SLOT_SIZE + (grid_rows - 1) * SLOT_GAP + PAD * 2 + 36 + 28

	_grid_panel.size = Vector2(grid_total_w, grid_total_h)
	_grid_bg.size    = Vector2(grid_total_w, grid_total_h)

	var grid_stripe: ColorRect = _grid_bg.get_node("GridStripe")
	grid_stripe.size = Vector2(grid_total_w, 3)

	_title_label.size     = Vector2(grid_total_w - PAD * 2, 26)
	_capacity_label.size  = Vector2(grid_total_w - PAD * 2, 26)

	var grid_sep: ColorRect = _grid_bg.get_node("GridSep")
	grid_sep.size     = Vector2(grid_total_w - PAD * 2, 1)
	grid_sep.position = Vector2(PAD, 34)

	_grid_container.position = Vector2(PAD, 42)
	_grid_container.size     = Vector2(grid_total_w - PAD * 2, grid_total_h - 42 - PAD)

	_grid_panel.position = Vector2(
		(viewport_size.x - grid_total_w) / 2.0,
		_hotbar_bg.position.y - grid_total_h - 8
	)

	_update_capacity_label()


func _populate_slots() -> void:
	if slotAmount < MIN_HOTBAR_SLOTS:
		slotAmount = MIN_HOTBAR_SLOTS
	slots.clear()
	_clear_children(_hotbar_container)
	_clear_children(_grid_container)

	for i in range(slotAmount):
		var slot = slot_scene.instantiate()
		slot.slot_index    = i
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.size                = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.connect("selected",     Callable(self, "_on_slot_selected"))
		slot.connect("item_changed", Callable(self, "_on_slot_item_changed"))
		slots.append(slot)

		if i < MIN_HOTBAR_SLOTS:
			var col := i % HOTBAR_COLS
			slot.position = Vector2(col * (SLOT_SIZE + SLOT_GAP), 0)
			_hotbar_container.add_child(slot)
		else:
			var grid_i := i - MIN_HOTBAR_SLOTS
			var col    := grid_i % GRID_COLS
			var row    := grid_i / GRID_COLS
			slot.position = Vector2(col * (SLOT_SIZE + SLOT_GAP), row * (SLOT_SIZE + SLOT_GAP))
			_grid_container.add_child(slot)

	if selected_slot_index >= MIN_HOTBAR_SLOTS or selected_slot_index >= slots.size():
		selected_slot_index = -1
	update_hotbar_selection()


func _clear_children(node: Control) -> void:
	for child in node.get_children():
		child.queue_free()


func _set_grid_visible(vis: bool) -> void:
	_grid_visible       = vis
	_grid_panel.visible = vis
	if vis:
		for i in range(MIN_HOTBAR_SLOTS, slots.size()):
			slots[i].update_visuals()
		_grid_panel.modulate = Color(1, 1, 1, 0)
		_grid_panel.scale    = Vector2(0.95, 0.95)
		_grid_panel.pivot_offset = _grid_bg.size / 2.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_grid_panel, "modulate", Color.WHITE, 0.15)
		tw.tween_property(_grid_panel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)


func _on_slot_selected(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
	if index >= MIN_HOTBAR_SLOTS:
		return
	if selected_slot_index == index:
		selected_slot_index = -1
		update_hotbar_selection()
		emit_signal("hotbar_selected", null, index)
		return
	selected_slot_index = index
	var slot: Button = slots[index]
	emit_signal("hotbar_selected", slot.item, index)
	update_hotbar_selection()


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
	if index == selected_slot_index and slot.item == null:
		selected_slot_index = -1
		emit_signal("hotbar_selected", null, index)
		update_hotbar_selection()
	_update_capacity_label()


func add_item(item, count: int = 1) -> bool:
	if item == null:
		return false
	if "isStackable" in item and item.isStackable:
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


func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			Key.KEY_1: _select_hotbar_number(1)
			Key.KEY_2: _select_hotbar_number(2)
			Key.KEY_3: _select_hotbar_number(3)
			Key.KEY_4: _select_hotbar_number(4)
			Key.KEY_5: _select_hotbar_number(5)
			Key.KEY_6: _select_hotbar_number(6)
	if event.is_action_pressed("open_inventory"):
		_set_grid_visible(!_grid_visible)


func _select_hotbar_number(n: int) -> void:
	var index = n - 1
	if index < 0 or index >= MIN_HOTBAR_SLOTS or index >= slots.size():
		return
	_on_slot_selected(index)


func update_hotbar_selection() -> void:
	for i in range(MIN_HOTBAR_SLOTS):
		if i >= slots.size():
			break
		var s = slots[i]
		if i == selected_slot_index:
			if "set_selected" in s:
				s.set_selected(true)
			else:
				s.modulate = Color(1.0, 0.9, 0.5, 1.0)
		else:
			if "deselect" in s:
				s.deselect()
			else:
				s.modulate = Color(1.0, 1.0, 1.0, 1.0)


func extend_capacity(extra_slots: int) -> void:
	if extra_slots <= 0:
		return
	var old_count := slotAmount
	slotAmount += extra_slots
	for i in range(old_count, slotAmount):
		var slot = slot_scene.instantiate()
		slot.slot_index    = i
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.size                = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.connect("selected",     Callable(self, "_on_slot_selected"))
		slot.connect("item_changed", Callable(self, "_on_slot_item_changed"))
		slots.append(slot)
		var grid_i := i - MIN_HOTBAR_SLOTS
		var col    := grid_i % GRID_COLS
		var row    := grid_i / GRID_COLS
		slot.position = Vector2(col * (SLOT_SIZE + SLOT_GAP), row * (SLOT_SIZE + SLOT_GAP))
		_grid_container.add_child(slot)
	var new_rows := ceili(float(slotAmount - MIN_HOTBAR_SLOTS) / float(GRID_COLS))
	var old_rows := ceili(float(old_count - MIN_HOTBAR_SLOTS) / float(GRID_COLS))
	if new_rows > old_rows:
		var extra_h := (new_rows - old_rows) * (SLOT_SIZE + SLOT_GAP)
		_grid_container.size.y += extra_h
		_grid_bg.size.y        += extra_h
		var vp_size := get_viewport().get_visible_rect().size
		_grid_panel.position.y  = _hotbar_bg.position.y - _grid_bg.size.y - 8
	_update_capacity_label()


func set_total_capacity(total: int) -> void:
	if total > slotAmount:
		extend_capacity(total - slotAmount)


func _update_capacity_label() -> void:
	if _capacity_label != null:
		_capacity_label.text = "%d / %d" % [occupiedSlots, slotAmount]
