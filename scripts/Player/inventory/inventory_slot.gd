extends Button
class_name InventorySlot

signal selected(slot_index: int)
signal item_changed(slot_index: int)

@onready var slot_texture: TextureRect = $SlotTexture
const OUTLINE = preload("uid://b00dsthkd2ybg")

@export var slot_index: int = -1

var item: ItemResource = null
var item_count: int = 0
var txtr: TextureRect = null
var count_label: Label = null
var _ready_called: bool = false
var _is_selected: bool = false
var scene
var is_safe_slot: bool = false

var done := false

static var currently_selected_slot: InventorySlot = null

static var held_item: ItemResource = null
static var held_count: int = 0
static var cursor_icon: TextureRect = null

func _ready() -> void:
	_init_cursor_icon(self)
	txtr = get_node_or_null("ItemIcon")
	count_label = get_node_or_null("ItemCount")
	if txtr == null:
		push_error("InventorySlot: missing child 'ItemIcon' (TextureRect).")
	if count_label == null:
		push_warning("InventorySlot: missing child 'ItemCount' (Label).")
	if txtr != null:
		var mat := ShaderMaterial.new()
		mat.shader = OUTLINE
		mat.set_shader_parameter("outline_thickness", 2.0)
		mat.set_shader_parameter("outline_color", Color.TRANSPARENT)
		txtr.material = mat
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_ready_called = true
	update_visuals()

static func _init_cursor_icon(parent: Node) -> void:
	if is_instance_valid(cursor_icon):
		return
	cursor_icon = TextureRect.new()
	var mat := ShaderMaterial.new()
	mat.shader = OUTLINE
	mat.set_shader_parameter("outline_thickness", 2)
	cursor_icon.material = mat
	cursor_icon.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	cursor_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_icon.size = Vector2(250, 250)
	cursor_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	cursor_icon.modulate = Color(1.0, 1.0, 1.0, 0.7)
	cursor_icon.visible = false
	parent.get_tree().root.add_child.call_deferred(cursor_icon)

func _process(_delta: float) -> void:
	if is_instance_valid(cursor_icon):
		cursor_icon.global_position = get_global_mouse_position() - cursor_icon.size / 2.0

func _pressed() -> void:
	_init_cursor_icon(self)
	if held_item == null:
		if item == null:
			return
		if item.isUsableItem or item.isWeapon or item.isPlaceable:
			set_selected(true)
		emit_signal("selected", slot_index)

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		return
	if not get_global_rect().has_point(get_global_mouse_position()):
		return
	get_viewport().set_input_as_handled()
	if held_item != null:
		if _is_selected:
			_clear_equip_state()
		var swap = item
		var swap_count = item_count
		set_item(held_item, held_count)
		if is_safe_slot:
			if not GlobalSafe.safe.has(held_item):
				GlobalSafe.safe.append(held_item)
		else:
			GlobalSafe.safe.erase(held_item)
		held_item = swap
		held_count = swap_count
		_apply_cursor_icon(held_item)
	else:
		if item == null:
			return
		if _is_selected:
			_clear_equip_state()
		held_item = item
		held_count = item_count
		set_item(null)
		_apply_cursor_icon(held_item)

static func _apply_cursor_icon(res: ItemResource) -> void:
	if not is_instance_valid(cursor_icon):
		return
	if res != null:
		cursor_icon.texture = res.txtr if "txtr" in res else null
		cursor_icon.visible = cursor_icon.texture != null
		if cursor_icon.material is ShaderMaterial:
			cursor_icon.material.set_shader_parameter("outline_color", res.calculate_rarity_outline())
	else:
		cursor_icon.texture = null
		cursor_icon.visible = false

func _apply_slot_outline() -> void:
	if txtr == null or not txtr.material is ShaderMaterial:
		return
	if item != null:
		txtr.material.set_shader_parameter("outline_color", item.calculate_rarity_outline())
		txtr.material.set_shader_parameter("outline_thickness", 2.0)
	else:
		txtr.material.set_shader_parameter("outline_color", Color.TRANSPARENT)

func _clear_equip_state() -> void:
	if is_instance_valid(scene):
		scene.queue_free()
		scene = null
	_is_selected = false
	if currently_selected_slot == self:
		currently_selected_slot = null
	if is_instance_valid(item):
		if "isEquipped" in item:
			item.isEquipped = false
		item.isSelected = false
	_update_selection_visuals()

func set_item(new_item, count: int = 1) -> void:
	item = new_item
	if is_instance_valid(item):
		item.inv_slot = self
		item_count = count
		item.amount = count
	else:
		item = null
		item_count = 0
		done = false
	update_visuals()
	emit_signal("item_changed", slot_index)

func set_selected(value: bool) -> void:
	if value and item == null:
		return
	if value and currently_selected_slot != null and currently_selected_slot != self:
		currently_selected_slot._deselect_internal()
	_is_selected = value
	if value:
		currently_selected_slot = self
		item.isSelected = true
		item.isEquipped = true
		if item.itemScene != null:
			if is_instance_valid(scene):
				scene.queue_free()
			scene = item.itemScene.instantiate()
			GlobalPlayer.player.add_child(scene)
			scene.initialize(item)
			scene.isSelected = true
	else:
		_deselect_internal()
	_update_selection_visuals()

func _deselect_internal() -> void:
	_is_selected = false
	if currently_selected_slot == self:
		currently_selected_slot = null
		if is_instance_valid(item):
			item.isSelected = false
			if "isEquipped" in item:
				item.isEquipped = false
	_update_selection_visuals()

func deselect() -> void:
	_deselect_internal()
	if is_instance_valid(scene):
		scene.queue_free()
		scene = null

func _update_selection_visuals() -> void:
	if txtr == null:
		return
	if _is_selected:
		slot_texture.modulate = Color(2.0, 2.0, 2.0, 1.0)
		txtr.modulate = Color(1.0, 1.0, 1.0, 0.55)
	elif is_hovered():
		slot_texture.modulate = Color(1.5, 1.5, 1.5, 1.0)
		txtr.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		slot_texture.modulate = Color(1.0, 1.0, 1.0, 1.0)
		txtr.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_mouse_entered() -> void:
	_update_selection_visuals()

func _on_mouse_exited() -> void:
	_update_selection_visuals()

func update_visuals() -> void:
	if not _ready_called:
		txtr = get_node_or_null("ItemIcon")
		count_label = get_node_or_null("ItemCount")
	if txtr == null:
		return
	if item != null:
		txtr.texture = item.txtr if "txtr" in item else null
		if count_label != null and item.isStackable:
			item_count = item.amount
			count_label.text = str(item_count) if item_count > 0 else ""
			count_label.visible = item_count > 0
		txtr.visible = true
	else:
		txtr.texture = null
		txtr.visible = false
		if count_label != null:
			count_label.text = ""
			count_label.visible = false
	_apply_slot_outline()
	_update_selection_visuals()

func _on_pressed() -> void:
	pass
