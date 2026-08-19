extends Node

## Autoload that listens for the "esc" action anywhere a player exists and
## lazily creates/toggles the pause menu overlay, the same way FogOfWar
## lazily creates the map UI. process_mode ALWAYS so it still hears "esc"
## while the tree is paused (needed to close the menu again).

var _pause_menu = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("esc"):
		return
	if not is_instance_valid(GlobalPlayer.player):
		return
	if _pause_menu != null and is_instance_valid(_pause_menu) and _pause_menu.is_settings_open():
		return
	if _pause_menu == null or not is_instance_valid(_pause_menu):
		_create_pause_menu()
	if _pause_menu == null:
		return
	_pause_menu.toggle()
	get_viewport().set_input_as_handled()

func _create_pause_menu() -> void:
	var scene = load("res://ui/pause_menu/pause_menu.tscn")
	if scene == null:
		return
	var cl := CanvasLayer.new()
	cl.layer = 30
	cl.name = "PauseMenuLayer"
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(cl)
	var menu = scene.instantiate()
	cl.add_child(menu)
	_pause_menu = menu
