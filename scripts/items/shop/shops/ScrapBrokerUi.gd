extends Control
class_name ScrapBrokerUI

const C_BG         := Color(0.09, 0.10, 0.12)
const C_PANEL      := Color(0.13, 0.14, 0.17)
const C_PANEL_DARK := Color(0.08, 0.09, 0.11)
const C_BORDER     := Color(0.22, 0.24, 0.28)
const C_ACCENT     := Color(0.90, 0.65, 0.20)
const C_ACCENT_DIM := Color(0.60, 0.42, 0.10)
const C_TEXT       := Color(0.92, 0.90, 0.85)
const C_TEXT_DIM   := Color(0.55, 0.53, 0.50)
const C_GREEN      := Color(0.35, 0.80, 0.45)
const C_RED        := Color(0.90, 0.35, 0.30)
const C_SPIRIT     := Color(0.55, 0.85, 1.00)

const RADIUS  := 9
const SIDE_PAD     := 12
const SIDE_W       := 240
const SIDE_SLOT    := 54
const SIDE_GAP     := 5
const SIDE_COLS    := 4
const SIDE_MAX_H   := 420

const SHARD_RANGES: Dictionary = {
	0: Vector2(40,   120),
	1: Vector2(120,  280),
	2: Vector2(280,  600),
	3: Vector2(600,  1400),
	4: Vector2(1400, 3500),
}

const SPIRIT_CHANCE: Dictionary = {
	0: 0.0,
	1: 0.0,
	2: 0.02,
	3: 0.08,
	4: 0.22,
}

@onready var _main_panel:       Control     = $MainPanel
@onready var _slot_visual:      TextureRect = $MainPanel/Background/SlotPanel/SlotVisual
@onready var _slot_border:      Panel       = $MainPanel/Background/SlotPanel/SlotBorder
@onready var _slot_count_label: Label       = $MainPanel/Background/SlotPanel/SlotCountLabel
@onready var _name_label:       Label       = $MainPanel/Background/NameLabel
@onready var _rarity_label:     Label       = $MainPanel/Background/RarityLabel
@onready var _shard_label:      Label       = $MainPanel/Background/ShardLabel
@onready var _spirit_label:     Label       = $MainPanel/Background/SpiritLabel
@onready var _convert_btn:      Button      = $MainPanel/Background/ConvertBtn
@onready var _feedback_label:   Label       = $MainPanel/Background/FeedbackLabel
@onready var _title_label:      Label       = $MainPanel/Background/TitleLabel
@onready var _drop_zone:        Control     = $MainPanel/Background/DropZone

var _slot_item: ItemResource = null
var _slot_count: int = 0
var _spirit_core_resource: ItemResource = null

var _inv_panel: Control
var _inv_scroll: ScrollContainer
var _inv_grid: Control
var _inv_cap_label: Label
var _inv_slots: Array = []

var _safe_panel: Control
var _safe_scroll: ScrollContainer
var _safe_grid: Control
var _safe_cap_label: Label
var _safe_slots: Array = []
var _safe_slots_with_items := []
var _safe_occupied: int = 0


func _ready() -> void:
	if not get_parent() is CanvasLayer:
		var cl        := CanvasLayer.new()
		cl.layer       = 8
		cl.name        = "ScrapBrokerLayer"
		get_tree().root.call_deferred("add_child", cl)
		await get_tree().process_frame
		get_parent().remove_child(self)
		cl.add_child(self)

	_center_panel()
	_build_side_panels()
	hide()


func _center_panel() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_main_panel.position = Vector2(
		(viewport_size.x - 820.0) / 2.0,
		(viewport_size.y - 560.0) / 2.0
	)


func _build_side_panels() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var center_x := (viewport_size.x - 820.0) / 2.0
	var center_y := (viewport_size.y - 560.0) / 2.0

	_inv_panel = _build_side_panel("INVENTORY", Vector2(center_x - SIDE_W - SIDE_PAD, center_y))
	add_child(_inv_panel)
	_inv_cap_label = _inv_panel.get_meta("cap_label")
	_inv_scroll    = _inv_panel.get_meta("scroll")
	_inv_grid      = _inv_panel.get_meta("grid")

	_safe_panel = _build_side_panel("SAFE", Vector2(center_x + 820.0 + SIDE_PAD, center_y))
	add_child(_safe_panel)
	_safe_cap_label = _safe_panel.get_meta("cap_label")
	_safe_scroll    = _safe_panel.get_meta("scroll")
	_safe_grid      = _safe_panel.get_meta("grid")


