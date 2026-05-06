extends Node

# Time of day in [0, 1):
#   0.00 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset
@export var day_length_sec: float = 300.0  # 5 minutes per full cycle
@export var start_time: float = 0.30       # start a bit after sunrise

var time: float = 0.30
var _modulate_node: CanvasModulate = null

const C_NIGHT   = Color(0.20, 0.25, 0.45)
const C_DAWN    = Color(1.00, 0.65, 0.45)
const C_DAY     = Color(1.00, 1.00, 1.00)
const C_DUSK    = Color(1.00, 0.55, 0.40)

func _ready() -> void:
	time = start_time
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	if day_length_sec <= 0.0:
		return
	time = fposmod(time + delta / day_length_sec, 1.0)
	_apply_tint()

func is_daytime() -> bool:
	# Daytime is between sunrise (0.25) and sunset (0.75)
	return time >= 0.25 and time < 0.75

func get_tint() -> Color:
	# Smooth interpolation between four anchor colours
	if time < 0.25:
		return C_NIGHT.lerp(C_DAWN, time / 0.25)
	elif time < 0.5:
		return C_DAWN.lerp(C_DAY, (time - 0.25) / 0.25)
	elif time < 0.75:
		return C_DAY.lerp(C_DUSK, (time - 0.5) / 0.25)
	else:
		return C_DUSK.lerp(C_NIGHT, (time - 0.75) / 0.25)

func _apply_tint() -> void:
	if _modulate_node == null or not is_instance_valid(_modulate_node):
		_modulate_node = _find_modulate()
		if _modulate_node == null:
			return
	_modulate_node.color = get_tint()

func _find_modulate() -> CanvasModulate:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return null
	return _search(tree.current_scene)

func _search(node: Node) -> CanvasModulate:
	if node is CanvasModulate:
		return node
	for c in node.get_children():
		var found := _search(c)
		if found != null:
			return found
	return null
