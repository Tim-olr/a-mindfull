extends Node2D
class_name Weapon

@export_group("Base Stats")
@export var pierceMod: int = 0
@export var damageMod: float
@export var bulletLifeTimeMod: float
@export var bulletAmountMod: int
@export var rotationAdditionMod: float
@export var projectileSpeedMod: float
@export var bulletSizeMod: Vector2
@export var shootCooldown: float
@export var gun: bool
@export var melee: bool
@export var damage: float
@export var description: String
@export var Name: String
@export var rarity: String
@export var bulletScene: PackedScene
@export var doConsecShooting := false
@export var cameraShakeAmount: float
@export var knockback_force: float = 1000.0

@export_group("Melee Settings")
@export var is_swing: bool = false
@export var is_stab: bool = false
@export var swing_arc: float = 90.0
@export var stab_distance: float = 20.0
@export var attack_duration: float = 0.2

var shooter: Node2D
var targets_hit: Array[Node] = []
var melee_active: bool = false
var detection_area: Area2D

@onready var attack_cooldown: Timer = $attack_cooldown
@onready var bullet_stars_pos = $BulletStarsPos
@onready var melee_hitbox: Area2D = $BulletStarsPos/MeleeHitbox

var original_bullet_pos: Vector2  
var original_bullet_rot: float

func _ready():
	shooter = get_parent()
	melee_hitbox.body_entered.connect(_on_melee_hitbox_entered)
	melee_hitbox.area_entered.connect(_on_melee_hitbox_entered)
	original_bullet_pos = bullet_stars_pos.position  
	original_bullet_rot = bullet_stars_pos.rotation
	if shooter.is_in_group("enemy") and melee:
		detection_area = shooter.get_node_or_null("playerMeleeDetectionArea")

func _process(_delta: float) -> void:
	if shooter.is_in_group("player"):
		global_position = shooter.global_position
		bullet_stars_pos.look_at(get_global_mouse_position())
		if Input.is_action_pressed("attack") and shooter.stats.canAttack:
			perform_attack()
	elif shooter.is_in_group("spirit"):
		global_position = shooter.global_position
		bullet_stars_pos.look_at(get_global_mouse_position())
		if Input.is_action_just_pressed("spirit_attack") and shooter.out and shooter.canAttack:
			perform_attack()
	elif shooter.is_in_group("enemy"):
		if GlobalPlayer.player:
			bullet_stars_pos.look_at(GlobalPlayer.player.global_position)
			if gun:
				var dist = global_position.distance_to(GlobalPlayer.player.global_position)
				if shooter.stats.canAttack and dist < 1000:
					perform_attack()
			elif melee and detection_area:
				if shooter.stats.canAttack:
					for body in detection_area.get_overlapping_bodies():
						if body.is_in_group("player"):
							perform_attack()
							break

func perform_attack():
	if shooter.is_in_group("spirit"):
		shooter.canAttack = false
	else:
		shooter.stats.canAttack = false
		attack_cooldown.set_wait_time(shooter.stats.attackSpeed + shootCooldown)
		attack_cooldown.start()
	
	if gun:
		shoot()
	elif melee:
		if shooter.is_in_group("spirit"):
			do_melee_animation()
		else:
			var total_attacks = shooter.stats.bulletAmount + bulletAmountMod
			for i in total_attacks:
				do_melee_animation()
				if doConsecShooting:
					await get_tree().create_timer(0.1).timeout
				else:
					await get_tree().create_timer(attack_duration).timeout

func do_melee_animation():
	targets_hit.clear()
	melee_active = true
	
	for body in melee_hitbox.get_overlapping_bodies():
		_on_melee_hitbox_entered(body)
	for area in melee_hitbox.get_overlapping_areas():
		_on_melee_hitbox_entered(area)

	var tween = create_tween()
	var current_rot = bullet_stars_pos.rotation
	var current_pos = bullet_stars_pos.position
	
	if is_swing:
		tween.tween_property(bullet_stars_pos, "rotation", current_rot + deg_to_rad(swing_arc/2), attack_duration/2)
		tween.tween_property(bullet_stars_pos, "rotation", current_rot - deg_to_rad(swing_arc/2), attack_duration/2)
		tween.tween_property(bullet_stars_pos, "rotation", original_bullet_rot, 0.05)
	elif is_stab:
		tween.tween_property(bullet_stars_pos, "position", current_pos + Vector2(stab_distance, 0).rotated(current_rot), attack_duration/2)
		tween.tween_property(bullet_stars_pos, "position", original_bullet_pos, attack_duration/2)
	
	await tween.finished
	if shooter.is_in_group("spirit"):
		shooter.canAttack = true
	bullet_stars_pos.position = original_bullet_pos
	bullet_stars_pos.rotation = original_bullet_rot
	
	melee_active = false

