extends Node2D

@onready var stats = $"../PlayerStats"
@onready var interact_area = $InteractArea
@onready var movement_controller = $"../PlayerMovement"
@export var weapon: PackedScene
@export var knockback_resistance: float = 0.0  # 0 = no resistance, 1 = full resistance
@onready var mesh_instance_2d: MeshInstance2D = $"../MeshInstance2D"

func _ready() -> void:
	if weapon != null:
		var wepon = weapon.instantiate()
		add_child(wepon)

func _process(_delta: float) -> void:
	if stats.hp <= 0:
		die()

func _input(_event: InputEvent) -> void:
	if Input.is_action_pressed("interact"):
		for i in interact_area.get_overlapping_areas():
			if i.is_in_group("interactables"):
				i.interacted()
	if Input.is_action_just_pressed("embrace"):
		if !stats.playerSpiritScene.out:
			stats.playerSpiritScene.bring_out()
			stats.playerSpiritScene.host = get_parent()
		elif stats.playerSpiritScene.out:
			stats.playerSpiritScene.bring_in()

func damage(damage_amount, attacker, shake):
	stats.hp -= damage_amount
	damaged(shake)
	if attacker != null:
		var knockback_direction = (get_parent().global_position - attacker.global_position).normalized()
		apply_knockback(knockback_direction, 200.0)

func damaged(shake):
	var tween = create_tween()
	tween.tween_property(mesh_instance_2d, "modulate", Color.RED, 0.1)
	tween.tween_property(mesh_instance_2d, "modulate", Color.WHITE, 0.1)
	GlobalPlayer.camera.apply_shake(shake)

func die():
	get_tree().change_scene_to_file("res://spirit-game-project/scenes/main game/game.tscn")

func apply_knockback(direction: Vector2, force: float):
	var effective_force = force * (1.0 - clamp(knockback_resistance, 0.0, 1.0))
	var knockback_velocity = direction.normalized() * effective_force
	if movement_controller:
		movement_controller.add_knockback(knockback_velocity)
