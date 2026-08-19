extends Node

## Autoload that owns the rebindable action list, persists custom keybinds to
## disk, and applies them to the InputMap on startup (before any menu reads
## InputMap.action_get_events).

const SAVE_PATH := "user://keybinds.cfg"

## Actions exposed to the player for rebinding, with display labels. Kept as
## an explicit allowlist (rather than iterating every InputMap action) so
## debug-only actions (e.g. "test") never show up in the settings menu.
const REBINDABLE_ACTIONS := {
	"up": "Move Up",
	"down": "Move Down",
	"left": "Move Left",
	"right": "Move Right",
	"attack": "Attack",
	"spirit_attack": "Spirit Attack",
	"spirit_ability": "Spirit Ability",
	"embrace": "Embrace Spirit",
	"dodge": "Dodge",
	"interact": "Interact",
	"open_inventory": "Inventory",
	"open_map": "Map",
	"toggle_minimap": "Toggle Minimap",
	"restart": "Restart",
	"esc": "Pause / Back",
}

var _defaults: Dictionary = {}

func _ready() -> void:
	_capture_defaults()
	_load()

func _capture_defaults() -> void:
	for action in REBINDABLE_ACTIONS:
		if InputMap.has_action(action):
			_defaults[action] = InputMap.action_get_events(action).duplicate()

func get_events(action: String) -> Array:
	if not InputMap.has_action(action):
		return []
	return InputMap.action_get_events(action)

## Assigns a single event to an action, stealing that event away from any
## other rebindable action that currently holds it so two actions never end
## up silently sharing the same key.
func rebind(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	for other in REBINDABLE_ACTIONS:
		if other != action and _has_conflicting_event(other, event):
			InputMap.action_erase_events(other)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	_save()

func reset_action(action: String) -> void:
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	for event in _defaults.get(action, []):
		InputMap.action_add_event(action, event)
	_save()

func reset_all() -> void:
	for action in REBINDABLE_ACTIONS:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
			for event in _defaults.get(action, []):
				InputMap.action_add_event(action, event)
	_save()

func _has_conflicting_event(action: String, event: InputEvent) -> bool:
	for e in InputMap.action_get_events(action):
		if _events_equal(e, event):
			return true
	return false

func _events_equal(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode \
			and a.shift_pressed == b.shift_pressed \
			and a.ctrl_pressed == b.ctrl_pressed \
			and a.alt_pressed == b.alt_pressed
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	return false

func _save() -> void:
	var cfg := ConfigFile.new()
	for action in REBINDABLE_ACTIONS:
		var entries: Array = []
		for event in get_events(action):
			if event is InputEventKey:
				entries.append({
					"type": "key",
					"keycode": event.physical_keycode,
					"shift": event.shift_pressed,
					"ctrl": event.ctrl_pressed,
					"alt": event.alt_pressed,
				})
			elif event is InputEventMouseButton:
				entries.append({"type": "mouse", "button": event.button_index})
		cfg.set_value("keybinds", action, entries)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for action in REBINDABLE_ACTIONS:
		if not cfg.has_section_key("keybinds", action):
			continue
		var entries = cfg.get_value("keybinds", action, [])
		if not (entries is Array) or entries.is_empty():
			continue
		InputMap.action_erase_events(action)
		for entry in entries:
			var event: InputEvent = null
			if entry.get("type") == "key":
				var key_event := InputEventKey.new()
				key_event.physical_keycode = entry.get("keycode", 0)
				key_event.shift_pressed = entry.get("shift", false)
				key_event.ctrl_pressed = entry.get("ctrl", false)
				key_event.alt_pressed = entry.get("alt", false)
				event = key_event
			elif entry.get("type") == "mouse":
				var mouse_event := InputEventMouseButton.new()
				mouse_event.button_index = entry.get("button", 0)
				event = mouse_event
			if event != null:
				InputMap.action_add_event(action, event)