func _on_melee_hitbox_entered(body: Node):
	if !melee_active or targets_hit.has(body) or body == shooter:
		return
	if shooter.is_in_group("player") or shooter.is_in_group("spirit"):
		if body.is_in_group("enemy"):
			hit(body)
	elif shooter.is_in_group("enemy"):
		if body.is_in_group("player") or body.is_in_group("spirit"):
			hit(body)

func hit(hitBody):
	do_damage(hitBody)
	apply_knockback_to_target(hitBody)

func do_damage(hitBody):
	var total_damage
	if shooter.is_in_group("spirit"):
		total_damage = shooter.attackDamage + damage
	else:
		total_damage = shooter.stats.attackDamage + damage
	if hitBody.is_in_group("enemy"):
		if hitBody.has_method("damage"):
			hitBody.damage(total_damage)
		elif hitBody.get_parent().has_method("damage"):
			hitBody.get_parent().damage(total_damage)
		targets_hit.append(hitBody)
	elif hitBody.is_in_group("player"):
		if hitBody.manager.has_method("damage"):
			hitBody.manager.damage(total_damage, get_parent(), cameraShakeAmount)
		elif hitBody.get_parent().manager.has_method("damage"):
			hitBody.get_parent().manager.damage(total_damage, get_parent(), cameraShakeAmount)
		targets_hit.append(hitBody)

func apply_knockback_to_target(hitBody):
	if knockback_force <= 0:
		return
	var knockback_direction = (hitBody.global_position - shooter.global_position).normalized()
	if hitBody.is_in_group("enemy"):
		if hitBody.has_method("apply_knockback"):
			hitBody.apply_knockback(knockback_direction, knockback_force)
		elif hitBody.get_parent().has_method("apply_knockback"):
			hitBody.get_parent().apply_knockback(knockback_direction, knockback_force)
	elif hitBody.is_in_group("player"):
		if hitBody.manager.has_method("apply_knockback"):
			hitBody.manager.apply_knockback(knockback_direction, knockback_force)
		elif hitBody.get_parent().manager.has_method("apply_knockback"):
			hitBody.get_parent().manager.apply_knockback(knockback_direction, knockback_force)

func shoot():
	var total_bullets = shooter.stats.bulletAmount + bulletAmountMod
	var spread_angle = GlobalPlayer.stats.rotationAddition + rotationAdditionMod
	var start_rotation = bullet_stars_pos.rotation
	if total_bullets > 1 and !doConsecShooting:
		start_rotation -= (spread_angle * (total_bullets - 1)) / 2.0
	for i in total_bullets:
		var bullet = bulletScene.instantiate()
		bullet.shooter_group = "player" if shooter.is_in_group("player") else "enemy"
		bullet.knockback_force = knockback_force
		if shooter.is_in_group("player"):
			GlobalPlayer.camera.apply_shake(cameraShakeAmount)
		var current_rot = start_rotation + (i * spread_angle)
		bullet.rot = current_rot
		bullet.rotation = current_rot
		bullet.projectileSpeed = shooter.stats.projectileSpeed + projectileSpeedMod
		bullet.pierce = shooter.stats.pierce + pierceMod
		bullet.damage = shooter.stats.attackDamage + damageMod
		bullet.lifetime = shooter.stats.bulletLifeTime + bulletLifeTimeMod
		bullet.set_scale(shooter.stats.bulletSize + bulletSizeMod)
		bullet.global_position = bullet_stars_pos.global_position
		bullet.shake = cameraShakeAmount
		GlobalWorld.projectiles.add_child(bullet)
		if doConsecShooting:
			await get_tree().create_timer(0.1).timeout 
		if shooter.stats.bulletAmount > 1:
			start_rotation -= shooter.stats.rotationAddition + rotationAdditionMod

func _on_attack_cooldown_timeout() -> void:
	shooter.stats.canAttack = true
