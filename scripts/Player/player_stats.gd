extends Node2D

@export var speed: float
@export var hp: float
@export var attackDamage: float
@export var slideAmount: float
@export var playerSpirit: Resource

func _ready() -> void:
	GlobalPlayer.stats = self
