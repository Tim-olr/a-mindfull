extends Spirit

@export_enum("Chunk", "Swift") var mode := 0

@onready var chunkGun = preload("res://spirit-game-project/scenes/Weapons/spirit_weapons/STS_Chunk.tscn")
@onready var swiftGun = preload("res://spirit-game-project/scenes/Weapons/spirit_weapons/STS_swift.tscn")
var passiveRemMode : int
var addedHp
var addedDmg
var addedSpd
var addedDsa
@onready var mesh_instance_2d: MeshInstance2D = $MeshInstance2D

func flash_color(target: Color) -> void:
	if not mesh_instance_2d:
		return
	var tw = create_tween()
	tw.tween_property(mesh_instance_2d, "modulate", target, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(mesh_instance_2d, "modulate", Color(1, 1, 1, 1), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func changeWeap():
	if weapo and is_instance_valid(weapo):
		weapo.queue_free()
	if mode == 0:
		weaponScene = chunkGun
		weapo = weaponScene.instantiate()
		add_child(weapo)
		flash_color(Color(1, 0.85, 0, 1))
	elif mode == 1:
		weaponScene = swiftGun
		weapo = weaponScene.instantiate()
		add_child(weapo)
		flash_color(Color(0.35, 0.6, 1, 1))

func apply_passive():
	if mode == 0:
		passiveRemMode = 0
		GlobalPlayer.stats.maxHp += 30
		GlobalPlayer.stats.hp += 30
		addedHp = 30
		GlobalPlayer.visuals.health_bar.set_health(GlobalPlayer.stats.hp)
		addedDmg = GlobalPlayer.stats.attackDamage * 0.25
		GlobalPlayer.stats.attackDamage += addedDmg
	elif mode == 1:
		passiveRemMode = 1
		addedSpd = GlobalPlayer.stats.speed * 0.4
		GlobalPlayer.stats.speed += addedSpd
		addedDsa = GlobalPlayer.stats.dashAmount
		GlobalPlayer.stats.dashAmount = GlobalPlayer.stats.dashAmount * 2

func remove_passive():
	if passiveRemMode == 0:
		GlobalPlayer.stats.maxHp -= addedHp
		if GlobalPlayer.stats.hp - addedHp <= 0:
			GlobalPlayer.stats.hp = 1
			GlobalPlayer.visuals.health_bar.set_health(GlobalPlayer.stats.hp)
		else:
			GlobalPlayer.stats.hp -= addedHp
			GlobalPlayer.visuals.health_bar.set_health(GlobalPlayer.stats.hp)
		GlobalPlayer.stats.attackDamage -= addedDmg
	elif passiveRemMode == 1:
		GlobalPlayer.stats.speed -= addedSpd
		GlobalPlayer.stats.dashAmount -= addedDsa

func active_ability():
	if mode == 0:
		remove_passive()
		mode = 1
		changeWeap()
		size = Vector2(0.9, 0.9)
		set_scale(size)
		attackCooldown = 0.05
		canAttack = true
		apply_passive()
	elif mode == 1:
		remove_passive()
		mode = 0
		changeWeap()
		attackCooldown = 0.8
		canAttack = true
		size = Vector2(1.3, 1.3)
		set_scale(size)
		apply_passive()
