extends StaticBody2D
class_name DungeonRoom

enum Side { NORTH, SOUTH, EAST, WEST }

@export var room_size: Vector2 = Vector2(480, 270)

var room_id: StringName = &"normal"
var grid_position: Vector2i = Vector2i.ZERO
var visited: bool = false

@onready var _walls: Dictionary = {
	Side.NORTH: $WallNorth,
	Side.SOUTH: $WallSouth,
	Side.EAST: $WallEast,
	Side.WEST: $WallWest,
}

const DOOR_INSET := 40.0
const ENTRY_INSET := 100.0

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
