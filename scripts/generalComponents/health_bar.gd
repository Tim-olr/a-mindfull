extends ProgressBar

@onready var damage_bar: ProgressBar = $DamageBar
@onready var delaytimer: Timer = $Delaytimer

var health = 0
var damage_tween = null
const TWEEN_DURATION := 0.4

func set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	value = health

	if health <= 0:
		if damage_tween:
			damage_tween.kill()
		queue_free()
		return

	if health < prev_health:
		# Took damage: wait then animate the damage bar down
		delaytimer.start()
	else:
		# Healed (or same): stop any pending delay and tween immediately
		if not delaytimer.is_stopped():
			delaytimer.stop()
		tween_damage_bar_to(health, TWEEN_DURATION)

func init_health(_health):
	health = _health
	max_value = health
	value = health
	damage_bar.max_value = health
	damage_bar.value = health

func _on_delaytimer_timeout() -> void:
	tween_damage_bar_to(health, TWEEN_DURATION)

func tween_damage_bar_to(target: float, duration: float = TWEEN_DURATION) -> void:
	if damage_tween:
		damage_tween.kill()
	damage_tween = create_tween()
	damage_tween.tween_property(damage_bar, "value", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
