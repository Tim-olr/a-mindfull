extends Interactable

@export var item: ItemResource
@onready var icon: Sprite2D = $icon

func _ready() -> void:
	Name = item.Name
	description = item.description
	icon.texture = item.txtr

func interacted():
	GlobalPlayer.inventory.inventory.add_item(item)
	queue_free()
