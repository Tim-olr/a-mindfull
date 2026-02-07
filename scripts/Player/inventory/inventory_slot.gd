extends Button
class_name InventorySlot

signal selected(slot_index : int)
signal item_changed(slot_index : int)

@export var slot_index: int = -1

var item = null
var item_count: int = 0

var txtr: TextureRect = null
var count_label: Label = null

var _ready_called: bool = false

func _ready() -> void:
	if txtr == null:
		txtr = get_node_or_null("ItemIcon")
	if count_label == null:
		count_label = get_node_or_null("ItemCount")
	if txtr == null:
		push_error("InventorySlot: missing child 'ItemIcon' (TextureRect). Please add it or rename.")
	if count_label == null:
		push_warning("InventorySlot: missing child 'ItemCount' (Label).")
	_ready_called = true
	_update_visuals()

func set_item(new_item, count: int = 1) -> void:
	item = new_item
	item_count = count
	_update_visuals()
	emit_signal("item_changed", slot_index)


func _update_visuals() -> void:
	if not _ready_called:
		if txtr == null:
			txtr = get_node_or_null("ItemIcon")
		if count_label == null:
			count_label = get_node_or_null("ItemCount")
	if txtr == null:
		return
	if item != null:
		if item.has_method("get") and item.get("txtr") != null:
			txtr.texture = item.txtr
		else:
			if "txtr" in item:
				txtr.texture = item.txtr
			else:
				txtr.texture = null
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


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
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
	var temp_item = item
	var temp_count = item_count
	set_item(data["item"], data["count"])
	if is_instance_valid(source_slot):
		source_slot.set_item(temp_item, temp_count)
