extends Label

func _process(_delta: float) -> void:
	if DayNightCycle == null:
		return
	var t: float = DayNightCycle.time
	var total_minutes: int = int(t * 24.0 * 60.0)
	var hours: int = total_minutes / 60
	var minutes: int = total_minutes % 60
	text = "%02d:%02d" % [hours, minutes]
