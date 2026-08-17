extends Control
class_name ActualInv

## The player's weapon-carry bar. Holds up to `slotAmount` weapons at once
## (default 2 — see PlayerStats.max_weapons). Click a slot to equip that
## weapon; upgrades found during a run can raise capacity via extend_capacity()
## / set_total_capacity().

signal hotbar_selected(item_resource, slot_index: int)

@export var slotAmount: int = 2
var occupiedSlots: int = 0
var slots_with_items := []

const PAD       := 16
const SLOT_SIZE := 68
const SLOT_GAP  := 6

var slot_scene = preload("res://player/inventory/inventory_slot.tscn")

var base_slot_amount: int    = 0
var slots: Array             = []
var selected_slot_index: int = -1

@onready var _hotbar_bg:        NinePatchRect = $HotbarBg
@onready var _hotbar_container: Control       = $HotbarBg/HotbarContainer


func _ready() -> void:
	base_slot_amount = slotAmount
	_setup_layout()
	_populate_slots()


func _setup_layout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hotbar_total_w := slotAmount * SLOT_SIZE + (slotAmount - 1) * SLOT_GAP + PAD * 2
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


func _populate_slots() -> void:
	if slotAmount < 1:
		slotAmount = 1
	slots.clear()
	_clear_children(_hotbar_container)

	for i in range(slotAmount):
		var slot = slot_scene.instantiate()
		slot.slot_index    = i
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.size                = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.connect("selected",     Callable(self, "_on_slot_selected"))
		slot.connect("item_changed", Callable(self, "_on_slot_item_changed"))
		slots.append(slot)
		slot.position = Vector2(i * (SLOT_SIZE + SLOT_GAP), 0)
		_hotbar_container.add_child(slot)

	if selected_slot_index >= slots.size():
		selected_slot_index = -1
	update_hotbar_selection()


func _clear_children(node: Control) -> void:
	for child in node.get_children():
		child.queue_free()


func _on_slot_selected(index: int) -> void:
	if index < 0 or index >= slots.size():
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


func add_item(item, count: int = 1) -> bool:
	if item == null:
		return false
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


func _select_hotbar_number(n: int) -> void:
	var index = n - 1
	if index < 0 or index >= slots.size():
		return
	_on_slot_selected(index)


func update_hotbar_selection() -> void:
	for i in range(slots.size()):
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
		slot.position = Vector2(i * (SLOT_SIZE + SLOT_GAP), 0)
		_hotbar_container.add_child(slot)
	_setup_layout()


func set_total_capacity(total: int) -> void:
	if total > slotAmount:
		extend_capacity(total - slotAmount)
