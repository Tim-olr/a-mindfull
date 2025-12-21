extends Node2D

@export var speed: float
@export var hp: float
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
var canAttack: bool

func _ready() -> void:
	GlobalPlayer.stats = self
