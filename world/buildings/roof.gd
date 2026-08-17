extends Area2D
class_name Roof
@onready var roof_mesh: Sprite2D = $roof_sprite

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		fade_roof_mesh_out()

func fade_roof_mesh_out():
	var tween = create_tween()
	tween.tween_property(roof_mesh, "modulate:a", 0.3, 0.2)
	tween.tween_property(roof_mesh, "modulate:a", 0.0, 0.2)

func fade_roof_mesh_in():
	var tween = create_tween()
	tween.tween_property(roof_mesh, "modulate:a", 1.0, 0.4)

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		fade_roof_mesh_in()
