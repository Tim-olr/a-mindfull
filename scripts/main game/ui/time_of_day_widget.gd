extends Control

# Small widget that shows the current time-of-day. Reads from the
# DayNightCycle autoload. Display: "HH:MM" plus a sun/moon icon and
# a coloured swatch matching the current sky tint.

@onready var time_label: Label = $TimeLabel
@onready var phase_label: Label = $PhaseLabel
@onready var swatch: ColorRect = $Swatch

func _process(_delta: float) -> void:
	if DayNightCycle == null:
		return
	var t: float = DayNightCycle.time
	var total_minutes: int = int(t * 24.0 * 60.0)
	var hours: int = total_minutes / 60
	var minutes: int = total_minutes % 60
	if time_label != null:
		time_label.text = "%02d:%02d" % [hours, minutes]
	if phase_label != null:
		phase_label.text = ("☀ Day" if DayNightCycle.is_daytime() else "☾ Night")
	if swatch != null:
		swatch.color = DayNightCycle.get_tint()
