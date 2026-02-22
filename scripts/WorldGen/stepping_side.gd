extends Node2D
class_name SteppingSide

@export var isTop: bool = false

var entered: bool = false
var max_step_height: int = 1
const STEP_PIXEL_OFFSET := 200
var flipped: bool = false
var gen
var layer

var tile_cell: Vector2i = Vector2i.ZERO

@onready var climb_up_area: Area2D = $climbUpArea
@onready var climb_down_area: Area2D = $ClimbDownArea

func _ready() -> void:
	get_parent().step_up_layers.append(climb_up_area)
	get_parent().step_down_layers.append(climb_down_area)

func _exit_tree() -> void:
	get_parent().step_up_layers.erase(climb_up_area)
	get_parent().step_down_layers.erase(climb_down_area)

func _on_climb_up_area_area_entered(area: Area2D) -> void:
	if not area.is_in_group("climbing_area"):
		return
	max_step_height = GlobalPlayer.stats.step_height
	if gen == null or layer == null or GlobalPlayer == null or GlobalPlayer.player == null:
		return
	var stack = gen.get_stack_height_at(layer, tile_cell)
	if stack > max_step_height:
		return
	GlobalPlayer.movement.movement_enabled = false
	GlobalPlayer.movement.climb_timer.start(GlobalPlayer.stats.climb_time)
	await GlobalPlayer.movement.climb_timer.timeout
	entered = true
	if isTop:
		GlobalPlayer.coordinates.y -= stack
		gen.transition_to_layer(int(layer.y_cord) - (stack - 1))
	else:
		GlobalPlayer.player.global_position.y -= STEP_PIXEL_OFFSET * stack
		GlobalPlayer.player.global_position.x += (-150 if flipped else 150) * stack
		GlobalPlayer.coordinates.y += stack
		gen.transition_to_layer(int(GlobalPlayer.coordinates.y))

	gen.update_coord_display()
	GlobalPlayer.movement.movement_enabled = true

func _on_climb_up_area_area_exited(area: Area2D) -> void:
	entered = false

func _on_climb_down_area_area_entered(area: Area2D) -> void:
	# Down area keeps its normal behavior; still respect max_step_height
	if not area.is_in_group("climbing_area"):
		return

	max_step_height = GlobalPlayer.stats.step_height
	if gen == null or layer == null or GlobalPlayer == null or GlobalPlayer.player == null:
		return

	var stack = gen.get_stack_height_at(layer, tile_cell)
	if stack > max_step_height:
		return

	entered = true
	GlobalPlayer.player.global_position.y += STEP_PIXEL_OFFSET * stack
	GlobalPlayer.player.global_position.x += (150 if flipped else -150) * stack
	GlobalPlayer.coordinates.y -= stack
	gen.transition_to_layer(int(layer.y_cord) - (stack - 1))
	gen.update_coord_display()

func _on_climb_down_area_area_exited(area: Area2D) -> void:
	entered = false
