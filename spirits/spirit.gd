extends CharacterBody2D

class_name Spirit

@export_category("generic")
@export var Name: String
@export var attackType: String
@export var out: bool = false
@export var canGetAttacked: bool = true
@export var size:= Vector2(1,1)
@export var sprites: AnimatedSprite2D
@export_category("ability")
@export var activeAbilityCooldown: float
@export var min_active_time: float = 0.0
@export var hasAbilityDuration: bool
@export var abilityDuration: float
@export_category("other_attack_settings")
@export var hasWeapon := true
@export var hasStandaloneShooting: bool
@export var weaponScene: PackedScene

@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var bullet_start_pos: Marker2D = GlobalPlayer.spiritMarker

var canAbility: bool = true

var weapo: Weapon

@export var follow_distance: float = 25.0
@export var smooth_speed: float = 8.0

@export var projectile: PackedScene

@onready var ap: AnimationPlayer = $AnimationPlayer
@onready var active_ability_timer: Timer = $ActiveAbilityTimer
@onready var ability_duration_timed_out: Timer = $AbilityDurationTimedOut
@onready var enemycollision: CollisionShape2D = $enemycollision

var host: CharacterBody2D

@onready var stats: Node2D = $stats

func _ready() -> void:
	if hasWeapon:
		weapo = weaponScene.instantiate()
		add_child(weapo)
		weapo.hide()
	top_level = true 
	host = get_parent()
	set_scale(size)
	z_index = 2
	canAbility = true
	enemycollision.disabled = true
	add_to_group("spirit")

func _process(_delta: float) -> void:
	bullet_start_pos.global_position = global_position
	bullet_start_pos.look_at(get_global_mouse_position())
	if out:
		if Input.is_action_pressed("spirit_attack"):
			attack()
		if Input.is_action_just_pressed("spirit_ability"):
			active_ability()
	if sprites != null and !sprites.is_playing():
		sprites.play("default")

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
	#rotation = lerp_angle(rotation, move_dir.angle(), smooth_speed * delta)

func damage(amount, damager, shake):
	GlobalPlayer.manager.spirit_damage(amount, damager, shake)

func bring_out():
	if !out:
		out = true
		canGetAttacked = true
		apply_passive()
		if hasWeapon:
			weapo.show()
		ap.play("BringOut")
		enemycollision.disabled = false
		if allows_obstacle_passthrough():
			_set_obstacle_passthrough(true)

func bring_in():
	if out:
		out = false
		canGetAttacked = false
		remove_passive()
		if hasWeapon:
			weapo.hide()
		ap.play("BringIn")
		enemycollision.disabled = true
		if allows_obstacle_passthrough():
			_set_obstacle_passthrough(false)

func check_can_attack():
	if stats.canAttack:
		return true

func attack():
	pass

func apply_passive():
	pass

func remove_passive():
	pass

func get_effective_cooldown() -> float:
	return maxf(min_active_time, activeAbilityCooldown * (1.0 - ArtifactManager.spirit_cdr()))

func active_ability():
	pass

func remove_ability():
	pass

# Override in subclasses to transform incoming damage before reduction is applied.
# `hit_on_spirit` is true when the hit landed on the spirit body, false when on the player.
func modify_incoming_damage(amount: float, _hit_on_spirit: bool) -> float:
	return amount

## Override to true in subclasses whose passive/active ability lets the
## player walk through breakable/solid obstacles while the spirit is out.
func allows_obstacle_passthrough() -> bool:
	return false

func _set_obstacle_passthrough(enabled: bool) -> void:
	for obstacle in get_tree().get_nodes_in_group("obstacle"):
		if obstacle.has_method("set_player_can_pass"):
			obstacle.set_player_can_pass(enabled)

func _on_attack_cooldown_timer_timeout() -> void:
	stats.canAttack = true

func _on_active_ability_timer_timeout() -> void:
	canAbility = true

func _on_ability_duration_timed_out_timeout() -> void:
	if hasAbilityDuration:
		remove_ability()
