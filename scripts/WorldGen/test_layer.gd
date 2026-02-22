extends TileMapLayer
@onready var climb_up_area: Area2D = $climbUpArea

var enetered: bool
var step_height := 150

func _on_climb_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("climbing_area"):
		enetered = true
		GlobalPlayer.player.global_position.y += -step_height
		GlobalPlayer.player.global_position.x += 160

func _on_climb_area_area_exited(area: Area2D) -> void:
	enetered = false


func _on_climb_down_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("climbing_area"):
		enetered = true
		GlobalPlayer.player.global_position.y += step_height
		GlobalPlayer.player.global_position.x -= 160


func _on_climb_down_area_area_exited(area: Area2D) -> void:
	enetered = false
