extends Button
class_name InventorySlot

signal selected(slot_index: int)
signal item_changed(slot_index: int)

@onready var slot_texture: TextureRect = $SlotTexture
const OUTLINE = preload("uid://b00dsthkd2ybg")

@export var slot_index: int = -1

var item:          ItemResource = null
var item_count:    int          = 0
var txtr:          TextureRect  = null
var count_label:   Label        = null
var _ready_called: bool         = false
var _is_selected:  bool         = false
var scene
var is_safe_slot:  bool = false
var done := false

static var currently_selected_slot: InventorySlot = null
static var held_item:   ItemResource = null
static var held_count:  int          = 0
static var cursor_icon: TextureRect  = null

const C_BG            := Color(0.09, 0.10, 0.12)
const C_SLOT_NORMAL   := Color(0.13, 0.14, 0.17)
const C_SLOT_HOVER    := Color(0.20, 0.22, 0.27)
const C_SLOT_SELECTED := Color(0.26, 0.20, 0.05)
const C_BORDER        := Color(0.22, 0.24, 0.28)
const C_ACCENT        := Color(0.90, 0.65, 0.20)
const C_ACCENT_DIM    := Color(0.60, 0.42, 0.10)
const C_TEXT          := Color(0.92, 0.90, 0.85)
const C_TEXT_DIM      := Color(0.55, 0.53, 0.50)
const SLOT_RADIUS     := 7


func _ready() -> void:
	_init_cursor_icon(self)
	_apply_slot_style()
	txtr        = get_node_or_null("ItemIcon")
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
		txtr.set_anchors_preset(Control.PRESET_FULL_RECT)
		txtr.offset_left   = 6
		txtr.offset_top    = 6
		txtr.offset_right  = -6
		txtr.offset_bottom = -6
		txtr.expand_mode   = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		txtr.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		txtr.layout_mode   = 1
	if count_label != null:
		count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		count_label.layout_mode          = 1
		count_label.anchor_left          = 0.5
		count_label.anchor_top           = 0.5
		count_label.anchor_right         = 1.0
		count_label.anchor_bottom        = 1.0
		count_label.offset_left          = 0
		count_label.offset_top           = 0
		count_label.offset_right         = -4
		count_label.offset_bottom        = -3
		count_label.scale                = Vector2.ONE
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
		count_label.add_theme_font_size_override("font_size", 13)
		count_label.add_theme_color_override("font_color", C_TEXT)
		count_label.z_index = 2
	if slot_texture != null:
		slot_texture.visible = false
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_ready_called = true
	update_visuals()


func _apply_slot_style() -> void:
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var mk := func(col: Color, border_col: Color = C_BORDER) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color     = col
		s.border_color = border_col
		s.set_border_width_all(1)
		s.set_corner_radius_all(SLOT_RADIUS)
		return s
	add_theme_stylebox_override("normal",   mk.call(C_SLOT_NORMAL))
	add_theme_stylebox_override("hover",    mk.call(C_SLOT_HOVER))
	add_theme_stylebox_override("pressed",  mk.call(C_SLOT_SELECTED, C_ACCENT))
	add_theme_stylebox_override("disabled", mk.call(C_SLOT_NORMAL))


static func _init_cursor_icon(parent: Node) -> void:
	if is_instance_valid(cursor_icon):
		return
	cursor_icon              = TextureRect.new()
	cursor_icon.name         = "CursorHeldItem"
	var mat                  := ShaderMaterial.new()
	mat.shader               = load("uid://b00dsthkd2ybg")
	mat.set_shader_parameter("outline_thickness", 3)
	cursor_icon.material     = mat
	cursor_icon.z_index      = RenderingServer.CANVAS_ITEM_Z_MAX
	cursor_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_icon.size         = Vector2(56, 56)
	cursor_icon.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	cursor_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cursor_icon.modulate     = Color(1.0, 1.0, 1.0, 0.85)
	cursor_icon.visible      = false
	cursor_icon.top_level    = true
	cursor_icon.scale = Vector2(2, 2)
	parent.get_tree().root.add_child.call_deferred(cursor_icon)


