extends Node2D
class_name PlayerSpecials

var is_paused: bool = false

func pause():
	get_tree().paused = true

func unpause():
	get_tree().paused = false

func pause_wo_player():
	set_player_pause_mode(false)
	is_paused = true
	get_tree().paused = true

func unpause_wo_player():
	get_tree().paused = false
	is_paused = false
	set_player_pause_mode(true)

func set_player_pause_mode(paused: bool):
	var player_node = get_parent()
	if paused:
		player_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	else:
		player_node.process_mode = Node.PROCESS_MODE_ALWAYS