func _build_side_panel(title_text: String, pos: Vector2) -> Control:
	var panel_w  := SIDE_W
	var header_h := 38
	var panel_h  := SIDE_MAX_H

	var root       := Control.new()
	root.position   = pos
	root.size       = Vector2(panel_w, panel_h)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shadow_sb := StyleBoxFlat.new()
	shadow_sb.bg_color = Color(0, 0, 0, 0.35)
	shadow_sb.set_corner_radius_all(RADIUS)
	var shadow_panel := Panel.new()
	shadow_panel.position = Vector2(-4, -4)
	shadow_panel.size     = Vector2(panel_w + 8, panel_h + 8)
	shadow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow_panel.add_theme_stylebox_override("panel", shadow_sb)
	root.add_child(shadow_panel)

	var bg_npr := NinePatchRect.new()
	bg_npr.size = Vector2(panel_w, panel_h)
	bg_npr.patch_margin_left = RADIUS
	bg_npr.patch_margin_top = RADIUS
	bg_npr.patch_margin_right = RADIUS
	bg_npr.patch_margin_bottom = RADIUS
	bg_npr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg_npr)

	var bg_fill := ColorRect.new()
	bg_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_fill.color = C_BG
	bg_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_npr.add_child(bg_fill)

	var stripe := ColorRect.new()
	stripe.color     = C_ACCENT
	stripe.size      = Vector2(panel_w, 3)
	stripe.position  = Vector2.ZERO
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_npr.add_child(stripe)

	var title_lbl := Label.new()
	title_lbl.text = title_text
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", C_ACCENT)
	title_lbl.position = Vector2(SIDE_PAD, 7)
	title_lbl.size     = Vector2(panel_w - SIDE_PAD * 2, 22)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_npr.add_child(title_lbl)

	var cap_lbl := Label.new()
	cap_lbl.add_theme_font_size_override("font_size", 11)
	cap_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	cap_lbl.position = Vector2(SIDE_PAD, 7)
	cap_lbl.size     = Vector2(panel_w - SIDE_PAD * 2, 22)
	cap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cap_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_npr.add_child(cap_lbl)

	var sep := ColorRect.new()
	sep.color    = C_BORDER
	sep.size     = Vector2(panel_w - SIDE_PAD * 2, 1)
	sep.position = Vector2(SIDE_PAD, 30)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_npr.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(SIDE_PAD, header_h)
	scroll.size     = Vector2(panel_w - SIDE_PAD * 2, panel_h - header_h - SIDE_PAD)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode  = ScrollContainer.SCROLL_MODE_AUTO

	var scroll_sb := StyleBoxFlat.new()
	scroll_sb.bg_color = Color.TRANSPARENT
	scroll.add_theme_stylebox_override("panel", scroll_sb)

	bg_npr.add_child(scroll)

	var grid := Control.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(grid)

	root.set_meta("cap_label", cap_lbl)
	root.set_meta("scroll", scroll)
	root.set_meta("grid", grid)

	return root


func open() -> void:
	_slot_item = null
	_slot_count = 0
	_refresh_slot()
	_refresh_preview()
	_rebuild_inv_slots()
	_rebuild_safe_slots()
	show()
	_animate_in()


func close() -> void:
	if _slot_item != null:
		_return_slot_item()
	_slot_item = null
	_slot_count = 0
	_save_safe_back()
	hide()


func set_spirit_core_resource(res: ItemResource) -> void:
	_spirit_core_resource = res


