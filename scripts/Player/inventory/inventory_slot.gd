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
var is_cursed:     bool = false
var done := false

static var currently_selected_slot: InventorySlot = null
static var held_item:   ItemResource = null
static var held_count:  int          = 0
static var cursor_icon: TextureRect  = null
static var _cursor_layer: CanvasLayer = null

static var _tooltip_root:   Control     = null
static var _tooltip_layer:  CanvasLayer = null
static var _tooltip_panel:  Panel       = null
static var _tooltip_stripe: ColorRect   = null
static var _tooltip_name:   Label       = null
static var _tooltip_rarity: Label       = null
static var _tooltip_sep:    ColorRect   = null
static var _tooltip_desc:   Label       = null

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
	_init_tooltip(self)
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


const C_CURSED_TINT := Color(0.18, 0.08, 0.22)
const C_CURSED_BORDER := Color(0.40, 0.10, 0.50)

func _apply_slot_style() -> void:
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var mk := func(col: Color, border_col: Color = C_BORDER) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color     = col
		s.border_color = border_col
		s.set_border_width_all(1)
		s.set_corner_radius_all(SLOT_RADIUS)
		return s
	if is_cursed:
		add_theme_stylebox_override("normal",   mk.call(C_CURSED_TINT, C_CURSED_BORDER))
		add_theme_stylebox_override("hover",    mk.call(C_CURSED_TINT, C_CURSED_BORDER))
		add_theme_stylebox_override("pressed",  mk.call(C_CURSED_TINT, C_CURSED_BORDER))
		add_theme_stylebox_override("disabled", mk.call(C_CURSED_TINT, C_CURSED_BORDER))
	else:
		add_theme_stylebox_override("normal",   mk.call(C_SLOT_NORMAL))
		add_theme_stylebox_override("hover",    mk.call(C_SLOT_HOVER))
		add_theme_stylebox_override("pressed",  mk.call(C_SLOT_SELECTED, C_ACCENT))
		add_theme_stylebox_override("disabled", mk.call(C_SLOT_NORMAL))


static func _init_tooltip(parent: Node) -> void:
	if is_instance_valid(_tooltip_root):
		return
	_tooltip_layer        = CanvasLayer.new()
	_tooltip_layer.layer  = 110
	_tooltip_layer.name   = "ItemTooltipLayer"
	parent.get_tree().root.add_child.call_deferred(_tooltip_layer)

	const W   := 240
	const PAD := 10

	_tooltip_root              = Control.new()
	_tooltip_root.name         = "ItemTooltip"
	_tooltip_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_root.visible      = false
	_tooltip_layer.add_child.call_deferred(_tooltip_root)

	_tooltip_panel              = Panel.new()
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb                      := StyleBoxFlat.new()
	sb.bg_color                  = Color(0.08, 0.09, 0.11, 0.96)
	sb.border_color              = Color(0.22, 0.24, 0.28)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(7)
	_tooltip_panel.add_theme_stylebox_override("panel", sb)
	_tooltip_root.add_child(_tooltip_panel)

	_tooltip_stripe              = ColorRect.new()
	_tooltip_stripe.size         = Vector2(W, 4)
	_tooltip_stripe.position     = Vector2.ZERO
	_tooltip_stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_root.add_child(_tooltip_stripe)

	_tooltip_name              = Label.new()
	_tooltip_name.position     = Vector2(PAD, 8)
	_tooltip_name.size         = Vector2(W - PAD * 2, 22)
	_tooltip_name.add_theme_font_size_override("font_size", 15)
	_tooltip_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_root.add_child(_tooltip_name)

	_tooltip_rarity              = Label.new()
	_tooltip_rarity.position     = Vector2(PAD, 31)
	_tooltip_rarity.size         = Vector2(W - PAD * 2, 17)
	_tooltip_rarity.add_theme_font_size_override("font_size", 12)
	_tooltip_rarity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_root.add_child(_tooltip_rarity)

	_tooltip_sep              = ColorRect.new()
	_tooltip_sep.color        = Color(0.22, 0.24, 0.28)
	_tooltip_sep.size         = Vector2(W - PAD * 2, 1)
	_tooltip_sep.position     = Vector2(PAD, 52)
	_tooltip_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_sep.visible      = false
	_tooltip_root.add_child(_tooltip_sep)

	_tooltip_desc                 = Label.new()
	_tooltip_desc.position        = Vector2(PAD, 58)
	_tooltip_desc.size            = Vector2(W - PAD * 2, 72)
	_tooltip_desc.add_theme_font_size_override("font_size", 12)
	_tooltip_desc.add_theme_color_override("font_color", Color(0.72, 0.70, 0.66))
	_tooltip_desc.autowrap_mode   = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_desc.max_lines_visible = 4
	_tooltip_desc.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	_tooltip_desc.visible         = false
	_tooltip_root.add_child(_tooltip_desc)


