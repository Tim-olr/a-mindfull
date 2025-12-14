extends Node2D
@onready var black: Sprite2D = $CanvasLayer/Black
@onready var load_timer: Timer = $LoadTimer
@onready var projectiles: Node2D = $projectiles

func _ready() -> void:
	load_timer.start()
	GlobalPlayer.visuals.deleteBlack()
	GlobalWorld.projectiles = projectiles
	GlobalPlayer.stats.canAttack = true

func _on_load_timer_timeout() -> void:
	black.hide()
