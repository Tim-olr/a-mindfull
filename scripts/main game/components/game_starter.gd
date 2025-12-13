extends Interactable

@onready var timer: Timer = $Timer

func interacted():
	GameManager.gameStarted = true
	timer.start()
	GlobalPlayer.visuals.showBlack()

func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://spirit-game-project/scenes/main game/The game world/the_world.tscn")
