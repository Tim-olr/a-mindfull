extends Spirit

@export_enum("Chunk", "Swift") var mode := 0

@onready var chunkGun = preload("res://scenes/Weapons/spirit_weapons/STS_Chunk.tscn")
@onready var swiftGun = preload("res://scenes/Weapons/spirit_weapons/STS_swift.tscn")
var passiveRemMode : int
var addedHp
var addedDmg
var addedSpd
var addedDsa

func flash_color(target: Color) -> void:
	if not sprites:
		return
	var tw = create_tween()
	tw.tween_property(sprites, "modulate", target, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprites, "modulate", Color(1, 1, 1, 1), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func changeWeap():
	if weapo and is_instance_valid(weapo):
		weapo.queue_free()
	if mode == 0:
		weaponScene = chunkGun
		weapo = weaponScene.instantiate()
		add_child(weapo)
		flash_color(Color(1.0, 0.0, 0.0, 1.0))
		attack_cooldown_timer.start(stats.attackSpeed)
	elif mode == 1:
		weaponScene = swiftGun
		weapo = weaponScene.instantiate()
		add_child(weapo)
		flash_color(Color(0.0, 0.403, 0.26, 1.0))
		attack_cooldown_timer.start(stats.attackSpeed)

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
	if canAbility:
		sprites.play("active")
		active_ability_timer.start(activeAbilityCooldown)
		canAbility = false
		if mode == 0:
			remove_passive()
			mode = 1
			changeWeap()
			size = Vector2(1, 1)
			set_scale(size)
			stats.attackSpeed = 0.05
			stats.canAttack = true
			apply_passive()
		elif mode == 1:
			remove_passive()
			mode = 0
			changeWeap()
			stats.attackSpeed = 0.8
			stats.canAttack = true
			size = Vector2(1.3, 1.3)
			set_scale(size)
			apply_passive()
