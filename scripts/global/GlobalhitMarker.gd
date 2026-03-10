extends Node

@export var float_height := -50.0
@export var float_duration := 1.0
@export var fade_start := 0.5
@export var damage_color := Color.RED
@export var heal_color := Color.GREEN
@export var font_size := 50
@export var merge_radius := 40.0

var _active_markers: Array[Dictionary] = []

func show_hit_marker(amount: float, target: Node2D, is_heal: bool) -> void:
	var world = GlobalWorld.dmgNrs
	var spawn_pos = target.global_position

	for marker in _active_markers:
		if marker["is_heal"] == is_heal and marker["label"].position.distance_to(spawn_pos) <= merge_radius:
			marker["amount"] = snappedf(marker["amount"] + amount, 0.1)
			marker["label"].text = str(marker["amount"])
			marker["label"].modulate.a = 1.0
			marker["tween"].kill()
			var label = marker["label"]
			label.position.y = spawn_pos.y
			var tween = create_tween()
			marker["tween"] = tween
			tween.tween_property(label, "position:y", spawn_pos.y + float_height, float_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(label, "modulate:a", 0.0, float_duration - fade_start).set_delay(fade_start)
			tween.tween_callback(func(): _remove_marker(marker))
			tween.play()
			return

	var label = Label.new()
	label.text = str(snappedf(amount, 0.1))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("shadow_outline_size", 20)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.modulate = heal_color if is_heal else damage_color
	label.position = spawn_pos
	label.z_index = 1000
	world.add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "position:y", spawn_pos.y + float_height, float_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, float_duration - fade_start).set_delay(fade_start)

	var marker_data = {"label": label, "tween": tween, "amount": snappedf(amount, 0.1), "is_heal": is_heal}
	_active_markers.append(marker_data)
	tween.tween_callback(func(): _remove_marker(marker_data))
	tween.play()

func _remove_marker(marker: Dictionary) -> void:
	if marker["label"]:
		marker["label"].queue_free()
	_active_markers.erase(marker)
