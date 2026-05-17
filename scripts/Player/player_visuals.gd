extends Node2D
class_name PlayerVisuals

@onready var ap: AnimationPlayer = $"../AnimationPlayer"
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var gray: TextureRect = $Effects2/Gray
@onready var blue: TextureRect = $Effects/Blue

const GRAY_DURATION: float = 0.2

func _ready() -> void:
	GlobalPlayer.visuals = self
	health_bar.init_health(GlobalPlayer.stats.maxHp)
	if gray.material and gray.material is ShaderMaterial:
		gray.material.set_shader_parameter("saturation", 1.0)

func showBlack():
	ap.play("transition")

func deleteBlack():
	ap.play("transition_unload")

func show_gray(duration: float = GRAY_DURATION) -> void:
	var tw = create_tween()
	tw.tween_property(gray.material, "shader_parameter/saturation", 0.0, duration) \
	  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func hide_gray(duration: float = GRAY_DURATION) -> void:
	var tw = create_tween()
	tw.tween_property(gray.material, "shader_parameter/saturation", 1.0, duration) \
	  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func show_blue(duration: float = GRAY_DURATION) -> void:
	var tw = create_tween()
	tw.tween_property(blue.material, "shader_parameter/saturation", 0.4, duration) \
	  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func hide_blue(duration: float = GRAY_DURATION) -> void:
	var tw = create_tween()
	tw.tween_property(blue.material, "shader_parameter/saturation", 1.0, duration) \
	  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
