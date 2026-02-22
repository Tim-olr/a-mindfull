extends Node
class_name BuildingSystem

static var instance: BuildingSystem = null

const NEIGHBOR_OFFSETS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var world_gen: Node2D = null
var active_item: PlaceableItemResource = null
var preview_layer: TileMapLayer = null
var current_preview_cell: Vector2i = Vector2i(-9999, -9999)
var current_target_layer_y: int = 0
var _placement_valid: bool = false
var _is_deactivating: bool = false

func _ready() -> void:
	instance = self
	world_gen = get_parent()
	_setup_preview()

func _setup_preview() -> void:
	preview_layer = TileMapLayer.new()
	preview_layer.tile_set = world_gen.my_tile_set
	preview_layer.scale = Vector2(world_gen.TILE_SCALE, world_gen.TILE_SCALE)
	preview_layer.z_index = 1000
	world_gen.add_child(preview_layer)

func activate(item: PlaceableItemResource) -> void:
	active_item = item

func deactivate() -> void:
	if _is_deactivating:
		return
	_is_deactivating = true
	active_item = null
	_placement_valid = false
	_clear_preview()
	_is_deactivating = false

func _process(_delta: float) -> void:
	if active_item == null:
		_clear_preview()
		return
	_update_preview()

func _input(event: InputEvent) -> void:
	if active_item == null:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_viewport().set_input_as_handled()
			_try_place()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			get_viewport().set_input_as_handled()
			if InventorySlot.currently_selected_slot != null:
				InventorySlot.currently_selected_slot.deselect()
			else:
				deactivate()

func _update_preview() -> void:
	_clear_preview()
	current_preview_cell = Vector2i(-9999, -9999)
	_placement_valid = false

	var mouse_pos := world_gen.get_global_mouse_position()
	var result := _find_placement(mouse_pos)
	if result.is_empty():
		return

	var target_layer: TileMapLayer = result["layer"]
	var cell: Vector2i = result["cell"]

	current_preview_cell = cell
	current_target_layer_y = target_layer.y_cord
	_placement_valid = true

	preview_layer.position = target_layer.position
	preview_layer.modulate = Color(1.0, 1.0, 1.0, 0.5)
	preview_layer.set_cell(cell, active_item.source_id, active_item.atlas_coord)

func _get_top_occupied_layer_at(cell: Vector2i) -> TileMapLayer:
	var best: TileMapLayer = null
	for layer in world_gen.all_layers:
		if layer.get_cell_tile_data(cell) != null:
			if best == null or int(layer.y_cord) > int(best.y_cord):
				best = layer
	return best

func _find_placement(mouse_pos: Vector2) -> Dictionary:
	var sorted_layers = world_gen.all_layers.duplicate()
	sorted_layers.sort_custom(func(a, b): return int(a.y_cord) > int(b.y_cord))

	for layer in sorted_layers:
		var cell: Vector2i = layer.local_to_map(layer.to_local(mouse_pos))

		if layer.get_cell_tile_data(cell) != null:
			var above_layer = world_gen.get_or_create_build_layer(int(layer.y_cord) + 1)
			if above_layer == null:
				continue
			if above_layer.get_cell_tile_data(cell) != null:
				continue
			return {"layer": above_layer, "cell": cell}

	for layer in sorted_layers:
		var cell: Vector2i = layer.local_to_map(layer.to_local(mouse_pos))

		if layer.get_cell_tile_data(cell) != null:
			continue

		if _has_horizontal_neighbor(layer, cell):
			var top := _get_top_occupied_layer_at(cell)
			if top != null:
				continue
			return {"layer": layer, "cell": cell}

		var below_layer = world_gen.get_layer_by_y(int(layer.y_cord) - 1)
		if below_layer != null and below_layer.get_cell_tile_data(cell) != null:
			var top := _get_top_occupied_layer_at(cell)
			if top != null and int(top.y_cord) >= int(layer.y_cord):
				continue
			return {"layer": layer, "cell": cell}

	return {}

func _has_horizontal_neighbor(layer: TileMapLayer, cell: Vector2i) -> bool:
	for offset in NEIGHBOR_OFFSETS:
		if layer.get_cell_tile_data(cell + offset) != null:
			return true
	return false

func _clear_preview() -> void:
	if preview_layer != null:
		preview_layer.clear()

func _try_place() -> void:
	if not _placement_valid or current_preview_cell == Vector2i(-9999, -9999) or active_item == null:
		return

	var target_layer = world_gen.get_or_create_build_layer(current_target_layer_y)
	if target_layer == null:
		return

	if target_layer.get_cell_tile_data(current_preview_cell) != null:
		return

	target_layer.set_cell(current_preview_cell, active_item.source_id, active_item.atlas_coord)
	world_gen.refresh_stepping_sides_for_cell(target_layer, current_preview_cell)

	var slot := InventorySlot.currently_selected_slot
	if slot == null:
		return
	if slot.item_count > 1:
		slot.set_item(slot.item, slot.item_count - 1)
	else:
		slot.set_item(null, 0)
		deactivate()
