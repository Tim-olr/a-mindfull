extends Interactable
class_name ArtifactInteractable

@export var artifact: ArtifactResource
@onready var icon: Sprite2D = $icon

func _ready() -> void:
	if artifact == null:
		push_warning("ArtifactInteractable: no artifact assigned")
		return
	Name = artifact.artifact_name
	description = artifact.description
	if artifact.icon != null:
		icon.texture = artifact.icon
	icon.material = icon.material.duplicate()
	icon.material.set_shader_parameter("outline_color", artifact.rarity_color())
	_start_bob(icon)

func interacted() -> void:
	ArtifactManager.pick_up(artifact)
	queue_free()