func _rebuild_inv_slots() -> void:
	_inv_slots.clear()
	for child in _inv_grid.get_children():
		child.queue_free()

	if not is_instance_valid(GlobalPlayer.inventory):
		return
	var inv: ActualInv = GlobalPlayer.inventory.inventory
	if inv == null:
		return

	var slot_scene_res = preload("res://scenes/Player/inventory/InventorySlot.tscn")
	var idx := 0
	for src_slot in inv.slots:
		var slot = slot_scene_res.instantiate()
		slot.slot_index          = idx
		slot.custom_minimum_size = Vector2(SIDE_SLOT, SIDE_SLOT)
		slot.size                = Vector2(SIDE_SLOT, SIDE_SLOT)

		var col := idx % SIDE_COLS
		var row := idx / SIDE_COLS
		slot.position = Vector2(col * (SIDE_SLOT + SIDE_GAP), row * (SIDE_SLOT + SIDE_GAP))

		_inv_grid.add_child(slot)

		if src_slot.item != null:
			slot.set_item(src_slot.item, src_slot.item_count)
		_inv_slots.append(slot)
		idx += 1

	var rows := ceili(float(idx) / float(SIDE_COLS))
	_inv_grid.custom_minimum_size = Vector2(
		SIDE_COLS * SIDE_SLOT + (SIDE_COLS - 1) * SIDE_GAP,
		rows * SIDE_SLOT + maxi(rows - 1, 0) * SIDE_GAP
	)
	_inv_cap_label.text = "%d / %d" % [inv.occupiedSlots, inv.slotAmount]


func _rebuild_safe_slots() -> void:
	_safe_slots.clear()
	_safe_slots_with_items.clear()
	_safe_occupied = 0
	for child in _safe_grid.get_children():
		child.queue_free()

	var slot_scene_res = preload("res://scenes/Player/inventory/InventorySlot.tscn")
	var safe_items: Array = GlobalSafe.safe
	var count := maxi(safe_items.size() + 8, 24)

	for i in range(count):
		var slot = slot_scene_res.instantiate()
		slot.slot_index          = i
		slot.is_safe_slot        = true
		slot.custom_minimum_size = Vector2(SIDE_SLOT, SIDE_SLOT)
		slot.size                = Vector2(SIDE_SLOT, SIDE_SLOT)
		slot.connect("item_changed", Callable(self, "_on_safe_slot_changed"))

		var col := i % SIDE_COLS
		var row := i / SIDE_COLS
		slot.position = Vector2(col * (SIDE_SLOT + SIDE_GAP), row * (SIDE_SLOT + SIDE_GAP))

		_safe_grid.add_child(slot)
		_safe_slots.append(slot)

	for idx in range(safe_items.size()):
		if idx < _safe_slots.size():
			var item = safe_items[idx]
			_safe_slots[idx].set_item(item, item.amount)
			_safe_slots_with_items.append(_safe_slots[idx])
			_safe_occupied += 1

	_resize_safe_grid()
	_safe_cap_label.text = "%d" % _safe_occupied


func _on_safe_slot_changed(index: int) -> void:
	if index < 0 or index >= _safe_slots.size():
		return
	var slot = _safe_slots[index]
	if slot.item != null:
		if not _safe_slots_with_items.has(slot):
			_safe_slots_with_items.append(slot)
			_safe_occupied += 1
	else:
		if _safe_slots_with_items.has(slot):
			_safe_slots_with_items.erase(slot)
			_safe_occupied -= 1
	_safe_cap_label.text = "%d" % _safe_occupied

	if _safe_occupied >= _safe_slots.size() - 2:
		_expand_safe_slots(8)


func _expand_safe_slots(amount: int) -> void:
	var slot_scene_res = preload("res://scenes/Player/inventory/InventorySlot.tscn")
	var start := _safe_slots.size()
	for i in range(amount):
		var idx  := start + i
		var slot  = slot_scene_res.instantiate()
		slot.slot_index          = idx
		slot.is_safe_slot        = true
		slot.custom_minimum_size = Vector2(SIDE_SLOT, SIDE_SLOT)
		slot.size                = Vector2(SIDE_SLOT, SIDE_SLOT)
		slot.connect("item_changed", Callable(self, "_on_safe_slot_changed"))

		var col := idx % SIDE_COLS
		var row := idx / SIDE_COLS
		slot.position = Vector2(col * (SIDE_SLOT + SIDE_GAP), row * (SIDE_SLOT + SIDE_GAP))

		_safe_grid.add_child(slot)
		_safe_slots.append(slot)
	_resize_safe_grid()


