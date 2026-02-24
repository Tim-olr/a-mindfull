extends Node
class_name Item

var resource: ItemResource

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack") and resource.isSelected:
		use()

func use():
	if resource.isUsableItem:
		do_thing()
	if resource.isMaterial:
		pass

func do_thing():
	pass
