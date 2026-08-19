extends Node

# Time of day in [0, 1):
#   0.00 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset
#
# Purely a gameplay clock (drives the HUD clock and the Look At You spirit's
# daytime bonus) — it no longer tints the screen; that CanvasModulate filter
# was removed because it made the game look worse, not better.
@export var day_length_sec: float = 300.0  # 5 minutes per full cycle
@export var start_time: float = 0.30       # start a bit after sunrise

var time: float = 0.30
var lock_time: bool = false
var lock_value: float = 0.5

func _ready() -> void:
	time = start_time
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	if lock_time:
		time = lock_value
		return
	if day_length_sec <= 0.0:
		return
	time = fposmod(time + delta / day_length_sec, 1.0)

func is_daytime() -> bool:
	# Daytime is between sunrise (0.25) and sunset (0.75)
	return time >= 0.25 and time < 0.75
