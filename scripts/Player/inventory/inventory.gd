extends Control
class_name ActualInv

signal hotbar_selected(item_resource, slot_index : int)

@export var slotAmount: int = 24
var occupiedSlots: int = 0
const MIN_HOTBAR_SLOTS = 6

@onready var hotbar = $InventoryContainer/Hotbar
@onready var inventory_grid = $InventoryContainer/InventoryGrid
@onready var slot_scene = preload("res://spirit-game-project/scenes/Player/inventory/InventorySlot.tscn")

var slots: Array = []
var selected_slot_index: int = -1

func _ready() -> void:
	update_inventory_slots()
	inventory_grid.visible = false
	inventory_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE

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

func _on_slot_selected(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
	if index >= MIN_HOTBAR_SLOTS:
		return
	selected_slot_index = index
	var slot: Button = slots[index]
	emit_signal("hotbar_selected", slot.item, index)

func _on_slot_item_changed(index: int) -> void:
	if index == selected_slot_index:
		var slot = slots[index]
		if slot == null or slot.item == null or not slot.item.isWeapon:
			emit_signal("hotbar_selected", null, index)

func _input(event):
	if event.is_action_pressed("open_inventory"):
		inventory_grid.visible = !inventory_grid.visible
		inventory_grid.mouse_filter = Control.MOUSE_FILTER_STOP if inventory_grid.visible else Control.MOUSE_FILTER_IGNORE

func add_item(item, count: int = 1) -> bool:
	if occupiedSlots >= slotAmount:
		return false
	if item == null:
		return false
	if "isStackable" in item and item.isStackable:
		for s in slots:
			if s.item != null and "Name" in s.item and "Name" in item and s.item.Name == item.Name:
				var existing_count = s.item_count if "item_count" in s else 0
				s.set_item(s.item, existing_count + count)
				return true
	for s in slots:
		if s.item == null:
			s.set_item(item, count)
			occupiedSlots += 1
			return true
	return false
