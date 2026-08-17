extends Node
@export var float_height := 20.0
@export var float_duration := 0.9
@export var fade_start := 0.4
@export var damage_color := Color.WHITE
@export var heal_color := Color.GREEN
@export var font_size := 64
@export var display_scale := 0.15
@export var horizontal_offset := -40.0
@export var merge_radius := 10.0
var _active_markers: Array[Dictionary] = []

func show_hit_marker(amount: float, target: Node2D, is_heal: bool) -> void:
	var world = GlobalWorld.dmgNrs
	var spawn_pos = target.global_position
	process_mode = Node.PROCESS_MODE_ALWAYS

	for marker in _active_markers:
		if marker["is_heal"] == is_heal and marker["label"].position.distance_to(spawn_pos) <= merge_radius:
			marker["amount"] = snappedf(marker["amount"] + amount, 0.1)
			marker["label"].text = str(marker["amount"])
			marker["label"].modulate.a = 1.0
			marker["tween"].kill()
			var label = marker["label"]
			var centered = spawn_pos - label.pivot_offset * display_scale + Vector2(horizontal_offset, 0)
			label.position = centered
			var tween = create_tween().set_parallel(true)
			marker["tween"] = tween
			tween.tween_property(label, "scale", Vector2(display_scale * 1.4, display_scale * 1.4), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.chain().tween_property(label, "scale", Vector2(0.0, 0.0), float_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(label, "position:y", centered.y + float_height, float_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(label, "modulate:a", 0.0, float_duration - fade_start).set_delay(fade_start)
			tween.chain().tween_callback(func(): _remove_marker(marker))
			tween.play()
			return

	var label2 = Label.new()
	label2.text = str(snappedf(amount, 0.1))
	label2.add_theme_font_size_override("font_size", font_size)
	label2.add_theme_constant_override("outline_size", 14)
	label2.add_theme_color_override("font_outline_color", Color.BLACK)
	label2.modulate = heal_color if is_heal else damage_color
	label2.position = spawn_pos
	label2.z_index = 1000
	label2.scale = Vector2(0.0, 0.0)
	world.add_child(label2)

	await get_tree().process_frame
	label2.pivot_offset = label2.size / 2.0
	var centered2 = spawn_pos - label2.pivot_offset * display_scale + Vector2(horizontal_offset, 0)
	label2.position = centered2

	var tween2 = create_tween().set_parallel(true)
	tween2.tween_property(label2, "scale", Vector2(display_scale * 1.4, display_scale * 1.4), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween2.chain().tween_property(label2, "scale", Vector2(0.0, 0.0), float_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween2.tween_property(label2, "position:y", centered2.y + float_height, float_duration + 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween2.tween_property(label2, "modulate:a", 0.0, float_duration - fade_start).set_delay(fade_start)

	var marker_data = {"label": label2, "tween": tween2, "amount": snappedf(amount, 0.1), "is_heal": is_heal}
	_active_markers.append(marker_data)
	tween2.chain().tween_callback(func(): _remove_marker(marker_data))
	tween2.play()

func _remove_marker(marker: Dictionary) -> void:
	if marker["label"]:
		marker["label"].queue_free()
	_active_markers.erase(marker)
