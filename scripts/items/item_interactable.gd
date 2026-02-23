extends Interactable

@export var item: ItemResource
@onready var icon: Sprite2D = $icon

func _ready() -> void:
	Name = item.Name
	description = item.description
	icon.texture = item.txtr
	icon.material = icon.material.duplicate()

func interacted():
	GlobalPlayer.inventory.inventory.add_item(item)
	queue_free()

func _on_mouse_entered() -> void:
	var tw = create_tween()
	tw.tween_property(icon.material, "shader_parameter/outline_thickness", 6.0, 0.1)

func _on_mouse_exited() -> void:
	var tw = create_tween()
	tw.tween_property(icon.material, "shader_parameter/outline_thickness", 0.0, 0.1)
