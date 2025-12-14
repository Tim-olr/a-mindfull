extends Node2D
class_name Weapon

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

@onready var attack_cooldown: Timer = $attack_cooldown
@onready var bullet_stars_pos = $BulletStarsPos

@onready var stats = GlobalPlayer.stats

func _process(delta: float) -> void:
	global_position = GlobalPlayer.player.global_position
	bullet_stars_pos.rotation = 0
	bullet_stars_pos.look_at(get_global_mouse_position())
	if Input.is_action_pressed("attack") and stats.canAttack:
		if gun:
			shoot()
			stats.canAttack = false
			attack_cooldown.set_wait_time(stats.attackSpeed + shootCooldown)
			attack_cooldown.start()

func shoot():
	if gun:
		var maxRot = 0
		if stats.bulletAmount + bulletAmountMod > 1:
			maxRot = ((stats.bulletAmount + bulletAmountMod) * (stats.rotationAddition + rotationAdditionMod)) / 2.5
		for i in stats.bulletAmount:
			var bullet = bulletScene.instantiate()
			bullet.rot = bullet_stars_pos.rotation + maxRot
			bullet.rotation = bullet_stars_pos.rotation
			bullet.projectileSpeed = stats.projectileSpeed + projectileSpeedMod
			bullet.pierce = stats.pierce + pierceMod
			bullet.damage = stats.attackDamage + damageMod
			bullet.lifetime = stats.bulletLifeTime + bulletLifeTimeMod
			bullet.set_scale(stats.bulletSize + bulletSizeMod)
			bullet.global_position = bullet_stars_pos.global_position
			GlobalWorld.projectiles.add_child(bullet)
			if stats.bulletAmount > 1:
				maxRot -= stats.rotationAddition + rotationAdditionMod


func _on_attack_cooldown_timeout() -> void:
	stats.canAttack = true
