extends Control
class_name SafeUI

@export var slotAmount: int = 24
@export var slot_size: int = 64
@export var panel_width: int = 400

var done

var slots: Array = []
var slots_with_items := []
var occupiedSlots: int = 0
var safe_panel: Panel
var safe_grid: GridContainer
var close_button: Button

const slot_scene = preload("res://scenes/Player/inventory/InventorySlot.tscn")

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
		var slot_tex = slot.get_node_or_null("SlotTexture")
		if slot_tex:
			slot_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		var icon = slot.get_node_or_null("ItemIcon")
		if icon:
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.anchor_left   = 0.15
			icon.anchor_top    = 0.1
			icon.anchor_right  = 0.9
			icon.anchor_bottom = 0.9
			icon.offset_left   = 4
			icon.offset_top    = 2
			icon.offset_right  = 0
			icon.offset_bottom = 0
		var label = slot.get_node_or_null("ItemCount")
		if label:
			label.add_theme_font_size_override("font_size", 200)
			label.z_index = 1
			label.anchor_left   = 0.7
			label.anchor_top    = 0.5
			label.anchor_right  = 1.0
			label.anchor_bottom = 1.0
			label.offset_left   = 0
			label.offset_top    = 0
			label.offset_right  = 10
			label.offset_bottom = 0
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			label.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
		slots.append(slot)

func open() -> void:
	for slot in slots:
		slot.set_item(null)
	slots_with_items.clear()
	occupiedSlots = 0
	safe_panel.visible = true
	for item in GlobalSafe.safe:
		add_item(item, item.amount)

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
	var icon = slot.get_node_or_null("ItemIcon")
	if icon and not slot.done and slot.item != null:
		if slot.item.isStackable:
			icon.anchor_left   = 0.1
			icon.anchor_top    = 0.05
			icon.anchor_right  = 0.72
			icon.anchor_bottom = 0.72
		else:
			icon.anchor_left   = 0.1
			icon.anchor_top    = 0.1
			icon.anchor_right  = 0.9
			icon.anchor_bottom = 0.9
		icon.offset_left   = 0
		icon.offset_top    = 0
		icon.offset_right  = 0
		icon.offset_bottom = 0
		slot.done = true
	slot.update_visuals()
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
