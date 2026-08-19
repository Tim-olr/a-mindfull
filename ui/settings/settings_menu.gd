extends Control

signal closed

const ROW_LABEL_MIN_WIDTH := 260.0
const MODIFIER_KEYCODES := [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK]

@onready var keybind_list: VBoxContainer = $Panel/ScrollContainer/KeybindList

var _bind_buttons: Dictionary = {}
var _listening_action: String = ""
var _listening_button: Button = null

func _ready() -> void:
	hide()
	_build_rows()

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
