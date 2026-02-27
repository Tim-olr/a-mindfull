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
	mouse_filter = Control.MOUSE_FILTER_PASS
	# Use preset so Godot resolves the full-rect size immediately
	set_anchors_preset(Control.PRESET_FULL_RECT)

	safe_panel = Panel.new()
	safe_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	# Use preset for full height on the right side, then nudge left by panel_width
	safe_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	safe_panel.offset_left = -panel_width
	safe_panel.offset_right = 0.0
	safe_panel.offset_top = 0.0
	safe_panel.offset_bottom = 0.0
	add_child(safe_panel)

	var title = Label.new()
	title.text = "The Safe"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 10
	title.offset_bottom = 40
	safe_panel.add_child(title)

	close_button = Button.new()
	close_button.text = "Close"
	close_button.set_anchors_preset(Control.PRESET_TOP_WIDE)
	close_button.offset_left = 10
	close_button.offset_right = -10
	close_button.offset_top = 45
	close_button.offset_bottom = 80
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.pressed.connect(close)
	safe_panel.add_child(close_button)

	safe_grid = GridContainer.new()
	safe_grid.columns = 4
	safe_grid.set_anchors_preset(Control.PRESET_TOP_WIDE)
	safe_grid.offset_left = 10
	safe_grid.offset_right = -10
	safe_grid.offset_top = 90
	safe_panel.add_child(safe_grid)

	safe_panel.visible = false
	# Defer so the panel rect is fully computed before slots are sized
	build_slots.call_deferred()

func build_slots() -> void:
	slots.clear()
	for child in safe_grid.get_children():
		child.queue_free()

	for i in range(slotAmount):
		var slot = slot_scene.instantiate()
		safe_grid.add_child(slot)  # in tree first so _ready() fires
		slot.slot_index = i
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		slot.connect("item_changed", Callable(self, "_on_slot_item_changed"))
		# Fix texture scaling — find the TextureRect inside the slot scene
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

func close() -> void:
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
