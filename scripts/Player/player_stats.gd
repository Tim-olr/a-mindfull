extends Node2D
class_name PlayerStats

@onready var shard_counter: Control = $"../PlayerVisuals/UI/shard_counter"

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
@export var do_more_damage_to_enemies_with_hp_percent: bool = false
@export var enemy_health_percentage_min: int = 100
@export var damage_mult_for_dmdtewhp: float = 0.0
@export var damage_reduction: float = 0.0 # 0.0 = no reduction, -.2 = 20% reduction, 1.0 =  full reduction
@export var shards := 0.0 # sharsd are currency
@export var pickup_radius_mult: float = 0.0  # 0 = no auto-pickup; wise tree adds 0.05 per level
@export var luck: float = 0.0               # boosts rarity of loot; wise tree adds 0.10 per level
@export var gathering_speed: float = 1.0    # higher = faster gathering; wise tree adds 0.05 per level
@export var spirit_damage_reduction: float = 0.0  # extra DR applied only to spirit hits
@export var spirit_cooldown_reduction: float = 0.0  # reduces spirit active-ability cooldown
var bonus_inv_slots: int = 0                # extra inventory slots from wise tree

var hps: float
var canAttack: bool
var base_max_hp: float = 0.0

func hp_changed():
	GlobalPlayer.visuals.init_health_display(maxHp)

func add_shards(amount):
	if shards >= 1000000.0:
		return
	shards += amount
	shard_counter.change_amount(0)

func remove_shards(amount):
	if shards >= amount:
		shards -= amount
		shard_counter.change_amount(0)

func _ready() -> void:
	GlobalPlayer.stats = self
	base_max_hp = maxHp
