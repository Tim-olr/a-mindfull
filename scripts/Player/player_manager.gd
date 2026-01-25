extends Node2D

@onready var stats = $"../PlayerStats"
@onready var interact_area = $InteractArea
@export var weapon: PackedScene
@onready var mesh_instance_2d: MeshInstance2D = $"../MeshInstance2D"

func _ready() -> void:
	if weapon != null:
		var wepon = weapon.instantiate()
		add_child(wepon)

func _process(delta: float) -> void:
	if stats.hp <= 0:
		die()

func _input(event: InputEvent) -> void:
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
		

func damage(damage):
	stats.hp -= damage
	damaged()

func damaged():
	var tween = create_tween()
	tween.tween_property(mesh_instance_2d, "modulate", Color.RED, 0.1)
	tween.tween_property(mesh_instance_2d, "modulate", Color.WHITE, 0.1)

func die():
	pass
