extends Node2D
class_name PlayerVisuals

@onready var ap: AnimationPlayer = $"../AnimationPlayer"
@onready var health_bar: ProgressBar = $UI/HealthBar

func _ready() -> void:
	GlobalPlayer.visuals = self
	health_bar.set_health(GlobalPlayer.stats.hp)

func showBlack():
	ap.play("transition")

func deleteBlack():
	ap.play("transition_unload")
