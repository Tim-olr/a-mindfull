extends Control

const MAIN_MENU_SCENE := "res://ui/main_menu/main_menu.tscn"
const RUN_SCENE := "res://world/the_world.tscn"

@onready var settings_menu: Control = $SettingsMenu
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var settings_button: Button = $Panel/VBoxContainer/SettingsButton
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var main_menu_button: Button = $Panel/VBoxContainer/MainMenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	settings_menu.closed.connect(_on_settings_closed)

func is_settings_open() -> bool:
	return settings_menu.visible

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	if visible:
		return
	if is_instance_valid(GlobalPlayer.specials):
		GlobalPlayer.specials.open_pause_menu()
	settings_menu.hide()
	show()

func close() -> void:
	if not visible:
		return
	settings_menu.hide()
	hide()
	if is_instance_valid(GlobalPlayer.specials):
		GlobalPlayer.specials.close_pause_menu()

func _on_resume_pressed() -> void:
	close()

func _on_settings_pressed() -> void:
	settings_menu.open_settings()

func _on_settings_closed() -> void:
	pass

func _on_restart_pressed() -> void:
	_leave_run(RUN_SCENE)

func _on_main_menu_pressed() -> void:
	_leave_run(MAIN_MENU_SCENE)

## Restart/Main Menu abandon the current run outright rather than resuming
## it, so this force-clears the pause state directly instead of restoring
## whatever it was before the menu opened (close()'s job) — otherwise a run
## paused mid an ability like Keep Me Close's would carry get_tree().paused
## = true into the next scene, leaving it unresponsive.
func _leave_run(target_scene: String) -> void:
	settings_menu.hide()
	hide()
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", target_scene)
