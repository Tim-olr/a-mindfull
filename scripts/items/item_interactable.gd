extends Interactable
class_name ItemInteractable

@export var item: ItemResource
@onready var icon: Sprite2D = $icon

func _ready() -> void:
	Name = item.Name
	description = item.description
	icon.texture = item.txtr
	icon.material = icon.material.duplicate()
	icon.material.set_shader_parameter("outline_color", item.calculate_rarity_outline())
	if item.has_scale:
		scale = item.scale_mod

func interacted():
	GlobalPlayer.inventory.inventory.add_item(item)
	queue_free()
