extends Spirit

func apply_passive():
	GlobalPlayer.stats.speed *= 1.3

func remove_passive():
	GlobalPlayer.stats.speed /= 1.3

func active_ability():
	if canAbility:
		GlobalPlayer.movement.dodgeVelocity += Vector2(GlobalPlayer.movement.direction.x, GlobalPlayer.movement.direction.y) * 30000
		active_ability_timer.start(activeAbilityCooldown)
		canAbility = false
