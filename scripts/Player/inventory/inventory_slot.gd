extends Button
class_name InventorySlot

signal selected(slot_index : int)
signal item_changed(slot_index : int)

@onready var slot_texture: TextureRect = $SlotTexture

@export var slot_index: int = -1

var item = null
var item_count: int = 0

var txtr: TextureRect = null
var count_label: Label = null

var _ready_called: bool = false

static var currently_selected_slot: InventorySlot = null

func _ready() -> void:
	if txtr == null:
		txtr = get_node_or_null("ItemIcon")
	if count_label == null:
		count_label = get_node_or_null("ItemCount")
	if txtr == null:
		push_error("InventorySlot: missing child 'ItemIcon' (TextureRect). Please add it or rename.")
	if count_label == null:
		push_warning("InventorySlot: missing child 'ItemCount' (Label).")
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	_ready_called = true
	_update_visuals()

func set_item(new_item, count: int = 1) -> void:
	item = new_item
	item_count = count
	_update_visuals()
	emit_signal("item_changed", slot_index)

func set_selected(value: bool) -> void:
	if item == null:
		return
		
	if value and currently_selected_slot != null and currently_selected_slot != self:
		currently_selected_slot.deselect()
	
	if item.isUsableItem or item.isWeapon:
		item.isSelected = value
	
	if item.isSelected:
		currently_selected_slot = self
	elif currently_selected_slot == self:
		currently_selected_slot = null
	
	_update_selection_visuals()

func deselect() -> void:
	if item != null and item.isUsableItem:
		item.isSelected = false
	set_selected(false)

func _update_selection_visuals() -> void:
	if item != null and item.isSelected:
		slot_texture.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif is_hovered():
		slot_texture.modulate = Color(1.5, 1.5, 1.5, 1.0)
	else:
		slot_texture.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_mouse_entered() -> void:
	_update_selection_visuals()

func _on_mouse_exited() -> void:
	_update_selection_visuals()

func _update_visuals() -> void:
	if not _ready_called:
		if txtr == null:
			txtr = get_node_or_null("ItemIcon")
		if count_label == null:
			count_label = get_node_or_null("ItemCount")
	if txtr == null:
		return
	if item != null:
		txtr.texture = item.txtr if "txtr" in item else null
		if count_label != null:
			count_label.text = str(item_count) if item_count > 1 else ""
			count_label.visible = item_count > 1
		txtr.visible = true
	else:
		txtr.texture = null
		txtr.visible = false
		if count_label != null:
			count_label.text = ""
			count_label.visible = false
	_update_selection_visuals()

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			accept_event()
		else:
			if item != null:
				if item.isUsableItem or item.isWeapon:
					set_selected(true)
				emit_signal("selected", slot_index)

func _get_drag_data(_position):
	if not item:
		return null
	var preview = TextureRect.new()
	if item != null and ("txtr" in item or (item.has_method("get") and item.get("txtr") != null)):
		preview.texture = item.txtr
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.size = Vector2(40, 40)
	var preview_container = Control.new()
	preview_container.add_child(preview)
	preview.position = -preview.size / 2
	set_drag_preview(preview_container)
	return {
		"item": item,
		"count": item_count,
		"source_slot": self,
		"source_index": slot_index
	}

func _can_drop_data(_position, data) -> bool:
	return data is Dictionary and data.has("item")

func _drop_data(_position, data) -> void:
	if not (data is Dictionary and data.has("item")):
		return
	var source_slot: InventorySlot = data["source_slot"]
	if source_slot == self:
		return
	var temp_item = item
	var temp_count = item_count
	set_item(data["item"], data["count"])
	if is_instance_valid(source_slot):
		source_slot.set_item(temp_item, temp_count)
