extends Node2D
class_name PlayerManager

@onready var stats = $"../PlayerStats"
@onready var interact_area = $InteractArea
@onready var movement_controller = $"../PlayerMovement"
@onready var mesh_instance_2d: MeshInstance2D = $"../MeshInstance2D"
@onready var health_bar: ProgressBar = $"../PlayerVisuals/UI/HealthBar"
@onready var player_sprites: AnimatedSprite2D = $"../PlayerVisuals/PlayerSprites"
@onready var weapon_marker: Marker2D = $"../WeaponMarker"

@export var weapon: PackedScene
@export var inventory_node_path: NodePath = NodePath("")
@export var knockback_resistance: float = 0.0
@export var canHps: bool = false
@export var god_mode: bool = false

var canGetDamaged: bool = true
var spiritCanGetDamaged := true
var _weapon_instance: Node = null
var _active_interactable: Interactable = null

func _ready() -> void:
	if inventory_node_path != null and inventory_node_path != NodePath(""):
		var inv_node = get_node_or_null(inventory_node_path)
		if inv_node:
			inv_node.connect("hotbar_selected", Callable(self, "_on_inventory_hotbar_selected"))
		else:
			push_warning("PlayerManager: inventory_node_path set but node not found: %s" % inventory_node_path)
	if _weapon_instance == null and weapon != null and (inventory_node_path == NodePath("") or get_node_or_null(inventory_node_path) == null):
		var inst = weapon.instantiate()
		_weapon_instance = inst
		var player_node = get_parent()
		if player_node:
			player_node.add_child(inst)
		else:
			add_child(inst)
		inst.set("shooter", player_node)
		inst.set("isSelected", true)
	interact_area.area_exited.connect(_on_interact_area_exited)

func get_weapon() -> Node:
	return _weapon_instance

func _block_shoot_for(seconds: float) -> void:
	if stats != null:
		stats.canAttack = false
	await get_tree().create_timer(seconds).timeout
	if stats != null:
		stats.canAttack = true

func equip_weapon_from_item(item_resource) -> void:
	if item_resource == null:
		unequip_weapon()
		return
	if not item_resource.itemScene:
		unequip_weapon()
		return
	if _weapon_instance:
		unequip_weapon()
	var inst = item_resource.itemScene.instantiate()
	_weapon_instance = inst
	var player_node = get_parent()
	if player_node:
		player_node.add_child(inst)
	else:
		add_child(inst)
	inst.set("shooter", player_node)
	inst.set("isSelected", true)

func unequip_weapon() -> void:
	if _weapon_instance:
		var sh = null
		if _weapon_instance.has_method("get"):
			sh = _weapon_instance.get("shooter")
		if sh:
			if sh.is_in_group("spirit"):
				sh.canAttack = true
			elif sh.is_in_group("player") or sh.is_in_group("enemy"):
				if sh.has_method("get") and sh.get("stats") != null:
					sh.stats.canAttack = true
		if _weapon_instance.has_node("attack_cooldown"):
			_weapon_instance.attack_cooldown.stop()
		_weapon_instance.set("isSelected", false)
		_weapon_instance.queue_free()
		_weapon_instance = null

func _process(_delta: float) -> void:
	if stats.hp <= 0:
		die()
	GlobalPlayer.stats.playerSpiritScene.z_index = GlobalPlayer.player.z_index

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if _active_interactable != null:
			_active_interactable.close_interaction()
			_active_interactable = null
			return
		for i in interact_area.get_overlapping_areas():
			if i.is_in_group("interactables") and i is Interactable:
				i.interacted()
				if i._is_active:
					_active_interactable = i
				break
	if Input.is_action_just_pressed("embrace"):
		if not stats.playerSpiritScene.out:
			stats.playerSpiritScene.bring_out()
			stats.playerSpiritScene.host = get_parent()
		elif stats.playerSpiritScene.out:
			stats.playerSpiritScene.bring_in()

func _on_interact_area_exited(area: Area2D) -> void:
	if area == _active_interactable:
		_active_interactable.close_interaction()
		_active_interactable = null

func damage(damage_amount, attacker, shake):
	if god_mode:
		return
	if canGetDamaged:
		damage_amount = _apply_spirit_incoming_modifier(damage_amount, false)
		var reduction_am = damage_amount * stats.damage_reduction
		damage_amount -= reduction_am
		stats.hp -= damage_amount
		damaged(shake)
		health_bar.set_health(stats.hp)
		GlobalhitMarker.show_hit_marker(damage_amount, GlobalPlayer.player, false)
		if attacker != null:
			var knockback_direction = (get_parent().global_position - attacker.global_position).normalized()
			apply_knockback(knockback_direction, 200.0)

func spirit_damage(damage_amount, attacker, shake):
	if god_mode:
		return
	if spiritCanGetDamaged:
		damage_amount = _apply_spirit_incoming_modifier(damage_amount, true)
		var reduction_am = damage_amount * stats.damage_reduction
		damage_amount -= reduction_am
		stats.hp -= damage_amount
		damaged(shake)
		health_bar.set_health(stats.hp)
		GlobalhitMarker.show_hit_marker(damage_amount, GlobalPlayer.player, false)
		if attacker != null:
			var knockback_direction = (get_parent().global_position - attacker.global_position).normalized()
			apply_knockback(knockback_direction, 200.0)

func _apply_spirit_incoming_modifier(amount: float, hit_on_spirit: bool) -> float:
	var s = stats.playerSpiritScene
	if s != null and is_instance_valid(s) and s.has_method("modify_incoming_damage"):
		return s.modify_incoming_damage(amount, hit_on_spirit)
	return amount

func damaged(shake):
	var tween = create_tween()
	tween.tween_property(player_sprites, "modulate", Color.RED, 0.1)
	tween.tween_property(player_sprites, "modulate", Color.WHITE, 0.1)
	GlobalPlayer.camera.apply_shake(shake)

func die():
	canGetDamaged = false
	var tree = get_tree()
	if tree == null:
		return
	var player_node = get_parent()
	GlobalSafe.shards += (GlobalPlayer.stats.shards * 0.1)
	if player_node:
		player_node.process_mode = Node.PROCESS_MODE_ALWAYS
	if movement_controller:
		movement_controller.process_mode = Node.PROCESS_MODE_ALWAYS
	if player_sprites:
		player_sprites.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.paused = true
	if movement_controller:
		movement_controller.play_priority_animation("death", true)
		await player_sprites.animation_finished
	else:
		player_sprites.play("death")
		await player_sprites.animation_finished
	tree.paused = false
	tree.call_deferred("change_scene_to_file", "res://scenes/main game/game.tscn")

func hps_tick():
	if canHps:
		heal(stats.hps)

func heal(amount):
	if stats.hp >= stats.maxHp:
		return false
	var actual_heal = min(amount, stats.maxHp - stats.hp)
	stats.hp += actual_heal
	if actual_heal > 0:
		healed()
		health_bar.set_health(stats.hp)
		GlobalhitMarker.show_hit_marker(actual_heal, GlobalPlayer.player, true)
		return true

func healed():
	var tween = create_tween()
	tween.tween_property(mesh_instance_2d, "modulate", Color.GREEN, 0.1)
	tween.tween_property(mesh_instance_2d, "modulate", Color.WHITE, 0.1)

func apply_knockback(direction: Vector2, force: float):
	var effective_force = force * (1.0 - clamp(knockback_resistance, 0.0, 1.0))
	var knockback_velocity = direction.normalized() * effective_force
	if movement_controller:
		movement_controller.add_knockback(knockback_velocity)
