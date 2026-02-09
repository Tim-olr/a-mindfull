extends Node2D
class_name PlayerVisuals

@onready var ap: AnimationPlayer = $"../AnimationPlayer"
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var gray: TextureRect = $Effects/Gray

const GRAY_DURATION: float = 0.2

func _ready() -> void:
	GlobalPlayer.visuals = self
	health_bar.set_health(GlobalPlayer.stats.hp)
	if gray.material and gray.material is ShaderMaterial:
		gray.material.set_shader_parameter("saturation", 1.0)

func showBlack():
	ap.play("transition")

func deleteBlack():
	ap.play("transition_unload")

func show_gray(duration: float = GRAY_DURATION) -> void:
	if not (gray.material and gray.material is ShaderMaterial):
		push_error("Gray node does not have a ShaderMaterial with 'saturation' parameter.")
		return
	var tw = create_tween()
	tw.tween_property(gray.material, "shader_parameter/saturation", 0.0, duration) \
	  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func hide_gray(duration: float = GRAY_DURATION) -> void:
	if not (gray.material and gray.material is ShaderMaterial):
		push_error("Gray node does not have a ShaderMaterial with 'saturation' parameter.")
		return
	var tw = create_tween()
	tw.tween_property(gray.material, "shader_parameter/saturation", 1.0, duration) \
	  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
