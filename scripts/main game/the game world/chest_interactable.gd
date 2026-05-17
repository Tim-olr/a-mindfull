extends Interactable
class_name ChestInteractable

const CHEST_UI_SCENE = preload("res://scenes/main game/The game world/chest_ui.tscn")

const GATHER_BASE_TIME := 2.0  # seconds to open at gathering_speed 1.0

@export var loot_pool: ChestLootPool

var _chest_ui: ChestUI
var _opened: bool = false
var _chest_items: Array = []
var _rng := RandomNumberGenerator.new()

var _gathering: bool = false
var _gather_tween: Tween = null
var _gather_ui: CanvasLayer = null
var _gather_bar: ProgressBar = null


func _ready() -> void:
	_rng.randomize()
	Name        = "Chest"
	description = "A chest containing loot."
	_chest_ui   = CHEST_UI_SCENE.instantiate()
	get_tree().root.call_deferred("add_child", _chest_ui)


func _exit_tree() -> void:
	if is_instance_valid(_chest_ui):
		_chest_ui.queue_free()
	_cancel_gather()


func interacted() -> void:
	if _is_active:
		close_interaction()
		return
	_is_active = true
	if _gathering:
		return
	_start_gathering()


func close_interaction() -> void:
	super.close_interaction()
	_cancel_gather()
	if is_instance_valid(_chest_ui):
		_chest_ui.close()


func _start_gathering() -> void:
	_gathering = true
	var gs := 1.0
	if GlobalPlayer.stats != null:
		gs = maxf(0.1, GlobalPlayer.stats.gathering_speed)
	var duration := GATHER_BASE_TIME / gs

	# Build a small progress bar overlay at the bottom of the screen
	_gather_ui = CanvasLayer.new()
	_gather_ui.layer = 8
	get_tree().root.add_child(_gather_ui)

	var vp := get_viewport().get_visible_rect().size
	var bar_w := 240.0
	var bar_h := 22.0

	var bg := ColorRect.new()
	bg.color    = Color(0.08, 0.09, 0.11, 0.92)
	bg.size     = Vector2(bar_w + 24, bar_h + 28)
	bg.position = Vector2((vp.x - bg.size.x) * 0.5, vp.y - bg.size.y - 16)
	_gather_ui.add_child(bg)

	var lbl := Label.new()
	lbl.text = "Opening chest..."
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.76))
	lbl.position = Vector2(12, 4)
	lbl.size     = Vector2(bar_w, 18)
	bg.add_child(lbl)

	_gather_bar = ProgressBar.new()
	_gather_bar.min_value = 0.0
	_gather_bar.max_value = 1.0
	_gather_bar.value     = 0.0
	_gather_bar.show_percentage = false
	_gather_bar.size     = Vector2(bar_w, bar_h)
	_gather_bar.position = Vector2(12, 22)
	bg.add_child(_gather_bar)

	# Animate the progress bar over the gather duration
	_gather_tween = create_tween()
	_gather_tween.tween_property(_gather_bar, "value", 1.0, duration)
	_gather_tween.tween_callback(_finish_gathering)


func _finish_gathering() -> void:
	_gathering = false
	_clear_gather_ui()
	if not _opened:
		_roll_loot()
		_opened = true
	if is_instance_valid(_chest_ui):
		_chest_ui.open(_chest_items, self)


func _cancel_gather() -> void:
	if _gathering:
		_gathering = false
	if _gather_tween != null:
		_gather_tween.kill()
		_gather_tween = null
	_clear_gather_ui()


func _clear_gather_ui() -> void:
	if is_instance_valid(_gather_ui):
		_gather_ui.queue_free()
	_gather_ui = null
	_gather_bar = null


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
	var luck := 0.0
	if GlobalPlayer.stats != null:
		luck = GlobalPlayer.stats.luck
	_chest_items = loot_pool.roll_loot(_rng, luck)