func _process(_delta: float) -> void:
	if is_instance_valid(cursor_icon) and cursor_icon.visible:
		cursor_icon.global_position = get_global_mouse_position()
	if item != null:
		_apply_slot_outline()


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
	if get_viewport().is_input_handled():
		return
	get_viewport().set_input_as_handled()
	if held_item != null:
		if _is_selected:
			_clear_equip_state()
		var swap       = item
		var swap_count = item_count
		set_item(held_item, held_count)
		if is_safe_slot:
			if not GlobalSafe.safe.has(held_item):
				GlobalSafe.safe.append(held_item)
		else:
			GlobalSafe.safe.erase(held_item)
		held_item  = swap
		held_count = swap_count
		_apply_cursor_icon(held_item)
	else:
		if item == null:
			return
		if _is_selected:
			_clear_equip_state()
		held_item  = item
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
		txtr.material.set_shader_parameter("outline_color",     item.calculate_rarity_outline())
		txtr.material.set_shader_parameter("outline_thickness", 2.0)
	else:
		txtr.material.set_shader_parameter("outline_color", Color.TRANSPARENT)


func _clear_equip_state() -> void:
	if is_instance_valid(scene):
		scene.queue_free()
		scene = null
	if is_instance_valid(GlobalPlayer.manager) and not is_instance_valid(GlobalPlayer.manager._weapon_instance):
		GlobalPlayer.manager._weapon_instance = null
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
		item_count    = count
		item.amount   = count
	else:
		item       = null
		item_count = 0
		done       = false
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
				scene = null
			scene = item.itemScene.instantiate()
			GlobalPlayer.player.add_child(scene)
			if is_instance_valid(GlobalPlayer.manager):
				GlobalPlayer.manager._weapon_instance = scene
			scene.initialize(item)
			scene.isSelected = true
			if is_instance_valid(GlobalPlayer.stats):
				GlobalPlayer.stats.canAttack = true
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
	if is_instance_valid(GlobalPlayer.manager) and not is_instance_valid(GlobalPlayer.manager._weapon_instance):
		GlobalPlayer.manager._weapon_instance = null


func _update_selection_visuals() -> void:
	var mk := func(col: Color, border_col: Color = C_BORDER) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color     = col
		s.border_color = border_col
		s.set_border_width_all(1)
		s.set_corner_radius_all(SLOT_RADIUS)
		return s
	if _is_selected:
		add_theme_stylebox_override("normal", mk.call(C_SLOT_SELECTED, C_ACCENT))
		add_theme_stylebox_override("hover",  mk.call(C_SLOT_SELECTED, C_ACCENT))
		if txtr != null:
			txtr.modulate = Color(1.0, 1.0, 1.0, 0.6)
	elif is_hovered():
		add_theme_stylebox_override("normal", mk.call(C_SLOT_HOVER, C_ACCENT))
		add_theme_stylebox_override("hover",  mk.call(C_SLOT_HOVER, C_ACCENT))
		if txtr != null:
			txtr.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		add_theme_stylebox_override("normal", mk.call(C_SLOT_NORMAL))
		add_theme_stylebox_override("hover",  mk.call(C_SLOT_HOVER, C_ACCENT))
		if txtr != null:
			txtr.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_mouse_entered() -> void:
	_update_selection_visuals()


func _on_mouse_exited() -> void:
	_update_selection_visuals()


func update_visuals() -> void:
	if not _ready_called:
		txtr        = get_node_or_null("ItemIcon")
		count_label = get_node_or_null("ItemCount")
	if txtr == null:
		return
	if item != null:
		txtr.texture = item.txtr if "txtr" in item else null
		if count_label != null and item.isStackable:
			item_count          = item.amount
			count_label.text    = str(item_count) if item_count > 0 else ""
			count_label.visible = item_count > 0
		txtr.visible = true
	else:
		txtr.texture = null
		txtr.visible = false
		if count_label != null:
			count_label.text    = ""
			count_label.visible = false
	_apply_slot_outline()
	_update_selection_visuals()


func _on_pressed() -> void:
	pass
