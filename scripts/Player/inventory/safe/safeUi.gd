extends Control
class_name SafeUI

@export var slotAmount: int = 24
@export var slot_size: int = 64
@export var panel_width: int = 400

var slots: Array = []
var slots_with_items := []
var occupiedSlots: int = 0
var safe_panel: Panel
var safe_grid: GridContainer
var close_button: Button

const slot_scene = preload("res://spirit-game-project/scenes/Player/inventory/InventorySlot.tscn")

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_panel = Panel.new()
	safe_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	safe_panel.offset_left = -panel_width
	add_child(safe_panel)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	safe_panel.add_child(vbox)
	safe_grid = GridContainer.new()
	safe_grid.columns = 4
	vbox.add_child(safe_grid)
	safe_panel.visible = false
	build_slots.call_deferred()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("esc"):
		GlobalSafe.safe.clear()
		for slot in slots_with_items:
			if slot.item != null:
				GlobalSafe.safe.append(slot.item)
		if is_instance_valid(InventorySlot.held_item):
			GlobalSafe.safe.append(InventorySlot.held_item)
			InventorySlot.held_item = null
			InventorySlot.held_count = 0
			if is_instance_valid(InventorySlot.cursor_icon):
				InventorySlot.cursor_icon.visible = false
		safe_panel.visible = false

func build_slots() -> void:
	slots.clear()
	for child in safe_grid.get_children():
		child.queue_free()
	for i in range(slotAmount):
		var slot = slot_scene.instantiate()
		safe_grid.add_child(slot)
		slot.slot_index = i
		slot.is_safe_slot = true
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		slot.connect("item_changed", Callable(self, "_on_slot_item_changed"))
		for child in slot.find_children("*", "TextureRect", true, false):
			child.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			child.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			child.set_anchors_preset(Control.PRESET_FULL_RECT)
		slots.append(slot)

func open() -> void:
	safe_panel.visible = true
	for i in range(GlobalSafe.safe.size()):
		if i >= slots.size():
			break
		slots[i].set_item(GlobalSafe.safe[i], GlobalSafe.safe[i].amount)

func _on_close_pressed() -> void:
	GlobalSafe.safe.clear()
	for slot in slots_with_items:
		if slot.item != null:
			GlobalSafe.safe.append(slot.item)
	safe_panel.visible = false

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
