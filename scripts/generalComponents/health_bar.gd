extends ProgressBar

@onready var damage_bar: ProgressBar = $DamageBar
@onready var delaytimer: Timer = $Delaytimer

var health = 0
var damage_tween: Tween = null
var flash_tween: Tween = null

const TWEEN_DURATION := 0.4
const FLASH_DURATION := 0.2
const HEALTH_COLOR := Color("26ae50")

func _ready() -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = HEALTH_COLOR
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 5
	sb.corner_radius_bottom_right = 5
	sb.corner_radius_bottom_left = 10
	add_theme_stylebox_override("fill", sb)

func set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	value = health
	
	if health <= 0:
		if damage_tween: damage_tween.kill()
		if flash_tween: flash_tween.kill()
		queue_free()
		return
	
	if health < prev_health:
		flash_hp_bar(Color.RED)
		if delaytimer:
			delaytimer.start()
	elif health > prev_health:
		flash_hp_bar(Color.WHITE)
		if delaytimer and not delaytimer.is_stopped():
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

func flash_hp_bar(flash_color: Color):
	if flash_tween:
		flash_tween.kill()
	
	flash_tween = create_tween()
	var style_box = get_theme_stylebox("fill").duplicate()
	add_theme_stylebox_override("fill", style_box)
	flash_tween.tween_property(style_box, "bg_color", flash_color, FLASH_DURATION / 2)
	flash_tween.tween_property(style_box, "bg_color", HEALTH_COLOR, FLASH_DURATION / 2)
