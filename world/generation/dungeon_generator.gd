extends Node2D
class_name DungeonGenerator

signal generation_finished(rooms: Dictionary)

const DIR_NORTH := Vector2i(0, -1)
const DIR_SOUTH := Vector2i(0, 1)
const DIR_WEST := Vector2i(-1, 0)
const DIR_EAST := Vector2i(1, 0)
const DIRECTIONS: Array[Vector2i] = [DIR_NORTH, DIR_SOUTH, DIR_WEST, DIR_EAST]

@export var floor_config: FloorConfig
@export var default_room_scene: PackedScene = preload("res://world/generation/room.tscn")
@export var door_scene: PackedScene = preload("res://world/generation/door.tscn")
@export var auto_generate: bool = false
@export var use_random_seed: bool = true
@export var seed_value: int = 0

var rooms: Dictionary = {}
var connections: Dictionary = {}  # Vector2i -> Array[Vector2i], published copy of _connections for UI (minimap)

var _rng: RandomNumberGenerator
var _occupied: Dictionary = {}
var _connections: Dictionary = {}

func _ready() -> void:
	if auto_generate:
		generate()

func clear() -> void:
	for child in get_children():
		child.queue_free()
	rooms.clear()
	connections.clear()
	_occupied.clear()
	_connections.clear()

func generate() -> Dictionary:
	clear()
	_rng = RandomNumberGenerator.new()
	if use_random_seed:
		_rng.randomize()
	else:
		_rng.seed = seed_value

	var target_count := _rng.randi_range(floor_config.min_rooms, floor_config.max_rooms)
	_build_layout(target_count)
	var types := _assign_room_types(Vector2i.ZERO)
	rooms = _instantiate_rooms(types)
	connections = _connections
	generation_finished.emit(rooms)
	return rooms

func _shuffled(arr: Array) -> Array:
	var result := arr.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result

func _neighbor_count(cell: Vector2i) -> int:
	var count := 0
	for dir in DIRECTIONS:
		if _occupied.has(cell + dir):
			count += 1
	return count

func _build_layout(target_count: int) -> void:
	var start := Vector2i.ZERO
	_occupied[start] = true
	_connections[start] = []
	var frontier: Array[Vector2i] = [start]

	while _occupied.size() < target_count and not frontier.is_empty():
		var cell: Vector2i = frontier[_rng.randi_range(0, frontier.size() - 1)]
		var placed_here := false
		for dir in _shuffled(DIRECTIONS):
			if _occupied.size() >= target_count:
				break
			var next: Vector2i = cell + dir
			if _occupied.has(next) or _neighbor_count(next) > 1:
				continue
			if _rng.randf() > floor_config.branch_chance:
				continue
			_occupied[next] = true
			_connections[cell].append(next)
			_connections[next] = [cell]
			frontier.append(next)
			placed_here = true
		if not placed_here or _rng.randf() < floor_config.dead_end_chance:
			frontier.erase(cell)

	if floor_config.loop_chance > 0.0:
		for cell in _occupied.keys():
			for dir in DIRECTIONS:
				var next: Vector2i = cell + dir
				if not _occupied.has(next) or _connections[cell].has(next):
					continue
				if _rng.randf() < floor_config.loop_chance:
					_connections[cell].append(next)
					_connections[next].append(cell)

func _bfs_distances(start: Vector2i) -> Dictionary:
	var distances := {start: 0}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for neighbor in _connections.get(cell, []):
			if not distances.has(neighbor):
				distances[neighbor] = distances[cell] + 1
				queue.append(neighbor)
	return distances

func _assign_room_types(start: Vector2i) -> Dictionary:
	var types: Dictionary = {}
	for cell in _occupied.keys():
		types[cell] = &"normal"

	var distances := _bfs_distances(start)
	var available: Array = _occupied.keys().filter(func(c): return c != start)

	for special in floor_config.special_rooms:
		var candidates: Array = available.filter(func(c): return distances.get(c, 0) >= special.min_distance)
		match special.placement:
			SpecialRoomData.Placement.DEAD_END:
				candidates = candidates.filter(func(c): return _connections.get(c, []).size() == 1)
				candidates = _shuffled(candidates)
			SpecialRoomData.Placement.FARTHEST:
				candidates.sort_custom(func(a, b): return distances[a] > distances[b])
			SpecialRoomData.Placement.RANDOM:
				candidates = _shuffled(candidates)

		var placed := 0
		for cell in candidates:
			if placed >= special.count:
				break
			types[cell] = special.id
			available.erase(cell)
			placed += 1

		if placed < special.count:
			var fallback: Array = _shuffled(available.filter(func(c): return distances.get(c, 0) >= special.min_distance))
			for cell in fallback:
				if placed >= special.count:
					break
				types[cell] = special.id
				available.erase(cell)
				placed += 1

	return types

func _instantiate_rooms(types: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for cell in _occupied.keys():
		var room_id: StringName = types[cell]
		var scene := _pick_scene(room_id)
		var room: DungeonRoom = scene.instantiate()
		room.grid_position = cell
		room.room_id = room_id
		room.position = Vector2(cell.x * floor_config.room_size.x, cell.y * floor_config.room_size.y)
		add_child(room)
		result[cell] = room

	for cell in _occupied.keys():
		var room: DungeonRoom = result[cell]
		for neighbor in _connections.get(cell, []):
			var direction: Vector2i = neighbor - cell
			_spawn_door(room, result[neighbor], _side_for_direction(direction), _side_for_direction(-direction))
	return result

func _spawn_door(room: DungeonRoom, neighbor_room: DungeonRoom, side: DungeonRoom.Side, entry_side: DungeonRoom.Side) -> void:
	var door: Door = door_scene.instantiate()
	door.target_position = neighbor_room.get_entry_position(entry_side as Side)
	door.target_room = neighbor_room
	add_child(door)
	door.global_position = room.get_door_position(side as Side)
	door.face_side(side)

func _pick_scene(room_id: StringName) -> PackedScene:
	if room_id != &"normal":
		for special in floor_config.special_rooms:
			if special.id == room_id and special.scene != null:
				return special.scene
	if not floor_config.normal_room_scenes.is_empty():
		return floor_config.normal_room_scenes[_rng.randi_range(0, floor_config.normal_room_scenes.size() - 1)]
	return default_room_scene

func _side_for_direction(dir: Vector2i) -> DungeonRoom.Side:
	if dir == DIR_NORTH:
		return DungeonRoom.Side.NORTH
	if dir == DIR_SOUTH:
		return DungeonRoom.Side.SOUTH
	if dir == DIR_EAST:
		return DungeonRoom.Side.EAST
	return DungeonRoom.Side.WEST
