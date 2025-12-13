extends Node2D
@onready var black: Sprite2D = $CanvasLayer/Black
@onready var load_timer: Timer = $LoadTimer

func _ready() -> void:
	load_timer.start()
	GlobalPlayer.visuals.deleteBlack()

func _on_load_timer_timeout() -> void:
	black.hide()
