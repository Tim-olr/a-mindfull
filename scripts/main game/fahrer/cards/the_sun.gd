extends FahrerCard

func apply() -> void:
	DayNightCycle.lock_time = true
	DayNightCycle.lock_value = 0.5  # noon

func remove() -> void:
	DayNightCycle.lock_time = false
