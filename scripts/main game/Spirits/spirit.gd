extends CharacterBody2D

class_name Spirit

@export_category("generic")
@export var Name: String
@export var attackDamage: float
@export var attackType: String
@export var out: bool = false
@export var canGetAttacked: bool = true
@export var size:= Vector2(1,1)
@export_category("ability")
@export var activeAbilityCooldown: float
@export var hasAbilityDuration: bool
@export var abilityDuration: float
@export_category("projectile_settings")
@export var attackCooldown: float
@export var lifetime: float
@export var projectileSpeed: float
@export var pierce: int
@export var rotationAdditionMod: float
@export var bulletAmountMod: int
@export var bulletSize: Vector2
@export_category("other_attack_settings")
@export var hasWeapon: bool
@export var hasStandaloneShooting: bool
@export var weaponScene: PackedScene

@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var bullet_start_pos: Marker2D = GlobalPlayer.spiritMarker

var canAttack: bool = true
var canAbility: bool = true

var weapo: Node2D

@export var follow_distance: float = 150.0
@export var smooth_speed: float = 8.0

@export var projectile: PackedScene

@onready var ap: AnimationPlayer = $AnimationPlayer
@onready var active_ability_timer: Timer = $ActiveAbilityTimer
@onready var ability_duration_timed_out: Timer = $AbilityDurationTimedOut

var host: CharacterBody2D

func _ready() -> void:
	if hasWeapon:
		weapo = weaponScene.instantiate()
		add_child(weapo)
		weapo.hide()
	attack_cooldown_timer.start(attackCooldown)
	top_level = true 
	host = get_parent()
	set_scale(size)

func _process(_delta: float) -> void:
	bullet_start_pos.global_position = global_position
	bullet_start_pos.look_at(get_global_mouse_position())
	if out:
		if Input.is_action_pressed("spirit_attack"):
			attack()
		if Input.is_action_just_pressed("spirit_ability"):
			active_ability()

func _physics_process(delta: float) -> void:
	if !host:
		return
	add_collision_exception_with(host)
	var movement_script = host.player_movement
	if !movement_script:
		return
	var move_dir = movement_script.last_movement_direction
	
	var target_pos = host.global_position
	if out:
		target_pos -= move_dir * follow_distance
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
	rotation = lerp_angle(rotation, move_dir.angle(), smooth_speed * delta)

func bring_out():
	if !out:
		out = true
		canGetAttacked = true
		apply_passive()
		if hasWeapon:
			weapo.show()
		ap.play("BringOut")

func bring_in():
	if out:
		out = false
		canGetAttacked = false
		remove_passive()
		if hasWeapon:
			weapo.hide()
		ap.play("BringIn")

func check_can_attack():
	if canAttack:
		return true

func attack():
	pass

func apply_passive():
	pass

func remove_passive():
	pass

func active_ability():
	pass

func remove_ability():
	pass

func set_projectile(bulletScene):
	if hasStandaloneShooting:
		var total_bullets = bulletAmountMod
		var spread_angle = rotationAdditionMod
		var start_rotation = bullet_start_pos.rotation
		for i in total_bullets:
			var bullet = bulletScene.instantiate()
			if bullet.get("shooter_group") != null:
				bullet.shooter_group = "player"
			var current_rot = start_rotation + (i * spread_angle)
			bullet.global_position = bullet_start_pos.global_position
			bullet.rot = current_rot
			bullet.rotation = current_rot
			bullet.damage = attackDamage
			bullet.projectileSpeed = projectileSpeed
			bullet.lifetime = lifetime
			bullet.pierce = pierce
			bullet.set_scale(bulletSize)
			bullet.shake = 0.0
			GlobalWorld.projectiles.add_child(bullet) 
			return bullet

func _on_attack_cooldown_timer_timeout() -> void:
	canAttack = true

func _on_active_ability_timer_timeout() -> void:
	canAbility = true
	print("we can do it again twin")

func _on_ability_duration_timed_out_timeout() -> void:
	if hasAbilityDuration:
		remove_ability()
