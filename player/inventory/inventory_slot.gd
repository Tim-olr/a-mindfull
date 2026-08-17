extends Button
class_name InventorySlot

signal selected(slot_index: int)
signal item_changed(slot_index: int)

@onready var slot_bg:    NinePatchRect = $SlotBg
@onready var txtr:       TextureRect   = $ItemIcon
@onready var count_label: Label        = $ItemCount

const OUTLINE        = preload("uid://b00dsthkd2ybg")
const _TOOLTIP_SCENE = preload("res://player/inventory/item_tooltip.tscn")
const _CURSOR_SCENE  = preload("res://player/inventory/cursor_held_item.tscn")

@export var slot_index: int = -1

var item:          ItemResource = null
var item_count:    int          = 0
var _ready_called: bool         = false
var _is_selected:  bool         = false
var scene
var is_safe_slot:  bool = false
var done := false

static var currently_selected_slot: InventorySlot = null
static var held_item:   ItemResource = null
static var held_count:  int          = 0
static var cursor_icon: TextureRect  = null
static var _cursor_layer: CanvasLayer = null

static var _tooltip_root:   Control    = null
static var _tooltip_layer:  CanvasLayer = null
static var _tooltip_stripe: ColorRect  = null
static var _tooltip_name:   Label      = null
static var _tooltip_rarity: Label      = null
static var _tooltip_sep:    ColorRect  = null
static var _tooltip_desc:   Label      = null

# Modulate colours used for slot state — tweak freely in the editor
# or override these from an external script if you want theme support.
const TINT_NORMAL   := Color(1.00, 1.00, 1.00, 1.0)
const TINT_HOVER    := Color(1.25, 1.25, 1.25, 1.0)   # brighter on hover
const TINT_SELECTED := Color(1.00, 0.82, 0.25, 1.0)   # gold when selected


func _ready() -> void:
	_init_cursor_icon(self)
	_init_tooltip(self)
	_ready_called = true
	update_visuals()


# ── Tooltip singleton ────────────────────────────────────────────────────────

static func _init_tooltip(parent: Node) -> void:
	if is_instance_valid(_tooltip_root):
		return
	var layer: CanvasLayer = _TOOLTIP_SCENE.instantiate()
	layer.name = "ItemTooltipLayer"
	parent.get_tree().root.add_child.call_deferred(layer)
	_tooltip_root   = layer.get_node("ItemTooltip")
	_tooltip_stripe = _tooltip_root.get_node("TooltipStripe")
	_tooltip_name   = _tooltip_root.get_node("TooltipName")
	_tooltip_rarity = _tooltip_root.get_node("TooltipRarity")
	_tooltip_sep    = _tooltip_root.get_node("TooltipSep")
	_tooltip_desc   = _tooltip_root.get_node("TooltipDesc")


static func _show_tooltip(item: ItemResource) -> void:
	if not is_instance_valid(_tooltip_root) or item == null:
		return
	if not _tooltip_root.is_inside_tree() or _tooltip_stripe == null:
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

	_tooltip_root.size    = Vector2(W, h)
	_tooltip_root.visible = true


static func _hide_tooltip() -> void:
	if is_instance_valid(_tooltip_root):
		_tooltip_root.visible = false


# ── Cursor icon singleton ────────────────────────────────────────────────────

static func _init_cursor_icon(parent: Node) -> void:
	if is_instance_valid(cursor_icon):
		return
	var layer: CanvasLayer = _CURSOR_SCENE.instantiate()
	layer.name = "CursorIconLayer"
	parent.get_tree().root.add_child.call_deferred(layer)
	cursor_icon = layer.get_node("CursorHeldItem")


# ── Per-frame update ─────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if is_instance_valid(cursor_icon) and cursor_icon.visible:
		cursor_icon.position = cursor_icon.get_viewport().get_mouse_position() - (cursor_icon.size * cursor_icon.scale) / 2.0
	if item != null:
		_apply_slot_outline()
	if is_instance_valid(_tooltip_root) and _tooltip_root.visible and _tooltip_root.is_inside_tree():
		var vp := _tooltip_root.get_viewport()
		var mp := vp.get_mouse_position()
		var vs := vp.get_visible_rect().size
		var tw := _tooltip_root.size.x
		var th := _tooltip_root.size.y
		var tx := mp.x + 14.0
		var ty := mp.y - th - 8.0
		if tx + tw > vs.x - 4.0:
			tx = mp.x - tw - 10.0
		if ty < 4.0:
			ty = mp.y + 18.0
		_tooltip_root.position = Vector2(tx, ty)


# ── Input ────────────────────────────────────────────────────────────────────

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
	if not is_visible_in_tree():
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


# ── Visual state (NinePatchRect modulate only) ───────────────────────────────

func _update_selection_visuals() -> void:
	if slot_bg == null:
		return
	if _is_selected:
		slot_bg.self_modulate = TINT_SELECTED
		if txtr != null:
			txtr.modulate = Color(1.0, 1.0, 1.0, 0.6)
	elif is_hovered():
		slot_bg.self_modulate = TINT_HOVER
		if txtr != null:
			txtr.modulate = Color.WHITE
	else:
		slot_bg.self_modulate = TINT_NORMAL
		if txtr != null:
			txtr.modulate = Color.WHITE


func _apply_slot_outline() -> void:
	if txtr == null or not txtr.material is ShaderMaterial:
		return
	if item != null:
		var col = item.calculate_rarity_outline()
		txtr.material.set_shader_parameter("outline_color",     col if col != null else Color.WHITE)
		txtr.material.set_shader_parameter("outline_thickness", 2.0)
	else:
		txtr.material.set_shader_parameter("outline_color", Color.TRANSPARENT)


# ── Selection logic ──────────────────────────────────────────────────────────

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
	if is_instance_valid(new_item):
		item = new_item.duplicate(true)
		item.inv_slot = self
		item_count = count
		item.amount = count
	else:
		item = null
		item_count = 0
		done = false
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


# ── Hover signals ────────────────────────────────────────────────────────────

func _on_mouse_entered() -> void:
	_update_selection_visuals()
	if item != null and held_item == null:
		_show_tooltip(item)


func _on_mouse_exited() -> void:
	_update_selection_visuals()
	_hide_tooltip()


# ── Visuals ──────────────────────────────────────────────────────────────────

func update_visuals() -> void:
	# Guard: @onready vars may not be set yet if called before _ready
	if txtr == null:
		txtr         = get_node_or_null("ItemIcon")
		count_label  = get_node_or_null("ItemCount")
	if txtr == null:
		return
	if item != null:
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
	queue_redraw()


func _on_pressed() -> void:
	pass
