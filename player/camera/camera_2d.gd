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
	_mark_current(room)

func slide_to_room(room: DungeonRoom) -> void:
	if _room_tween:
		_room_tween.kill()
	_room_tween = create_tween()
	_room_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_room_tween.tween_property(self, "global_position", room.get_center(), room_transition_time)
	_mark_current(room)

func _mark_current(room: DungeonRoom) -> void:
	room.visited = true
	GlobalWorld.current_room = room
	print("DEBUG room marked current: grid=", room.grid_position, " global_pos=", room.global_position,
		" visible_in_tree=", room.is_visible_in_tree(), " children=", room.get_children())
	for c in room.get_children():
		if c is CanvasItem:
			print("  child ", c.name, " type=", c.get_class(), " visible=", c.visible, " modulate=", c.modulate, " z_index=", c.z_index)
			if c is TextureRect:
				print("    TextureRect global_position=", c.global_position, " size=", c.size, " global_rect=", c.get_global_rect(), " texture=", c.texture)
	print("DEBUG cam: enabled=", enabled, " is_current=", is_current(), " active_cam=", get_viewport().get_camera_2d(),
		" me=", self, " zoom=", zoom, " global_position=", global_position, " canvas_transform=", get_viewport().canvas_transform)
	print("DEBUG world2d: room=", room.get_world_2d(), " cam=", get_world_2d(), " same_viewport=", (room.get_viewport() == get_viewport()))

func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength,0,shakeFade * delta)
		offset = randomOffset()

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))
