extends Control
class_name ActualInv

signal hotbar_selected(item_resource, slot_index: int)

@export var slotAmount: int = 24

var occupiedSlots: int = 0

const MIN_HOTBAR_SLOTS = 6

@onready var hotbar = $InventoryContainer/Hotbar
@onready var inventory_grid = $InventoryContainer/InventoryGrid
@onready var slot_scene = preload("res://spirit-game-project/scenes/Player/inventory/InventorySlot.tscn")
const COPPER_PICKAXE = preload("uid://c6n55kgwomshl")

var slots: Array = []
var selected_slot_index: int = -1

func _ready() -> void:
	update_inventory_slots()
	inventory_grid.visible = false
	inventory_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_item(COPPER_PICKAXE) 

func clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

func update_inventory_slots() -> void:
	if slotAmount < MIN_HOTBAR_SLOTS:
		slotAmount = MIN_HOTBAR_SLOTS
	slots.clear()
	clear_container(hotbar)
	clear_container(inventory_grid)
	for i in range(slotAmount):
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.connect("selected", Callable(self, "_on_slot_selected"))
		slot.connect("item_changed", Callable(self, "_on_slot_item_changed"))
		slots.append(slot)
		if i < MIN_HOTBAR_SLOTS:
			hotbar.add_child(slot)
		else:
			inventory_grid.add_child(slot)
	if selected_slot_index >= MIN_HOTBAR_SLOTS or selected_slot_index >= slots.size():
		selected_slot_index = -1
	update_hotbar_selection()

func _on_slot_selected(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
	if index >= MIN_HOTBAR_SLOTS:
		return
	selected_slot_index = index
	var slot: Button = slots[index]
	emit_signal("hotbar_selected", slot.item, index)
	update_hotbar_selection()

func _on_slot_item_changed(index: int) -> void:
	if index != selected_slot_index:
		return
	var slot = slots[index]
	if slot == null or slot.item == null:
		selected_slot_index = -1
		emit_signal("hotbar_selected", null, index)
		update_hotbar_selection()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			Key.KEY_1:
				_select_hotbar_number(1)
			Key.KEY_2:
				_select_hotbar_number(2)
			Key.KEY_3:
				_select_hotbar_number(3)
			Key.KEY_4:
				_select_hotbar_number(4)
			Key.KEY_5:
				_select_hotbar_number(5)
			Key.KEY_6:
				_select_hotbar_number(6)
	if event.is_action_pressed("open_inventory"):
		inventory_grid.visible = !inventory_grid.visible
		inventory_grid.mouse_filter = Control.MOUSE_FILTER_STOP if inventory_grid.visible else Control.MOUSE_FILTER_IGNORE

func _select_hotbar_number(n: int) -> void:
	var index = n - 1
	if index < 0 or index >= MIN_HOTBAR_SLOTS:
		return
	if index >= slots.size():
		return
	_on_slot_selected(index)

func add_item(item, count: int = 1) -> bool:
	if item == null:
		return false
	if "isStackable" in item and item.isStackable:
		for s in slots:
			if s.item == null:
				s.set_item(item, count)
				occupiedSlots += 1
				return true
			if s.item != null and s.item.Name == item.Name:
				s.set_item(s.item, s.item_count + count)
				return true
	if occupiedSlots >= slotAmount:
		return false
	for s in slots:
		if s.item == null:
			s.set_item(item, count)
			occupiedSlots += 1
			return true
	return false

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
			if "set_selected" in s:
				s.set_selected(false)
			else:
				s.modulate = Color(1.0, 1.0, 1.0, 1.0)
