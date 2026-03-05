extends Node2D
class_name PlayerStats

@export var speed: float = 200
@export var hp: float
@export var maxHp: float
@export var attackDamage: float
@export var slideAmount: float
@export var playerSpirit: Resource
var playerSpiritScene: CharacterBody2D
@export var bulletAmount: int
@export var rotationAddition: float
@export var projectileSpeed: float
@export var pierce: int = 1
@export var bulletLifeTime: float
@export var bulletSize: Vector2
@export var attackSpeed: float
@export var dashImmuneTime: float
@export var dashCooldown: float
@export var dashAmount: int
@export var knockback_resistance: float = 0.0  # 0 = no resistance, 1 = full resistance
@export var step_height: int = 1
@export var climb_time: float

var hps: float
var canAttack: bool

func _ready() -> void:
	GlobalPlayer.stats = self
