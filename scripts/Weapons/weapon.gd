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

func _ready():
	shooter = get_parent()
	melee_hitbox.body_entered.connect(_on_melee_hitbox_entered)
	melee_hitbox.area_entered.connect(_on_melee_hitbox_entered)
	
	if shooter.is_in_group("enemy") and melee:
		detection_area = shooter.get_node_or_null("playerMeleeDetectionArea")

func _process(delta: float) -> void:
	if shooter.is_in_group("player"):
		global_position = shooter.global_position
		bullet_stars_pos.look_at(get_global_mouse_position())
		if Input.is_action_pressed("attack") and shooter.stats.canAttack:
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
	shooter.stats.canAttack = false
	attack_cooldown.set_wait_time(shooter.stats.attackSpeed + shootCooldown)
	attack_cooldown.start()
	
	if gun:
		shoot()
	elif melee:
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
	var original_rot = bullet_stars_pos.rotation
	var original_pos = bullet_stars_pos.position
	
	if is_swing:
		tween.tween_property(bullet_stars_pos, "rotation", original_rot + deg_to_rad(swing_arc/2), attack_duration/2)
		tween.tween_property(bullet_stars_pos, "rotation", original_rot - deg_to_rad(swing_arc/2), attack_duration/2)
		tween.tween_property(bullet_stars_pos, "rotation", original_rot, 0.05)
	elif is_stab:
		tween.tween_property(bullet_stars_pos, "position", original_pos + Vector2(stab_distance, 0).rotated(original_rot), attack_duration/2)
		tween.tween_property(bullet_stars_pos, "position", original_pos, attack_duration/2)
	
	await tween.finished
	melee_active = false

func _on_melee_hitbox_entered(body: Node):
	if !melee_active or targets_hit.has(body) or body == shooter:
		return
		
	var shooter_group = "player" if shooter.is_in_group("player") else "enemy"
	if body.is_in_group(shooter_group):
		return

	if body.is_in_group("enemy") or body.is_in_group("player"):
		hit(body)

func hit(hitBody):
	do_damage(hitBody)

func do_damage(hitBody):
	var total_damage = shooter.stats.attackDamage + damage
	if hitBody.is_in_group("enemy"):
		if hitBody.has_method("damage"):
			hitBody.damage(total_damage)
		elif hitBody.get_parent().has_method("damage"):
			hitBody.get_parent().damage(total_damage)
		targets_hit.append(hitBody)
	elif hitBody.is_in_group("player"):
		if hitBody.manager.has_method("damage"):
			hitBody.manager.damage(total_damage)
		elif hitBody.get_parent().manager.has_method("damage"):
			hitBody.get_parent().manager.damage(total_damage)
		targets_hit.append(hitBody)

func shoot():
	var maxRot = 0
	var total_bullets = shooter.stats.bulletAmount + bulletAmountMod
	if total_bullets > 1:
		maxRot = ((total_bullets) * (shooter.stats.rotationAddition + rotationAdditionMod)) / 2.5
	for i in total_bullets:
		var bullet = bulletScene.instantiate()
		bullet.shooter_group = "player" if shooter.is_in_group("player") else "enemy"
		if shooter.is_in_group("player"):
			GlobalPlayer.camera.apply_shake()
		bullet.rot = bullet_stars_pos.rotation + maxRot
		bullet.rotation = bullet_stars_pos.rotation
		bullet.projectileSpeed = shooter.stats.projectileSpeed + projectileSpeedMod
		bullet.pierce = shooter.stats.pierce + pierceMod
		bullet.damage = shooter.stats.attackDamage + damageMod
		bullet.lifetime = shooter.stats.bulletLifeTime + bulletLifeTimeMod
		bullet.set_scale(shooter.stats.bulletSize + bulletSizeMod)
		bullet.global_position = bullet_stars_pos.global_position
		GlobalWorld.projectiles.add_child(bullet)
		if doConsecShooting:
			await get_tree().create_timer(0.1).timeout 
		if shooter.stats.bulletAmount > 1:
			maxRot -= shooter.stats.rotationAddition + rotationAdditionMod

func _on_attack_cooldown_timeout() -> void:
	shooter.stats.canAttack = true
