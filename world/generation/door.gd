extends Interactable
class_name Door

var target_position: Vector2
var target_room: DungeonRoom

## The door's shape is wide along the wall and thin into the room by default,
## which matches an east/west (vertical) wall. Rotate it flush for north/south.
func face_side(side: DungeonRoom.Side) -> void:
	if side == DungeonRoom.Side.NORTH or side == DungeonRoom.Side.SOUTH:
		rotation = PI / 2.0
	else:
		rotation = 0.0

func interacted() -> void:
	print("DEBUG door interacted -> target_position=", target_position, " target_room=", (target_room.grid_position if target_room else "none"))
	if is_instance_valid(GlobalPlayer.player):
		GlobalPlayer.player.global_position = target_position
	if target_room and is_instance_valid(GlobalPlayer.camera):
		GlobalPlayer.camera.slide_to_room(target_room)
