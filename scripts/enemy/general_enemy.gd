extends CharacterBody2D
class_name enemy

@export var Name: String
@export var hp: float
@export var speed: float
@export var enemyDamage: float
@export var texture: Texture2D
@export var area: Area2D
@export var attackCooldown: float
@export var attackSpeed: float
@export var death_anim_time: float
@onready var timer: Timer = $Timer
@export var base: AnimatedSprite2D
@onready var death_anim_timer: Timer = $death_anim_timer
@onready var attack_speed: Timer = $attackSpeed
var itemPool = GlobalPlayer.player.itemPool

var canWalk := true

var died := false

var attacking := false

var canAttack := true

var direction

func _process(_delta: float) -> void:
	if hp <= 0 and !died:
		area.set_deferred("monitorable", false)
		area.set_deferred("monitoring", false)
		die()
	direction = velocity
	if direction == Vector2(0, 0):
		return

func _physics_process(_delta: float) -> void:
	if !attacking and canWalk:
		velocity = Vector2(speed, speed)
		move_and_slide()
	else:
		velocity = Vector2(0, 0)

func damage(damageAmount):
	var newDmg = damageAmount
	hp -= newDmg
	damaged()

func die():
	canWalk = false
	died = true
	queue_free()

func attack(_b):
	pass

func attackCooldownActivator():
	timer.start(attackCooldown)
	canAttack = false

func _on_timer_timeout() -> void:
	attacking = false
	canAttack = true

func evaDieCheckEn():
	return GlobalPlayer.manager.evaDieCheck(15)

func _on_attack_speed_timeout() -> void:
	attacking = false

func _on_death_anim_timer_timeout() -> void:
	queue_free()

func damaged():
	var tween = create_tween()
	tween.tween_property(base, "modulate", Color.RED, 0.1)
	tween.tween_property(base, "modulate", Color.WHITE, 0.1)
