extends StaticBody2D
class_name DungeonRoom

enum Side { NORTH, SOUTH, EAST, WEST }

@export var room_size: Vector2 = Vector2(480, 270)

@export_group("Enemies")
@export var can_spawn_enemies: bool = true
@export var enemy_pool: Array[PackedScene] = []
@export var enemy_count_range: Vector2i = Vector2i(2, 5)
@export var enemy_spawn_margin: float = 60.0

@export_group("Obstacles")
@export var can_spawn_obstacles: bool = true
@export var obstacle_pool: Array[PackedScene] = []
@export var obstacle_grid_columns: int = 6
@export var obstacle_grid_rows: int = 2
@export var obstacle_count_range: Vector2i = Vector2i(2, 5)
@export var obstacle_margin: float = 40.0

## Emitted once when the last enemy spawned in this room dies. Doors mounted
## on this room listen for it to reveal/unblock themselves.
signal cleared

var room_id: StringName = &"normal"
var grid_position: Vector2i = Vector2i.ZERO
var visited: bool = false

## True until this room spawns enemies and stays true for rooms that never
## do (start room, shops, item rooms, ...), so their doors are never blocked.
var is_cleared: bool = true
var enemy_count: int = 0

## Set by DungeonGenerator for the cell the player starts in, so it stays clear.
var is_start_room: bool = false

@onready var _walls: Dictionary = {
	Side.NORTH: $WallNorth,
	Side.SOUTH: $WallSouth,
	Side.EAST: $WallEast,
	Side.WEST: $WallWest,
}

const DOOR_INSET := 40.0
const ENTRY_INSET := 100.0

const ARDY := preload("uid://vmce3i1bf5v1")
const BARTHOLOMEW := preload("uid://dg08cdh3iur8r")
const BONKUS := preload("uid://cioco2pfro1aw")

const OBSTACLE_ROCK := preload("res://world/generation/obstacles/obstacle_rock.tscn")
const OBSTACLE_CRATE := preload("res://world/generation/obstacles/obstacle_crate.tscn")

const WEAPON_PEDESTAL := preload("res://items/weapon_interactable.tscn")
const WEAPON_CHOICE_SPACING := 60.0
const WEAPON_CHOICE_Y_OFFSET := 70.0

var _weapon_pedestals: Array[Node] = []

func _ready() -> void:
	# Rooms start inactive; DungeonGenerator/camera activates the start room
	# (and whichever room the player enters) via set_active().
	process_mode = Node.PROCESS_MODE_DISABLED
	if room_id == &"normal" and not is_start_room:
		_spawn_enemies()
		_spawn_obstacles()
	elif is_start_room:
		_spawn_weapon_choices()

## Lets the player pick one of two of their unlocked weapons to start the run
## with. The pedestal not chosen disappears once a choice is made.
func _spawn_weapon_choices() -> void:
	var names := WeaponRegistry.get_unlocked_names()
	names.shuffle()
	var choice_count: int = min(2, names.size())
	if choice_count <= 0:
		return

	var center_x := room_size.x / 2.0
	var y := room_size.y / 2.0 - WEAPON_CHOICE_Y_OFFSET
	var start_x := center_x - WEAPON_CHOICE_SPACING * (choice_count - 1) / 2.0

	for i in choice_count:
		var item := WeaponRegistry.get_item_resource(names[i])
		if item == null:
			continue
		var pedestal := WEAPON_PEDESTAL.instantiate()
		pedestal.item = item
		pedestal.position = Vector2(start_x + i * WEAPON_CHOICE_SPACING, y)
		_weapon_pedestals.append(pedestal)
		pedestal.tree_exiting.connect(_on_weapon_pedestal_taken.bind(pedestal))
		call_deferred("add_child", pedestal)

func _on_weapon_pedestal_taken(taken: Node) -> void:
	for pedestal in _weapon_pedestals:
		if pedestal != taken and is_instance_valid(pedestal):
			pedestal.queue_free()
	_weapon_pedestals.clear()

