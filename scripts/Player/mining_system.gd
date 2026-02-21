extends Node
class_name MiningSystem

static var instance: MiningSystem = null

const PROGRESS_BAR_WIDTH := 80.0
const PROGRESS_BAR_HEIGHT := 10.0
const PROGRESS_BAR_OFFSET := Vector2(-40.0, -80.0)

@onready var item_interactable_scene = preload("uid://cgwfugy5k2bsj")


var world_gen: Node2D = null

var _mining := false
var _mining_timer := 0.0
var _mining_target_block: MineableBlockResource = null
var _mining_target_layer: TileMapLayer = null
var _mining_target_cell: Vector2i = Vector2i.ZERO

var _ui_canvas: CanvasLayer = null
var _progress_bar_bg: ColorRect = null
var _progress_bar_fill: ColorRect = null

func _ready() -> void:
	instance = self
	world_gen = get_parent()
	_setup_ui()

func _setup_ui() -> void:
	_ui_canvas = CanvasLayer.new()
	_ui_canvas.layer = 99
	add_child(_ui_canvas)

	_progress_bar_bg = ColorRect.new()
	_progress_bar_bg.color = Color(0.1, 0.1, 0.1, 0.85)
	_progress_bar_bg.size = Vector2(PROGRESS_BAR_WIDTH, PROGRESS_BAR_HEIGHT)
	_progress_bar_bg.visible = false
	_ui_canvas.add_child(_progress_bar_bg)

	_progress_bar_fill = ColorRect.new()
	_progress_bar_fill.color = Color(0.9, 0.7, 0.1, 1.0)
	_progress_bar_fill.size = Vector2(0.0, PROGRESS_BAR_HEIGHT)
	_progress_bar_fill.visible = false
	_ui_canvas.add_child(_progress_bar_fill)

func _process(delta: float) -> void:
	if _mining:
		_tick_mining(delta)
	else:
		_hide_progress()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_start_mining()
		else:
			_cancel_mining()

func _try_start_mining() -> void:
	if BuildingSystem.instance != null and BuildingSystem.instance.active_item != null:
		return

	var pickaxe := _get_held_pickaxe()
	var mouse_pos := world_gen.get_global_mouse_position()

	for ly in range(world_gen.current_layer_y + 1, world_gen.current_layer_y - 2, -1):
		var layer = world_gen.get_layer_by_y(ly)
		if layer == null:
			continue
		var cell = layer.local_to_map(layer.to_local(mouse_pos))
		if layer.get_cell_tile_data(cell) == null:
			continue

		var source = layer.get_cell_source_id(cell)
		var atlas = layer.get_cell_atlas_coords(cell)
		var block = world_gen.get_mineable_block(source, atlas)
		if block == null:
			continue

		if pickaxe == null or pickaxe.tier < block.required_pickaxe_tier:
			return

		_start_mining(block, layer, cell)
		return

func _start_mining(block: MineableBlockResource, layer: TileMapLayer, cell: Vector2i) -> void:
	_mining = true
	_mining_timer = 0.0
	_mining_target_block = block
	_mining_target_layer = layer
	_mining_target_cell = cell
	_progress_bar_bg.visible = true
	_progress_bar_fill.visible = true

func _cancel_mining() -> void:
	_mining = false
	_mining_timer = 0.0
	_mining_target_block = null
	_mining_target_layer = null
	_hide_progress()

func _tick_mining(delta: float) -> void:
	if _mining_target_block == null or _mining_target_layer == null:
		_cancel_mining()
		return

	var current_cell := _get_mouse_cell(_mining_target_layer)
	if current_cell != _mining_target_cell:
		_cancel_mining()
		return

	_mining_timer += delta
	_update_progress_bar(_mining_timer / _mining_target_block.hardness)

	if _mining_timer >= _mining_target_block.hardness:
		_finish_mining()

func _finish_mining() -> void:
	var drops := _mining_target_block.roll_drops()
	var layer := _mining_target_layer
	var cell := _mining_target_cell
	var layer_z := layer.z_index

	var tile_world_pos := layer.to_global(layer.map_to_local(cell))

	layer.erase_cell(cell)
	_cancel_mining()

	_spawn_drops(drops, tile_world_pos, layer_z)

func _spawn_drops(drops: Array[Dictionary], world_pos: Vector2, layer_z: int) -> void:
	if item_interactable_scene == null:
		push_error("MiningSystem: item_interactable_scene is not set.")
		return
	if GlobalWorld == null or GlobalWorld.theWorld == null:
		push_error("MiningSystem: GlobalWorld.theWorld is not available.")
		return

	for drop in drops:
		var interactable := item_interactable_scene.instantiate()
		interactable.item = drop["item"]
		var count: int = drop["count"]
		var spread := Vector2(randf_range(-30.0, 30.0), randf_range(-20.0, 20.0))
		interactable.global_position = world_pos + spread
		interactable.z_index = layer_z + 1
		GlobalWorld.theWorld.add_child(interactable)
		if count > 1 and interactable.item is ItemResource:
			interactable.item = interactable.item.duplicate()
			interactable.item.amount = count

func _get_mouse_cell(layer: TileMapLayer) -> Vector2i:
	return layer.local_to_map(layer.to_local(world_gen.get_global_mouse_position()))

func _update_progress_bar(progress: float) -> void:
	if _mining_target_layer == null:
		return
	var tile_world_pos := _mining_target_layer.to_global(
		_mining_target_layer.map_to_local(_mining_target_cell)
	)
	var screen_pos := world_gen.get_viewport().get_canvas_transform() * tile_world_pos
	screen_pos += PROGRESS_BAR_OFFSET

	_progress_bar_bg.position = screen_pos
	_progress_bar_fill.position = screen_pos
	_progress_bar_fill.size.x = PROGRESS_BAR_WIDTH * clamp(progress, 0.0, 1.0)

func _hide_progress() -> void:
	if _progress_bar_bg != null:
		_progress_bar_bg.visible = false
	if _progress_bar_fill != null:
		_progress_bar_fill.visible = false

func _get_held_pickaxe() -> PickaxeItemResource:
	var slot := InventorySlot.currently_selected_slot
	if slot == null or slot.item == null:
		return null
	if slot.item is PickaxeItemResource:
		return slot.item as PickaxeItemResource
	return null
