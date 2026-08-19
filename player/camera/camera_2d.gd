extends Camera2D

@export var shakeFade: float = 5.0
@export var room_transition_time: float = 1.2

var rng = RandomNumberGenerator.new()

var shake_strength: float = 0.0
var _room_tween: Tween

func _ready() -> void:
	# Ignore the parent (Player)'s transform so the camera can stay fixed
	# on a room's center instead of tracking the player around.
	top_level = true

func apply_shake(shakeAmt):
	shake_strength = shakeAmt

func snap_to_room(room: DungeonRoom) -> void:
	if _room_tween:
		_room_tween.kill()
	global_position = room.get_center()
	_leave_current_room(room)
	room.set_active(true)

## Slides the camera to the new room. Player movement/shooting and the new
## room's enemies stay frozen until the slide animation finishes, so no
## gameplay logic runs while the room switch is still playing out.
func slide_to_room(room: DungeonRoom) -> void:
	if _room_tween:
		_room_tween.kill()
	_set_logic_frozen(true)
	_leave_current_room(room)
	_room_tween = create_tween()
	_room_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_room_tween.tween_property(self, "global_position", room.get_center(), room_transition_time)
	_room_tween.tween_callback(_finish_room_switch.bind(room))

func _finish_room_switch(room: DungeonRoom) -> void:
	room.set_active(true)
	_set_logic_frozen(false)

func _set_logic_frozen(frozen: bool) -> void:
	if is_instance_valid(GlobalPlayer.movement):
		GlobalPlayer.movement.movement_enabled = not frozen
	if is_instance_valid(GlobalPlayer.stats):
		GlobalPlayer.stats.canAttack = not frozen

func _leave_current_room(room: DungeonRoom) -> void:
	if is_instance_valid(GlobalWorld.current_room) and GlobalWorld.current_room != room:
		GlobalWorld.current_room.set_active(false)
	room.visited = true
	GlobalWorld.current_room = room

func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength,0,shakeFade * delta)
		offset = randomOffset()

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))