static func _show_tooltip(item: ItemResource) -> void:
	if not is_instance_valid(_tooltip_root) or item == null:
		return
	if not _tooltip_root.is_inside_tree():
		return
	const W   := 240
	const PAD := 10
	const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]

	var rarity_col = item.calculate_rarity_outline()
	if rarity_col == null:
		rarity_col = Color.WHITE
	_tooltip_stripe.color = rarity_col
	_tooltip_name.text    = item.Name if item.Name != "" else "Unknown"
	_tooltip_name.add_theme_color_override("font_color", rarity_col)
	_tooltip_rarity.text  = RARITY_NAMES[clampi(item.rarity, 0, 4)]
	_tooltip_rarity.add_theme_color_override("font_color", rarity_col)

	var has_desc := item.description != null and item.description.strip_edges() != ""
	_tooltip_desc.visible = has_desc
	_tooltip_sep.visible  = has_desc

	var h: int
	if has_desc:
		_tooltip_desc.text = item.description
		var char_count     := item.description.length()
		var line_count     := clampi(ceili(float(char_count) / 28.0), 1, 4)
		h = 60 + line_count * 17 + 8
		_tooltip_desc.size = Vector2(W - PAD * 2, line_count * 17 + 4)
	else:
		h = 54

	_tooltip_panel.size  = Vector2(W, h)
	_tooltip_root.size   = Vector2(W, h)
	_tooltip_root.visible = true


static func _hide_tooltip() -> void:
	if is_instance_valid(_tooltip_root):
		_tooltip_root.visible = false


static func _init_cursor_icon(parent: Node) -> void:
	if is_instance_valid(cursor_icon):
		return
	_cursor_layer        = CanvasLayer.new()
	_cursor_layer.name   = "CursorIconLayer"
	_cursor_layer.layer  = 100
	parent.get_tree().root.add_child.call_deferred(_cursor_layer)

	cursor_icon              = TextureRect.new()
	cursor_icon.name         = "CursorHeldItem"
	var mat                  := ShaderMaterial.new()
	mat.shader               = load("uid://b00dsthkd2ybg")
	mat.set_shader_parameter("outline_thickness", 3)
	cursor_icon.material     = mat
	cursor_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_icon.size         = Vector2(56, 56)
	cursor_icon.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	cursor_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cursor_icon.modulate     = Color(1.0, 1.0, 1.0, 0.85)
	cursor_icon.visible      = false
	cursor_icon.scale        = Vector2(2, 2)
	_cursor_layer.add_child.call_deferred(cursor_icon)


func _process(_delta: float) -> void:
	if is_instance_valid(cursor_icon) and cursor_icon.visible:
		cursor_icon.position = cursor_icon.get_viewport().get_mouse_position() - (cursor_icon.size * cursor_icon.scale) / 2.0
	if item != null:
		_apply_slot_outline()
	if is_instance_valid(_tooltip_root) and _tooltip_root.visible and _tooltip_root.is_inside_tree():
		var vp   := _tooltip_root.get_viewport()
		var mp   := vp.get_mouse_position()
		var vs   := vp.get_visible_rect().size
		var tw   := _tooltip_root.size.x
		var th   := _tooltip_root.size.y
		var tx   := mp.x + 14.0
		var ty   := mp.y - th - 8.0
		if tx + tw > vs.x - 4.0:
			tx = mp.x - tw - 10.0
		if ty < 4.0:
			ty = mp.y + 18.0
		_tooltip_root.position = Vector2(tx, ty)


func _pressed() -> void:
	_hide_tooltip()
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
			emit_signal("selected", slot_index)
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
			emit_signal("selected", slot_index)
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
		var col = item.calculate_rarity_outline()
		txtr.material.set_shader_parameter("outline_color",     col if col != null else Color.WHITE)
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
	update_visuals.call_deferred()
	emit_signal("item_changed", slot_index)


func set_selected(value: bool) -> void:
	if value and item == null:
		return
	if currently_selected_slot != null and not is_instance_valid(currently_selected_slot):
		currently_selected_slot = null
	if value and currently_selected_slot != null and currently_selected_slot != self:
		currently_selected_slot.deselect()
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
			scene.initialize(item)
			GlobalPlayer.player.add_child(scene)
			GlobalPlayer.manager._weapon_instance = scene
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
	if item != null and held_item == null and not is_cursed:
		_show_tooltip(item)


func _on_mouse_exited() -> void:
	_update_selection_visuals()
	_hide_tooltip()


func update_visuals() -> void:
	if not _ready_called:
		txtr        = get_node_or_null("ItemIcon")
		count_label = get_node_or_null("ItemCount")
	if txtr == null:
		return
	if item != null:
		if is_cursed:
			txtr.texture = null
			txtr.visible = false
			if count_label != null:
				count_label.text    = ""
				count_label.visible = false
			_apply_slot_outline()
			_update_selection_visuals()
			return
		txtr.texture = item.txtr if "txtr" in item else null
		if count_label != null and item.isStackable:
			item_count          = item.amount
			count_label.text    = str(item_count) if item_count > 0 else ""
			count_label.visible = item_count > 0
		elif count_label != null:
			count_label.text    = ""
			count_label.visible = false
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
