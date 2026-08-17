extends Resource
class_name FloorConfig

@export var floor_name: String = "Depths"
@export var min_rooms: int = 6
@export var max_rooms: int = 10
@export var room_size: Vector2 = Vector2(480, 270)
@export_range(0.0, 1.0) var branch_chance: float = 0.5
@export_range(0.0, 1.0) var dead_end_chance: float = 0.3
@export_range(0.0, 1.0) var loop_chance: float = 0.0
@export var normal_room_scenes: Array[PackedScene] = []
@export var special_rooms: Array[SpecialRoomData] = []
