extends Node2D

var _charge_ratio: float = 0.0
var _visible_bar: bool = false

const RADIUS: float = 20.0
const THICKNESS: float = 4.0
const SEGMENTS: int = 64
const OFFSET: Vector2 = Vector2(0, -36)

func _process(_delta: float) -> void:
	queue_redraw()
	global_position = get_global_mouse_position() + OFFSET

func show_bar(ratio: float) -> void:
	_charge_ratio = ratio
	_visible_bar = true

func hide_bar() -> void:
	_visible_bar = false
	_charge_ratio = 0.0

func _draw() -> void:
	if not _visible_bar:
		return

	var track_color := Color(0.2, 0.2, 0.2, 0.5)
	_draw_arc_thick(track_color, 1.0)

	var fill_color := _get_charge_color(_charge_ratio)
	_draw_arc_thick(fill_color, _charge_ratio)

func _draw_arc_thick(color: Color, ratio: float) -> void:
	if ratio <= 0.0:
		return
	var points: PackedVector2Array = []
	var arc_radians: float = TAU * ratio
	var step: float = arc_radians / float(SEGMENTS)
	var start: float = -PI / 2.0

	for i in range(SEGMENTS + 1):
		var angle: float = start + step * i
		points.append(Vector2(cos(angle), sin(angle)) * RADIUS)

	draw_polyline(points, color, THICKNESS, true)

func _get_charge_color(ratio: float) -> Color:
	var red := Color(0.886, 0.294, 0.290)
	var orange := Color(0.937, 0.624, 0.153)
	var green := Color(0.518, 0.799, 0.169, 1.0)

	if ratio < 0.5:
		return red.lerp(orange, ratio * 2.0)
	else:
		return orange.lerp(green, (ratio - 0.5) * 2.0)
