extends Area2D
class_name Interactable

@export var Name: String
@export var description: String

@export_group("Bob Animation")
@export var bob_height: float = 4.0
@export var bob_duration: float = 2.4

var _is_active: bool = false

func interacted():
	pass

func close_interaction():
	_is_active = false

## Gentle floating idle animation for pickup icons.
func _start_bob(target: Node2D) -> void:
	var start_y := target.position.y
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "position:y", start_y - bob_height, bob_duration * 0.5)
	tween.tween_property(target, "position:y", start_y, bob_duration * 0.5)
