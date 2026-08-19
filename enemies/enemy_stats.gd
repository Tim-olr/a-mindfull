extends Node2D

@export var hp: float
@export var speed: float
@export var attackDamage: float
@export var attackCooldown: float
@export var attackSpeed: float
@export var death_anim_time: float
@export var bulletAmount: int
@export var rotationAddition: float
@export var projectileSpeed: float
@export var pierce: int = 1
@export var bulletLifeTime: float
@export var bulletSize: Vector2
@export var shard_reward: int = 1
var max_hp: float = 0.0
var canAttack: bool = true
