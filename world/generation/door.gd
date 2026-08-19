extends Interactable
class_name Door

var target_position: Vector2
var target_room: DungeonRoom

## The room this door is mounted in (not the room it leads to). Its
## clear-state gates whether this door can be seen/used.
var source_room: DungeonRoom = null

func _ready() -> void:
	_refresh_blocked_state()
	if source_room != null:
		source_room.cleared.connect(_refresh_blocked_state)

## The door's shape is wide along the wall and thin into the room by default,
## which matches an east/west (vertical) wall. Rotate it flush for north/south.
func face_side(side: DungeonRoom.Side) -> void:
	if side == DungeonRoom.Side.NORTH or side == DungeonRoom.Side.SOUTH:
		rotation = PI / 2.0
	else:
		rotation = 0.0

func interacted() -> void:
	if source_room != null and not source_room.is_cleared:
		return
	if is_instance_valid(GlobalPlayer.player):
		GlobalPlayer.player.global_position = target_position
	if target_room and is_instance_valid(GlobalPlayer.camera):
		GlobalPlayer.camera.slide_to_room(target_room)

## Rooms with live enemies hide this door entirely and stop it from being
## detected as an overlapping interactable, so a blocked door can neither be
## seen nor walked up and interacted with — not just "greyed out".
func _refresh_blocked_state() -> void:
	var open := source_room == null or source_room.is_cleared
	visible = open
	monitorable = open