func _resize_safe_grid() -> void:
	var rows := ceili(float(_safe_slots.size()) / float(SIDE_COLS))
	_safe_grid.custom_minimum_size = Vector2(
		SIDE_COLS * SIDE_SLOT + (SIDE_COLS - 1) * SIDE_GAP,
		rows * SIDE_SLOT + maxi(rows - 1, 0) * SIDE_GAP
	)


func _save_safe_back() -> void:
	GlobalSafe.safe.clear()
	for slot in _safe_slots_with_items:
		if slot.item != null:
			GlobalSafe.safe.append(slot.item)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		return
	if _drop_zone == null:
		return
	if not _drop_zone.get_global_rect().has_point(get_global_mouse_position()):
		return
	if InventorySlot.held_item == null:
		return
	if not InventorySlot.held_item.isMaterial:
		return
	get_viewport().set_input_as_handled()
	var incoming_item: ItemResource = InventorySlot.held_item
	var incoming_count: int = InventorySlot.held_count
	InventorySlot.held_item = null
	InventorySlot.held_count = 0
	if is_instance_valid(InventorySlot.cursor_icon):
		InventorySlot.cursor_icon.texture = null
		InventorySlot.cursor_icon.visible = false
	if _slot_item != null:
		InventorySlot.held_item = _slot_item
		InventorySlot.held_count = _slot_count
		InventorySlot._apply_cursor_icon(_slot_item)
	_slot_item = incoming_item
	_slot_count = incoming_count
	_refresh_slot()
	_refresh_preview()


func _on_clear_pressed() -> void:
	if _slot_item == null:
		return
	_return_slot_item()
	_slot_item = null
	_slot_count = 0
	_refresh_slot()
	_refresh_preview()


func _return_slot_item() -> void:
	if _slot_item == null:
		return
	if GlobalPlayer.inventory and GlobalPlayer.inventory.inventory.has_method("add_item"):
		GlobalPlayer.inventory.inventory.add_item(_slot_item, _slot_count)
	_slot_item = null
	_slot_count = 0


func _on_convert_pressed() -> void:
	if _slot_item == null:
		return

	var rarity_idx: int  = _slot_item.rarity
	var range_v: Vector2 = SHARD_RANGES.get(rarity_idx, Vector2(40, 120))
	var shards_earned    := roundf(randf_range(range_v.x, range_v.y))

	var got_spirit       := false
	var spirit_chance: float = SPIRIT_CHANCE.get(rarity_idx, 0.0)
	if spirit_chance > 0.0 and randf() < spirit_chance:
		got_spirit = true

	if GameManager.is_in_lobby:
		GlobalSafe.shards += shards_earned
		GlobalPlayer.player.get_parent().shard_counter_lobby.change_amount(shards_earned)
	else:
		GlobalPlayer.stats.add_shards(shards_earned)

	if got_spirit and _spirit_core_resource != null:
		var core := _spirit_core_resource.duplicate(true)
		if core.isStackable:
			core.amount = 1
		if GlobalPlayer.inventory and GlobalPlayer.inventory.inventory.has_method("add_item"):
			GlobalPlayer.inventory.inventory.add_item(core)

	_slot_item = null
	_slot_count = 0
	_refresh_slot()
	_refresh_preview()

	var msg := "+%d shards" % int(shards_earned)
	if got_spirit:
		msg += "  +  Spirit Core!"
		_show_feedback(msg, C_SPIRIT)
	else:
		_show_feedback(msg, C_GREEN)


func _show_feedback(msg: String, col: Color) -> void:
	_feedback_label.text     = msg
	_feedback_label.modulate = col
	var tw := create_tween()
	tw.tween_property(_feedback_label, "modulate", Color(col.r, col.g, col.b, 0.0), 2.0)


