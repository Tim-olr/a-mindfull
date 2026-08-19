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
@export var hitImmuneTime: float = 0.6
@export var knockback_resistance: float = 0.0  # 0 = no resistance, 1 = full resistance
@export var step_height: int = 1
@export var climb_time: float
@export var do_more_damage_to_enemies_with_hp_percent: bool = false
@export var enemy_health_percentage_min: int = 100
@export var damage_mult_for_dmdtewhp: float = 0.0
@export var damage_reduction: float = 0.0 # 0.0 = no reduction, -.2 = 20% reduction, 1.0 =  full reduction
@export var pickup_radius_mult: float = 0.0  # 0 = no auto-pickup
@export var luck: float = 0.0               # boosts rarity of loot
@export var gathering_speed: float = 1.0    # higher = faster chest opening
@export var spirit_damage_reduction: float = 0.0  # extra DR applied only to spirit hits
@export var spirit_cooldown_reduction: float = 0.0  # reduces spirit active-ability cooldown
@export var max_weapons: int = 2            # max weapons that can be carried at once; upgrades may raise this

var hps: float
var canAttack: bool
var base_max_hp: float = 0.0

func hp_changed():
	GlobalPlayer.visuals.init_health_display(maxHp)

func _ready() -> void:
	GlobalPlayer.stats = self
	if GameManager.playerSpirit != null:
		playerSpirit = GameManager.playerSpirit
	base_max_hp = maxHp
