extends FahrerCard

# Enemy speed bump lives in FahrerDeck.enemy_speed_mult(); the dash count
# bonus is applied directly to the player here so it persists for the run.

const DASH_BONUS: int = 2

func apply() -> void:
	GlobalPlayer.stats.dashAmount += DASH_BONUS

func remove() -> void:
	GlobalPlayer.stats.dashAmount -= DASH_BONUS