## Enables/disables all processing (AI, timers, animations, ...) for everything
## in this room's subtree, so rooms the player isn't in stay fully idle.
func set_active(active: bool) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func _spawn_enemies() -> void:
	if not can_spawn_enemies:
		return
	var pool := enemy_pool
	if pool.is_empty():
		pool = [ARDY, BARTHOLOMEW, BONKUS]
	var count := randi_range(enemy_count_range.x, enemy_count_range.y)
	if count <= 0:
		return
	enemy_count = count
	is_cleared = false
	for i in count:
		var scene: PackedScene = pool[randi_range(0, pool.size() - 1)]
		var enemy: CharacterBody2D = scene.instantiate()
		enemy.position = Vector2(
			randf_range(enemy_spawn_margin, room_size.x - enemy_spawn_margin),
			randf_range(enemy_spawn_margin, room_size.y - enemy_spawn_margin)
		)
		enemy.tree_exited.connect(_on_enemy_defeated)
		call_deferred("add_child", enemy)

## Hooked to every spawned enemy's tree_exited (fires on queue_free(), which
## is how Enemy.die() removes them) rather than a "died" signal, so it also
## catches any other way an enemy might leave the room.
func _on_enemy_defeated() -> void:
	enemy_count = maxi(enemy_count - 1, 0)
	if enemy_count == 0 and not is_cleared:
		is_cleared = true
		cleared.emit()

func _spawn_obstacles() -> void:
	if not can_spawn_obstacles:
		return
	var pool := obstacle_pool
	if pool.is_empty():
		pool = [OBSTACLE_ROCK, OBSTACLE_CRATE]
	var cells := _obstacle_grid_cells()
	cells.shuffle()
	var count := clampi(randi_range(obstacle_count_range.x, obstacle_count_range.y), 0, cells.size())
	for i in count:
		var scene: PackedScene = pool[randi_range(0, pool.size() - 1)]
		var obstacle: Node2D = scene.instantiate()
		obstacle.position = cells[i]
		call_deferred("add_child", obstacle)

## Candidate obstacle placement points (room-local space), laid out on a grid
## and filtered away from the walls and from each door opening.
func _obstacle_grid_cells() -> Array:
	var cells: Array = []
	var cell_w := room_size.x / obstacle_grid_columns
	var cell_h := room_size.y / obstacle_grid_rows
	var door_points := [
		get_wall_offset(Side.NORTH as Side), get_wall_offset(Side.SOUTH as Side),
		get_wall_offset(Side.EAST as Side), get_wall_offset(Side.WEST as Side),
	]
	for x in obstacle_grid_columns:
		for y in obstacle_grid_rows:
			var point := Vector2((x + 0.5) * cell_w, (y + 0.5) * cell_h)
			if point.x < obstacle_margin or point.x > room_size.x - obstacle_margin:
				continue
			if point.y < obstacle_margin or point.y > room_size.y - obstacle_margin:
				continue
			var blocks_door := false
			for door_point in door_points:
				if point.distance_to(door_point) < obstacle_margin * 1.5:
					blocks_door = true
					break
			if not blocks_door:
				cells.append(point)
	return cells

func get_center() -> Vector2:
	return global_position + room_size / 2.0

## Point on the given wall, in local space (room_size aligned, origin at top-left corner).
func get_wall_offset(side: Side) -> Vector2:
	match side:
		Side.NORTH:
			return Vector2(room_size.x / 2.0, 0.0)
		Side.SOUTH:
			return Vector2(room_size.x / 2.0, room_size.y)
		Side.EAST:
			return Vector2(room_size.x, room_size.y / 2.0)
		Side.WEST:
			return Vector2(0.0, room_size.y / 2.0)
	return Vector2.ZERO

## Unit vector pointing from the given wall back into the room.
func get_inward_direction(side: Side) -> Vector2:
	match side:
		Side.NORTH:
			return Vector2(0.0, 1.0)
		Side.SOUTH:
			return Vector2(0.0, -1.0)
		Side.EAST:
			return Vector2(-1.0, 0.0)
		Side.WEST:
			return Vector2(1.0, 0.0)
	return Vector2.ZERO

## World position for a door sitting against the given wall.
func get_door_position(side: Side) -> Vector2:
	return global_position + get_wall_offset(side) + get_inward_direction(side) * DOOR_INSET

## World position just inside the room on the given side, for a player entering through that wall.
func get_entry_position(side: Side) -> Vector2:
	return global_position + get_wall_offset(side) + get_inward_direction(side) * ENTRY_INSET

func open_side(side: Side) -> void:
	if _walls.has(side):
		_walls[side].disabled = true

func open_sides(sides: Array) -> void:
	for side in sides:
		open_side(side)
