extends Interactable

var _ui: Control = null

func interacted() -> void:
	if _ui == null or not is_instance_valid(_ui):
		_create_ui()
	else:
		_ui.show()
		if _ui.has_method("_refresh"):
			_ui.call("_refresh")
	_is_active = true

func close_interaction() -> void:
	if _ui != null and is_instance_valid(_ui):
		_ui.hide()
	_is_active = false

func _create_ui() -> void:
	var script = load("res://scripts/main game/ui/wise_tree_ui.gd")
	if script == null:
		return
	var cl := CanvasLayer.new()
	cl.layer = 15
	cl.name = "WiseTreeLayer"
	get_tree().root.add_child(cl)
	var ui = script.new()
	cl.add_child(ui)
	_ui = ui
