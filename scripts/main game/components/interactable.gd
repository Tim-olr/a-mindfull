extends Area2D
class_name Interactable

@export var Name: String
@export var description: String

var _is_active: bool = false

func interacted():
	pass

func close_interaction():
	_is_active = false
