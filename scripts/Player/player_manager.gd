extends Node2D

@onready var Stats = $"../PlayerStats"
@onready var interact_area = $InteractArea
@export var weapon: PackedScene

func _ready() -> void:
	if weapon != null:
		var wepon = weapon.instantiate()
		add_child(wepon)

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("interact"):
		for i in interact_area.get_overlapping_areas():
			if i.is_in_group("interactables"):
				i.interacted()
