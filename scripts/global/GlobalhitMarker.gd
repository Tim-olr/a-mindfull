extends Node

@export var float_height := -50.0
@export var float_duration := 1.0
@export var fade_start := 0.5
@export var damage_color := Color.RED
@export var heal_color := Color.GREEN
@export var font_size := 50

func show_hit_marker(amount: int, target: Node2D, is_heal: bool) -> void:
	var world = GlobalWorld.dmgNrs
	var label = Label.new()
	label.text = str(abs(amount))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("shadow_outline_size", 20)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.modulate = heal_color if is_heal else damage_color
	label.position = target.global_position
	label.z_index = 1000
	world.add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y + float_height, float_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, float_duration - fade_start).set_delay(fade_start)
	tween.tween_callback(label.queue_free)
	tween.play()
