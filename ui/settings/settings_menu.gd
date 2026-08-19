extends Control

signal closed

const ROW_LABEL_MIN_WIDTH := 260.0
const MODIFIER_KEYCODES := [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK]

const FPS_LABELS := {0: "Uncapped", 30: "30", 60: "60", 120: "120", 144: "144", 240: "240"}

@onready var keybind_list: VBoxContainer = $Panel/TabContainer/Controls/KeybindList
@onready var general_list: VBoxContainer = $Panel/TabContainer/Display/GeneralList

var _bind_buttons: Dictionary = {}
var _listening_action: String = ""
var _listening_button: Button = null
var _fullscreen_checkbox: CheckBox = null

func _ready() -> void:
	hide()
	_build_rows()
	_build_general_settings()

func open_settings() -> void:
	_cancel_listening()
	_refresh_all_bindings()
	show()

func _close() -> void:
	_cancel_listening()
	hide()
	closed.emit()

func _on_close_pressed() -> void:
	_close()

func _on_reset_all_pressed() -> void:
	KeybindManager.reset_all()
	_refresh_all_bindings()

func _build_rows() -> void:
	for action in KeybindManager.REBINDABLE_ACTIONS:
		_add_row(action, KeybindManager.REBINDABLE_ACTIONS[action])

func _add_row(action: String, label_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(ROW_LABEL_MIN_WIDTH, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var bind_button := Button.new()
	bind_button.custom_minimum_size = Vector2(180, 36)
	bind_button.text = _binding_text(action)
	bind_button.pressed.connect(_on_bind_pressed.bind(action, bind_button))
	row.add_child(bind_button)

	var reset_button := Button.new()
	reset_button.text = "Reset"
	reset_button.custom_minimum_size = Vector2(70, 36)
	reset_button.pressed.connect(_on_reset_pressed.bind(action, bind_button))
	row.add_child(reset_button)

	keybind_list.add_child(row)
	_bind_buttons[action] = bind_button

func _on_bind_pressed(action: String, button: Button) -> void:
	if _listening_action != "":
		return
	_listening_action = action
	_listening_button = button
	button.text = "Press a key..."

func _on_reset_pressed(action: String, button: Button) -> void:
	if _listening_action == action:
		_listening_action = ""
		_listening_button = null
	KeybindManager.reset_action(action)
	_refresh_all_bindings()

func _unhandled_input(event: InputEvent) -> void:
	if _listening_action == "":
		if visible and event.is_action_pressed("esc"):
			_close()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_cancel_listening()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode in MODIFIER_KEYCODES:
			return
		var new_event := InputEventKey.new()
		new_event.physical_keycode = event.physical_keycode
		new_event.shift_pressed = event.shift_pressed
		new_event.ctrl_pressed = event.ctrl_pressed
		new_event.alt_pressed = event.alt_pressed
		KeybindManager.rebind(_listening_action, new_event)
		_finish_listening()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		var new_event := InputEventMouseButton.new()
		new_event.button_index = event.button_index
		KeybindManager.rebind(_listening_action, new_event)
		_finish_listening()
		get_viewport().set_input_as_handled()

func _finish_listening() -> void:
	_listening_action = ""
	_listening_button = null
	_refresh_all_bindings()

func _cancel_listening() -> void:
	if _listening_button != null and _listening_action != "":
		_listening_button.text = _binding_text(_listening_action)
	_listening_action = ""
	_listening_button = null

func _refresh_all_bindings() -> void:
	for action in _bind_buttons:
		_bind_buttons[action].text = _binding_text(action)

func _binding_text(action: String) -> String:
	var events := KeybindManager.get_events(action)
	if events.is_empty():
		return "Unbound"
	return _event_to_text(events[0])

func _event_to_text(event: InputEvent) -> String:
	if event is InputEventKey:
		var parts: Array[String] = []
		if event.ctrl_pressed:
			parts.append("Ctrl")
		if event.alt_pressed:
			parts.append("Alt")
		if event.shift_pressed:
			parts.append("Shift")
		var keycode: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		parts.append(OS.get_keycode_string(keycode))
		return "+".join(parts)
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				return "Mouse Left"
			MOUSE_BUTTON_RIGHT:
				return "Mouse Right"
			MOUSE_BUTTON_MIDDLE:
				return "Mouse Middle"
			MOUSE_BUTTON_WHEEL_UP:
				return "Mouse Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN:
				return "Mouse Wheel Down"
			_:
				return "Mouse %d" % event.button_index
	return "Unknown"

func _build_general_settings() -> void:
	_add_slider_row("Screen Shake", 0.0, 2.0, 0.05, GameSettings.screen_shake_intensity, func(v): GameSettings.set_screen_shake_intensity(v))
	_add_slider_row("Brightness", 0.4, 1.8, 0.05, GameSettings.brightness, func(v): GameSettings.set_brightness(v))
	_add_fps_row()
	_add_fullscreen_row()
	_add_resolution_row()

func _add_slider_row(label_text: String, min_v: float, max_v: float, step: float, current: float, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(ROW_LABEL_MIN_WIDTH, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = current
	slider.custom_minimum_size = Vector2(220, 24)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var value_label := Label.new()
	value_label.text = "%d%%" % roundi(current * 100.0)
	value_label.custom_minimum_size = Vector2(56, 0)
	row.add_child(value_label)

	slider.value_changed.connect(func(v: float):
		value_label.text = "%d%%" % roundi(v * 100.0)
		on_change.call(v)
	)

	general_list.add_child(row)

func _add_fps_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = "FPS Limit"
	label.custom_minimum_size = Vector2(ROW_LABEL_MIN_WIDTH, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var option := OptionButton.new()
	for fps in GameSettings.FPS_OPTIONS:
		option.add_item(FPS_LABELS.get(fps, str(fps)))
	var idx := GameSettings.FPS_OPTIONS.find(GameSettings.fps_limit)
	option.selected = maxi(idx, 0)
	option.item_selected.connect(func(i: int): GameSettings.set_fps_limit(GameSettings.FPS_OPTIONS[i]))
	row.add_child(option)

	general_list.add_child(row)

func _add_fullscreen_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = "Fullscreen"
	label.custom_minimum_size = Vector2(ROW_LABEL_MIN_WIDTH, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var checkbox := CheckBox.new()
	checkbox.button_pressed = GameSettings.fullscreen
	checkbox.toggled.connect(func(pressed: bool): GameSettings.set_fullscreen(pressed))
	row.add_child(checkbox)

	general_list.add_child(row)
	_fullscreen_checkbox = checkbox

## Picking a resolution only has a visible effect in windowed mode, so
## choosing one also switches Fullscreen off (and updates that checkbox)
## instead of silently doing nothing while fullscreen is still on.
func _add_resolution_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = "Resolution"
	label.custom_minimum_size = Vector2(ROW_LABEL_MIN_WIDTH, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var option := OptionButton.new()
	for res in GameSettings.RESOLUTIONS:
		option.add_item("%d x %d" % [res.x, res.y])
	var idx := GameSettings.RESOLUTIONS.find(GameSettings.window_size)
	option.selected = maxi(idx, 0)
	option.item_selected.connect(func(i: int):
		var res: Vector2i = GameSettings.RESOLUTIONS[i]
		GameSettings.set_window_size(res)
		if GameSettings.fullscreen:
			GameSettings.set_fullscreen(false)
			if _fullscreen_checkbox != null:
				_fullscreen_checkbox.button_pressed = false
	)
	row.add_child(option)

	general_list.add_child(row)
