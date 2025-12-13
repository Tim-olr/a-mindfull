extends Node2D
@onready var ap: AnimationPlayer = $"../AnimationPlayer"

func _ready() -> void:
	GlobalPlayer.visuals = self

func showBlack():
	ap.play("transition")

func deleteBlack():
	ap.play("transition_unload")
