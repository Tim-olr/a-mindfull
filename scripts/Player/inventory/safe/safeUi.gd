extends Control
class_name SafeUI

const C_BG         := Color(0.09, 0.10, 0.12)
const C_PANEL_DARK := Color(0.08, 0.09, 0.11)
const C_BORDER     := Color(0.22, 0.24, 0.28)
const C_ACCENT     := Color(0.90, 0.65, 0.20)
const C_TEXT       := Color(0.92, 0.90, 0.85)
const C_TEXT_DIM   := Color(0.55, 0.53, 0.50)
const C_GREEN      := Color(0.35, 0.80, 0.45)
const C_RED        := Color(0.90, 0.35, 0.30)

const RADIUS  := 9
const GRID_COLS := 4
const SLOT_SIZE := 64
const SLOT_GAP  := 6

@export var slotAmount: int = 24

var slots: Array = []
var slots_with_items: Array = []
var occupiedSlots: int = 0

const slot_scene = preload("res://scenes/Player/inventory/InventorySlot.tscn")

@onready var _main_panel:        Control  = $MainPanel
@onready var _grid_container:    Control  = $MainPanel/Background/GridContainer
@onready var _capacity_label:    Label    = $MainPanel/Background/CapacityLabel
@onready var _shard_stored_label: Label   = $MainPanel/Background/ShardBox/ShardStoredLabel
@onready var _shard_amount_input: LineEdit = $MainPanel/Background/ShardBox/ShardAmountInput
@onready var _shard_minus_btn:   Button   = $MainPanel/Background/ShardBox/ShardMinusBtn
@onready var _shard_plus_btn:    Button   = $MainPanel/Background/ShardBox/ShardPlusBtn
@onready var _shard_withdraw_btn: Button  = $MainPanel/Background/ShardBox/ShardWithdrawBtn


func _ready() -> void:
	if not get_parent() is CanvasLayer:
		var cl        := CanvasLayer.new()
		cl.layer       = 8
		cl.name        = "SafeUiLayer"
		get_tree().root.call_deferred("add_child", cl)
		await get_tree().process_frame
		get_parent().remove_child(self)
		cl.add_child(self)

	_center_panel()
	_rebuild_inv_slots()
	_update_capacity_label()
	_update_shard_label()
	hide()


func _center_panel() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_main_panel.position = Vector2(
		(viewport_size.x - 720.0) / 2.0,
		(viewport_size.y - 540.0) / 2.0
	)


func open() -> void:
	_rebuild_inv_slots()
	for item in GlobalSafe.safe:
		add_item(item, item.amount)
	_update_capacity_label()
	_update_shard_label()
	show()
	_animate_in()


func close() -> void:
	_save_and_close()


func _rebuild_inv_slots() -> void:
	slots.clear()
	slots_with_items.clear()
	occupiedSlots = 0
	for child in _grid_container.get_children():
		child.queue_free()

	for i in range(slotAmount):
		var slot = slot_scene.instantiate()
		slot.slot_index          = i
		slot.is_safe_slot        = true
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.size                = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.connect("item_changed", Callable(self, "_on_slot_item_changed"))

		var col := i % GRID_COLS
		var row := i / GRID_COLS
		slot.position = Vector2(col * (SLOT_SIZE + SLOT_GAP), row * (SLOT_SIZE + SLOT_GAP))

		_grid_container.add_child(slot)
		slots.append(slot)


func _animate_in() -> void:
	modulate     = Color(1, 1, 1, 0)
	scale        = Vector2(0.92, 0.92)
	pivot_offset = get_viewport().get_visible_rect().size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate", Color.WHITE, 0.18)
	tw.tween_property(self, "scale",    Vector2.ONE,  0.18).set_trans(Tween.TRANS_BACK)


func _save_and_close() -> void:
	GlobalSafe.safe.clear()
	for slot in slots_with_items:
		if slot.item != null:
			GlobalSafe.safe.append(slot.item)
	if is_instance_valid(InventorySlot.held_item):
		GlobalSafe.safe.append(InventorySlot.held_item)
		InventorySlot.held_item  = null
		InventorySlot.held_count = 0
		if is_instance_valid(InventorySlot.cursor_icon):
			InventorySlot.cursor_icon.texture = null
			InventorySlot.cursor_icon.visible = false
	hide()


func _on_close_pressed() -> void:
	_save_and_close()
	_notify_interactable_closed()


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
	_update_capacity_label()


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


func _notify_interactable_closed() -> void:
	if is_instance_valid(GlobalPlayer.manager):
		for area in GlobalPlayer.manager.interact_area.get_overlapping_areas():
			if area is Interactable and area._is_active:
				area.close_interaction()
				return


func _update_capacity_label() -> void:
	if _capacity_label != null:
		_capacity_label.text = "%d / %d" % [occupiedSlots, slotAmount]


func _shard_input_value() -> float:
	if _shard_amount_input == null:
		return 0.0
	var t := _shard_amount_input.text.strip_edges()
	if t.is_empty():
		return 0.0
	return maxf(0.0, t.to_float())


func _set_shard_input(v: float) -> void:
	if _shard_amount_input != null:
		_shard_amount_input.text = str(maxf(0.0, v))


func _on_shard_minus() -> void:
	_set_shard_input(_shard_input_value() - 1.0)


func _on_shard_plus() -> void:
	_set_shard_input(minf(GlobalSafe.shards, _shard_input_value() + 1.0))


func _on_shard_withdraw() -> void:
	var amount: float = _shard_input_value()
	if amount <= 0.0:
		return
	if amount > GlobalSafe.shards:
		amount = GlobalSafe.shards
	if amount <= 0.0:
		return
	GlobalSafe.shards -= amount
	GlobalPlayer.stats.add_shards(amount)
	_set_shard_input(0.0)
	_update_shard_label()


func _update_shard_label() -> void:
	if _shard_stored_label != null:
		_shard_stored_label.text = "◈  %s" % str(GlobalSafe.shards)
