extends CharacterBody2D
class_name Enemy

@export var Name: String
@export var texture: Texture2D
@export var area: Area2D
@onready var timer: Timer = $Timer
@export var base: Sprite2D
@export var weapon: PackedScene
@onready var death_anim_timer: Timer = $death_anim_timer
@onready var stats: Node2D = $EnemyStats
@onready var attack_speed: Timer = $attack_speed
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var health_bar: ProgressBar = $"UI enemy/HealthBar"

@export var knockback_resistance: float = 0.0 

var knockbackVelocity = Vector2.ZERO 
var knockback_decay: float = 10.0 

var canWalk := true

var isMelee: bool = false

var died := false

var attacking := false

var direction

func _ready() -> void:
	base.texture = texture
	await get_tree().physics_frame
	health_bar.init_health(stats.hp)
	if weapon != null:
		var wep = weapon.instantiate()
		add_child(wep)

func _process(_delta: float) -> void:
	if stats.hp <= 0 and !died:
		area.set_deferred("monitorable", false)
		area.set_deferred("monitoring", false)
		die()
	direction = velocity
	if direction == Vector2(0, 0):
		return

func _physics_process(delta: float) -> void:
	if knockbackVelocity.length() > 0:
		knockbackVelocity = lerp(knockbackVelocity, Vector2.ZERO, knockback_decay * delta)
		if knockbackVelocity.length() < 1.0:
			knockbackVelocity = Vector2.ZERO
	
	if !attacking and canWalk and GlobalPlayer.player:
		nav_agent.target_position = GlobalPlayer.player.global_position
		if not nav_agent.is_navigation_finished():
			var next_path_pos = nav_agent.get_next_path_position()
			var new_velocity = global_position.direction_to(next_path_pos) * stats.speed
			nav_agent.set_velocity(new_velocity + knockbackVelocity)
	elif knockbackVelocity.length() > 0:
		velocity = knockbackVelocity
		move_and_slide()

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func damage(damageAmount, _dmgr, _camShake):
	var newDmg = damageAmount
	stats.hp -= newDmg
	health_bar.set_health(stats.hp)
	damaged()
	GlobalhitMarker.show_hit_marker(newDmg, self, false)

func die():
	canWalk = false
	died = true
	queue_free()

func attack(_b):
	pass

func attackCooldownActivator():
	timer.start(stats.attackCooldown)

func _on_timer_timeout() -> void:
	attacking = false

func _on_attack_speed_timeout() -> void:
	attacking = false

func _on_death_anim_timer_timeout() -> void:
	queue_free()

func damaged():
	var tween = create_tween()
	tween.tween_property(base, "modulate", Color.RED, 0.1)
	tween.tween_property(base, "modulate", Color.WHITE, 0.1)

func apply_knockback(direction: Vector2, force: float):
	var effective_force = force * (1.0 - clamp(knockback_resistance, 0.0, 1.0))
	knockbackVelocity = direction.normalized() * effective_force
