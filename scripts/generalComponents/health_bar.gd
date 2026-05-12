extends ProgressBar

@onready var damage_bar: ProgressBar = $DamageBar
@onready var delaytimer: Timer = $Delaytimer

var health = 0
var damage_tween: Tween = null
var flash_tween: Tween = null
var _hp_label: Label = null

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
	_hp_label = Label.new()
	_hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_label.add_theme_font_size_override("font_size", 16)
	_hp_label.add_theme_color_override("font_color", Color.WHITE)
	_hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_hp_label.add_theme_constant_override("shadow_offset_x", 1)
	_hp_label.add_theme_constant_override("shadow_offset_y", 1)
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_label.z_index = 10
	add_child(_hp_label)
	_update_hp_label()

func _update_hp_label() -> void:
	if _hp_label == null:
		return
	_hp_label.text = "%d / %d" % [int(health), int(max_value)]

func set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	value = health
	_update_hp_label()

	if health <= 0:
		if damage_tween: damage_tween.kill()
		if flash_tween: flash_tween.kill()
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
	_update_hp_label()

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
