extends FahrerCard

func apply() -> void:
	# Lock the day/night cycle to midnight.
	DayNightCycle.lock_time = true
	DayNightCycle.lock_value = 0.0

func remove() -> void:
	DayNightCycle.lock_time = false
