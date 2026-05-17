extends Interactable
class_name ChestInteractable

const CHEST_UI_SCENE = preload("res://scenes/main game/The game world/chest_ui.tscn")

const GATHER_BASE_TIME := 2.0  # seconds to open at gathering_speed 1.0

# Bar dimensions in world-space pixels (relative to chest origin)
const BAR_W      := 44.0
const BAR_H      := 6.0
const BAR_Y      := -28.0  # above chest
const C_BAR_BG   := Color(0.15, 0.15, 0.15, 0.95)
const C_BAR_FILL := Color(0.90, 0.65, 0.20)
const C_BAR_BDR  := Color(0.05, 0.05, 0.05, 0.95)
const C_HIGHLIGHT := Color(1.35, 1.22, 0.85)

@export var loot_pool: ChestLootPool

var _chest_ui: ChestUI
var _opened: bool = false
var _chest_items: Array = []
var _rng := RandomNumberGenerator.new()

var _gathering: bool = false
var _gather_elapsed: float = 0.0
var _gather_duration: float = 0.0
var _gather_progress: float = 0.0
var _bar_node: Node2D = null

var _player_nearby: bool = false


func _ready() -> void:
	_rng.randomize()
	Name        = "Chest"
	description = "A chest containing loot."
	_chest_ui   = CHEST_UI_SCENE.instantiate()
	get_tree().root.call_deferred("add_child", _chest_ui)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _exit_tree() -> void:
	if is_instance_valid(_chest_ui):
		_chest_ui.queue_free()
	_cancel_gather()


func _process(delta: float) -> void:
	if not _gathering:
		return
	_gather_elapsed += delta
	_gather_progress = clampf(_gather_elapsed / _gather_duration, 0.0, 1.0)
	if is_instance_valid(_bar_node):
		_bar_node.queue_redraw()
	if _gather_elapsed >= _gather_duration:
		_gathering = false
		_finish_gathering()


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


# ── Outline highlight ────────────────────────────────────────────────────────

func _on_area_entered(area: Area2D) -> void:
	if GlobalPlayer.manager != null and area == GlobalPlayer.manager.interact_area:
		_player_nearby = true
		_set_highlight(true)

func _on_area_exited(area: Area2D) -> void:
	if GlobalPlayer.manager != null and area == GlobalPlayer.manager.interact_area:
		_player_nearby = false
		_set_highlight(false)

func _set_highlight(on: bool) -> void:
	var chest_root = get_parent()
	if chest_root != null:
		chest_root.modulate = C_HIGHLIGHT if on else Color.WHITE


# ── Gathering progress bar (world-space) ─────────────────────────────────────

func _start_gathering() -> void:
	_gathering = true
	_gather_elapsed = 0.0
	_gather_progress = 0.0
	var gs := 1.0
	if GlobalPlayer.stats != null:
		gs = maxf(0.1, GlobalPlayer.stats.gathering_speed)
	_gather_duration = GATHER_BASE_TIME / gs

	_bar_node = Node2D.new()
	_bar_node.z_index = 10
	add_child(_bar_node)
	_bar_node.draw.connect(_draw_gather_bar)


func _draw_gather_bar() -> void:
	if _bar_node == null:
		return
	var bx := -BAR_W / 2.0
	var by := BAR_Y
	# Border
	_bar_node.draw_rect(Rect2(bx - 1, by - 1, BAR_W + 2, BAR_H + 2), C_BAR_BDR)
	# Background
	_bar_node.draw_rect(Rect2(bx, by, BAR_W, BAR_H), C_BAR_BG)
	# Fill
	if _gather_progress > 0.0:
		_bar_node.draw_rect(Rect2(bx, by, BAR_W * _gather_progress, BAR_H), C_BAR_FILL)


func _finish_gathering() -> void:
	_clear_bar()
	if not _opened:
		_roll_loot()
		_opened = true
	if is_instance_valid(_chest_ui):
		_chest_ui.open(_chest_items, self)


func _cancel_gather() -> void:
	_gathering = false
	_gather_elapsed = 0.0
	_gather_progress = 0.0
	_clear_bar()


func _clear_bar() -> void:
	if is_instance_valid(_bar_node):
		_bar_node.queue_free()
	_bar_node = null


# ── Loot ──────────────────────────────────────────────────────────────────────

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