func _refresh_slot() -> void:
	if _slot_item == null:
		_slot_visual.texture   = null
		_slot_count_label.text = ""
		var sb := StyleBoxFlat.new()
		sb.bg_color     = Color.TRANSPARENT
		sb.border_color = Color.TRANSPARENT
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(RADIUS)
		_slot_border.add_theme_stylebox_override("panel", sb)
	else:
		_slot_visual.texture = _slot_item.txtr
		if _slot_item.isStackable and _slot_count > 1:
			_slot_count_label.text = "x%d" % _slot_count
		else:
			_slot_count_label.text = ""
		var rarity_col := _rarity_color(_slot_item.rarity)
		var sb         := StyleBoxFlat.new()
		sb.bg_color     = Color.TRANSPARENT
		sb.border_color = rarity_col
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(RADIUS)
		_slot_border.add_theme_stylebox_override("panel", sb)


func _refresh_preview() -> void:
	if _slot_item == null:
		_name_label.text      = "— select a material —"
		_name_label.modulate  = C_TEXT_DIM
		_rarity_label.text    = ""
		_shard_label.text     = ""
		_spirit_label.text    = ""
		_convert_btn.disabled = true
		_style_action_btn(_convert_btn, true)
		return

	var rarity_idx           = _slot_item.rarity
	var rarity_names         := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	var rarity_col           := _rarity_color(rarity_idx)

	_name_label.text     = _slot_item.Name.to_upper()
	_name_label.modulate = Color.WHITE
	_rarity_label.text     = rarity_names[clampi(rarity_idx, 0, 4)].to_upper()
	_rarity_label.modulate = rarity_col

	var range_v: Vector2 = SHARD_RANGES.get(rarity_idx, Vector2(40, 120))
	_shard_label.text = "◈  %d – %d  shards" % [int(range_v.x), int(range_v.y)]

	var spirit_chance: float = SPIRIT_CHANCE.get(rarity_idx, 0.0)
	if spirit_chance > 0.0:
		_spirit_label.text     = "%.0f%% chance: Spirit Core" % (spirit_chance * 100.0)
		_spirit_label.modulate = C_SPIRIT
	else:
		_spirit_label.text     = "No Spirit Core chance"
		_spirit_label.modulate = C_TEXT_DIM
	_spirit_label.show()

	_convert_btn.disabled = false
	_style_action_btn(_convert_btn, false)


func _animate_in() -> void:
	modulate     = Color(1, 1, 1, 0)
	scale        = Vector2(0.92, 0.92)
	pivot_offset = get_viewport().get_visible_rect().size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate", Color.WHITE, 0.18)
	tw.tween_property(self, "scale",    Vector2.ONE,  0.18).set_trans(Tween.TRANS_BACK)


func _rarity_color(rarity_idx: int) -> Color:
	match rarity_idx:
		0: return Color(0.75, 0.75, 0.75)
		1: return Color(0.30, 0.85, 0.35)
		2: return Color(0.30, 0.55, 1.00)
		3: return Color(0.70, 0.30, 1.00)
		4: return Color(1.00, 0.60, 0.10)
	return Color.WHITE


func _style_action_btn(btn: Button, is_disabled: bool) -> void:
	var mk := func(col: Color) -> StyleBoxFlat:
		var s               := StyleBoxFlat.new()
		s.bg_color           = col
		s.set_corner_radius_all(RADIUS)
		s.content_margin_top    = 9
		s.content_margin_bottom = 9
		return s
	btn.add_theme_stylebox_override("normal",   mk.call(C_ACCENT_DIM if is_disabled else C_ACCENT))
	btn.add_theme_stylebox_override("hover",    mk.call(Color(1.00, 0.75, 0.25)))
	btn.add_theme_stylebox_override("pressed",  mk.call(Color(0.65, 0.45, 0.10)))
	btn.add_theme_stylebox_override("disabled", mk.call(C_ACCENT_DIM))
	btn.add_theme_color_override("font_color",          C_BG)
	btn.add_theme_color_override("font_hover_color",    C_BG)
	btn.add_theme_color_override("font_pressed_color",  C_BG)
	btn.add_theme_color_override("font_disabled_color", Color(C_BG.r, C_BG.g, C_BG.b, 0.4))
