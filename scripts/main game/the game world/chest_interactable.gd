extends Interactable
class_name ChestInteractable

const CHEST_UI_SCENE = preload("res://scenes/main game/The game world/chest_ui.tscn")

@export var loot_pool: ChestLootPool

var _chest_ui: ChestUI
var _opened: bool = false
var _chest_items: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	Name        = "Chest"
	description = "A chest containing loot."
	_chest_ui   = CHEST_UI_SCENE.instantiate()
	get_tree().root.call_deferred("add_child", _chest_ui)


func _exit_tree() -> void:
	if is_instance_valid(_chest_ui):
		_chest_ui.queue_free()


func interacted() -> void:
	if _is_active:
		close_interaction()
		return
	_is_active = true
	if not _opened:
		_roll_loot()
		_opened = true
	_chest_ui.open(_chest_items, self)


func close_interaction() -> void:
	super.close_interaction()
	if is_instance_valid(_chest_ui):
		_chest_ui.close()


func take_item(index: int) -> void:
	if index < 0 or index >= _chest_items.size():
		return
	var entry = _chest_items[index]
	GlobalPlayer.inventory.inventory.add_item(entry["item"], entry["count"])
	_chest_items.remove_at(index)
	_chest_ui.refresh(_chest_items)


func take_all() -> void:
	var remaining: Array = []
	for entry in _chest_items:
		if not GlobalPlayer.inventory.inventory.add_item(entry["item"], entry["count"]):
			remaining.append(entry)
	_chest_items = remaining
	_chest_ui.refresh(_chest_items)


func _roll_loot() -> void:
	if loot_pool == null:
		return
	_chest_items = loot_pool.roll_loot(_rng)
